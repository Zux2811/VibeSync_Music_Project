import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/sources/api_service.dart';
import '../../theme/theme_provider.dart';
import '../../auth/auth_provider.dart';
import '../../settings/profile_page.dart';
import '../../settings/change_password_page.dart';
import '../../artist/artist_verification_page.dart';
import '../../artist/artist_dashboard_page.dart';
// Conditional import for web
import 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils.dart'
    as web_utils;

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  Future<void> _logout(BuildContext context) async {
    await ApiService.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/signin_option');
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch user data when the tab is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          _buildProfileCard(context),
          const SizedBox(height: 24),

          // Theme Section
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildThemeSection(context),
          const SizedBox(height: 32),

          // Artist/Admin Section (role-based)
          _buildRoleBasedSection(context),
          const SizedBox(height: 32),

          // Logout Section
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.red,
            ),
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        Widget avatarWidget;
        String userName;

        if (authProvider.isFetchingUser) {
          avatarWidget = const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
          userName = 'Loading...';
        } else if (authProvider.fetchUserError != null ||
            authProvider.user == null) {
          avatarWidget = const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: Icon(Icons.error_outline, color: Colors.white),
          );
          userName = 'Tap to retry';
        } else {
          final user = authProvider.user!;
          userName = user.name ?? 'Username';
          final hasAvatar =
              user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
          final avatarUrl =
              hasAvatar ? user.avatarUrl! : 'assets/logo/logo.png';
          avatarWidget = CircleAvatar(
            radius: 30,
            backgroundImage:
                hasAvatar
                    ? NetworkImage(avatarUrl) as ImageProvider
                    : AssetImage(avatarUrl),
            backgroundColor: Colors.grey.shade300,
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ).then((_) {
              // Refresh data when returning from profile page if needed
              if (authProvider.user == null ||
                  authProvider.fetchUserError != null) {
                authProvider.fetchUser();
              }
            });
          },
          child: Row(
            children: [
              avatarWidget,
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
        );
      },
    );
  }

  Widget _buildRoleBasedSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final items = <Widget>[];

        // Admin Dashboard (for admin users - ONLY on Web)
        if (user.isAdmin && kIsWeb) {
          items.add(
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.red,
                ),
              ),
              title: const Text('Admin Dashboard'),
              subtitle: const Text('Manage users, songs, and verifications'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () async {
                // Get token from SharedPreferences and open React admin dashboard
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('jwt_token') ?? '';
                web_utils.openAdminDashboard(token);
              },
            ),
          );
        }

        // Artist Dashboard (for artist users)
        if (user.isArtist) {
          items.add(
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mic, color: Colors.purple),
              ),
              title: const Text('Artist Dashboard'),
              subtitle: const Text('Manage your music and albums'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ArtistDashboardPage(),
                  ),
                );
              },
            ),
          );
        }

        // Become an Artist (for regular users who are not artists)
        if (user.isUser) {
          items.add(
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user, color: Colors.blue),
              ),
              title: const Text('Become an Artist'),
              subtitle: const Text('Apply for artist verification'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ArtistVerificationPage(),
                  ),
                );
              },
            ),
          );
        }

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.isAdmin
                  ? 'Administration'
                  : (user.isArtist ? 'Artist Tools' : 'Artist'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(children: items),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 1),
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
