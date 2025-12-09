import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../theme/theme_provider.dart';
import 'profile_page.dart';
import '../subscription/subscription_provider.dart';
import '../payment/vnpay_webview_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          // Profile Card
          _buildProfileCard(context),

          // Subscription Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SubscriptionCard(),
          ),

          // Theme Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _ThemeSettingCard(),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    // TODO: Replace with actual user data from a provider
    const String userName = "Username";
    const String avatarUrl = "https://via.placeholder.com/150"; // Placeholder

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profile",
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ThemeSettingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyan.withAlpha(128), width: 1),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text('Light Theme'),
                leading: const Icon(Icons.light_mode),
                trailing: Radio<AppThemeMode>(
                  value: AppThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setTheme(value);
                    }
                  },
                ),
                onTap: () {
                  themeProvider.setTheme(AppThemeMode.light);
                },
              ),
              const Divider(height: 0),
              ListTile(
                title: const Text('Dark Theme'),
                leading: const Icon(Icons.dark_mode),
                trailing: Radio<AppThemeMode>(
                  value: AppThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setTheme(value);
                    }
                  },
                ),
                onTap: () {
                  themeProvider.setTheme(AppThemeMode.dark);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, sub, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.tealAccent.withAlpha(128),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscription',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Gói hiện tại: ${sub.isPro ? 'Pro' : 'Free'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (!sub.isPro)
                    ElevatedButton(
                      onPressed: () async {
                        final now = DateTime.now().millisecondsSinceEpoch;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => VnPayWebViewPage(
                                  amount: 10000, // 10,000 VND test
                                  orderInfo: 'Mua gói Pro nghe nhạc - test',
                                  txnRef: 'ORDER_$now',
                                ),
                          ),
                        );
                        if (result == true && context.mounted) {
                          // Gọi backend để upgrade thật sự và đồng bộ tier
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('jwt_token');
                          if (token == null || token.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bạn cần đăng nhập lại'),
                                ),
                              );
                            }
                            return;
                          }

                          final ok = await sub.upgradeToPro(
                            token,
                            provider: 'vnpay',
                            providerRef: 'ORDER_$now',
                            amount: 10000,
                          );

                          if (ok) {
                            // Refresh user info (tierCode)
                            await context.read<AuthProvider>().fetchUser();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Thanh toán thành công. Bạn đã là Pro!',
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    sub.errorMessage ?? 'Nâng cấp thất bại',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Nâng cấp Pro'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () async {
                        await sub.setTier('free');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã chuyển về gói Free'),
                            ),
                          );
                        }
                      },
                      child: const Text('Chuyển về Free'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _benefitsList(context),
            ],
          ),
        );
      },
    );
  }

  Widget _benefitsList(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Free:', style: Theme.of(context).textTheme.titleMedium),
        _bullet('Không thể tải nhạc xuống (ẩn nút tải)'),
        _bullet('Giới hạn chuyển bài: 6 lần/12 giờ'),
        _bullet('Trộn bài có thể lặp lại'),
        const SizedBox(height: 8),
        Text('Pro:', style: Theme.of(context).textTheme.titleMedium),
        _bullet('Có nút tải nhạc nghe offline'),
        _bullet('Chuyển bài không giới hạn'),
        _bullet('Trộn bài không bị trùng lặp'),
        const SizedBox(height: 4),
        Text(
          'Lưu ý: VNPay ở chế độ TEST, chỉ dùng để demo. Không dùng key test trên production.',
          style: TextStyle(color: textColor?.withAlpha(160), fontSize: 12),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
