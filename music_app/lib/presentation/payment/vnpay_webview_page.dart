import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VnPayWebViewPage extends StatefulWidget {
  final int amount; // in VND
  final String orderInfo;
  final String txnRef; // unique id per order

  const VnPayWebViewPage({
    super.key,
    required this.amount,
    required this.orderInfo,
    required this.txnRef,
  });

  @override
  State<VnPayWebViewPage> createState() => _VnPayWebViewPageState();
}

class _VnPayWebViewPageState extends State<VnPayWebViewPage> {
  late final WebViewController _controller;

  // TEST credentials - Do NOT hardcode in production. Move to backend in real app.
  static const String vnpTmnCode = 'Y79T70MP';
  static const String vnpHashSecret = 'IFRKW20LIMKP9WZUTJQA634MB2QW0K9Z';
  static const String vnpUrl =
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String returnUrl = 'https://example.com/vnpay_return';

  @override
  void initState() {
    super.initState();
    final url = _buildPaymentUrl(
      amount: widget.amount,
      orderInfo: widget.orderInfo,
      txnRef: widget.txnRef,
    );

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                final uri = request.url;
                if (uri.startsWith(returnUrl)) {
                  // Example: ...?vnp_ResponseCode=00
                  final u = Uri.parse(uri);
                  final code = u.queryParameters['vnp_ResponseCode'];
                  if (code == '00') {
                    // Success -> mark user as pro on this device
                    _markPro().then((_) => Navigator.pop(context, true));
                  } else {
                    Navigator.pop(context, false);
                  }
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(url));
  }

  Future<void> _markPro() async {
    // Persist locally; you may also want to confirm on backend
    final sp = await SharedPreferences.getInstance();
    await sp.setString('subscription_tier', 'pro');
  }

  String _buildPaymentUrl({
    required int amount,
    required String orderInfo,
    required String txnRef,
  }) {
    // VNPay requires amount in smallest currency unit (VND * 100)
    final int vnpAmount = amount * 100;
    final createDate = _formatDate(DateTime.now());

    final Map<String, String> params = {
      'vnp_Version': '2.1.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': vnpTmnCode,
      'vnp_Amount': vnpAmount.toString(),
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': txnRef,
      'vnp_OrderInfo': orderInfo,
      'vnp_OrderType': 'other',
      'vnp_Locale': 'vn',
      'vnp_ReturnUrl': returnUrl,
      'vnp_IpAddr': '0.0.0.0',
      'vnp_CreateDate': createDate,
    };

    // Sort by key
    final sorted = SplayTreeMap<String, String>.from(params);
    final query = sorted.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final secureHash = _hmacSHA512(vnpHashSecret, query);

    final fullUrl = '$vnpUrl?$query&vnp_SecureHash=$secureHash';
    return fullUrl;
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }

  String _hmacSHA512(String key, String data) {
    final hmac = Hmac(sha512, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VNPay (Test)')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
