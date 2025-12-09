import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import 'subscription_provider.dart';
import 'upgrade_pro_page.dart';

class SubscriptionStatusPage extends StatefulWidget {
  const SubscriptionStatusPage({super.key});

  @override
  State<SubscriptionStatusPage> createState() => _SubscriptionStatusPageState();
}

class _SubscriptionStatusPageState extends State<SubscriptionStatusPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick every second to refresh countdown UI
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Try initial sync with backend
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshFromServer());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (!mounted || token == null || token.isEmpty) return;
    // Fire and await to update state
    await context.read<SubscriptionProvider>().fetchMySubscription(token);
    // Also refresh user info to keep tierCode consistent
    await context.read<AuthProvider>().fetchUser();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trạng thái gói Pro'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _refreshFromServer,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, sub, _) {
          final theme = Theme.of(context);
          if (sub.isPro) {
            final endAt = sub.endAt; // may be null
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bạn đang ở gói Pro', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Thời gian còn lại:',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            endAt != null
                                ? _formatDuration(sub.remainingDuration)
                                : '—',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.event, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                endAt != null
                                    ? 'Hết hạn vào: ${_fmtDateTime(endAt)}'
                                    : 'Không xác định ngày hết hạn',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.bug_report, size: 18),
                              const SizedBox(width: 8),
                              Text('Source: ${sub.source ?? '-'}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Not Pro
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn chưa nâng cấp Pro',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nâng cấp để tải nhạc offline, chuyển bài không giới hạn, v.v.',
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UpgradeProPage(),
                        ),
                      );
                    },
                    child: const Text('Nâng cấp ngay'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmtDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
