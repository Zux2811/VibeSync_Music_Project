import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import 'subscription_provider.dart';
import '../payment/vnpay_webview_page.dart';

import 'dart:async';

class UpgradeProPage extends StatefulWidget {
  const UpgradeProPage({super.key});

  @override
  State<UpgradeProPage> createState() => _UpgradeProPageState();
}

class _UpgradeProPageState extends State<UpgradeProPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick every second to refresh countdown if user is Pro
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nâng cấp Pro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<SubscriptionProvider>(
          builder: (context, sub, _) {
            final theme = Theme.of(context);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quyền lợi gói Pro', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _bullet('Tải nhạc nghe offline'),
                  _bullet('Chuyển bài không giới hạn'),
                  _bullet('Trộn bài không bị trùng lặp'),
                  const SizedBox(height: 16),

                  // Countdown nếu đang là Pro và có endAt
                  if (sub.isPro && sub.endAt != null) ...[
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thời gian còn lại: ${_formatDuration(sub.remainingDuration)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3 lựa chọn gói Pro
                  if (!sub.isPro) ...[
                    _planTile(
                      context,
                      title: 'Pro 1 tháng',
                      priceText: '10.000đ',
                      onPressed:
                          () => _startUpgradeFlow(
                            context,
                            sub,
                            months: 1,
                            amount: 10000,
                            orderInfo: 'Mua gói Pro 1 tháng',
                          ),
                    ),
                    const SizedBox(height: 12),
                    _planTile(
                      context,
                      title: 'Pro 6 tháng',
                      priceText: '50.000đ',
                      onPressed:
                          () => _startUpgradeFlow(
                            context,
                            sub,
                            months: 6,
                            amount: 50000,
                            orderInfo: 'Mua gói Pro 6 tháng',
                          ),
                    ),
                    const SizedBox(height: 12),
                    _planTile(
                      context,
                      title: 'Pro 1 năm',
                      priceText: '90.000đ',
                      onPressed:
                          () => _startUpgradeFlow(
                            context,
                            sub,
                            months: 12,
                            amount: 90000,
                            orderInfo: 'Mua gói Pro 1 năm',
                          ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days > 0) {
      return '$days ngày ${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
    }
    return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
  }

  Widget _planTile(
    BuildContext context, {
    required String title,
    required String priceText,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  priceText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(onPressed: onPressed, child: const Text('Nâng cấp')),
        ],
      ),
    );
  }

  Future<void> _startUpgradeFlow(
    BuildContext context,
    SubscriptionProvider sub, {
    required int months,
    required int amount,
    required String orderInfo,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VnPayWebViewPage(
              amount: amount,
              orderInfo: orderInfo,
              txnRef: 'ORDER_${now}_$months',
            ),
      ),
    );

    if (result == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn cần đăng nhập lại')),
          );
        }
        return;
      }

      final ok = await sub.upgradeToPro(
        token,
        provider: 'vnpay',
        providerRef: 'ORDER_${now}_$months',
        amount: amount.toDouble(),
        durationMonths: months,
      );

      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sub.errorMessage ?? 'Nâng cấp thất bại')),
          );
        }
        return;
      }

      // Refresh user info và subscription để đồng bộ endAt
      await context.read<AuthProvider>().fetchUser();
      final sp = await SharedPreferences.getInstance();
      final token2 = sp.getString('jwt_token');
      if (token2 != null && token2.isNotEmpty) {
        await context.read<SubscriptionProvider>().fetchMySubscription(token2);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán thành công. Bạn đã là Pro!'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
