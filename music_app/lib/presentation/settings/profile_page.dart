import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../../data/models/user_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_page.dart';
import '../playlists/user_playlists_page.dart';
import 'package:music_app/presentation/home/tabs/library/favorites_page.dart';
import 'package:music_app/data/models/playlist.dart';
import '../subscription/upgrade_pro_page.dart';
import '../subscription/subscription_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null && !authProvider.isFetchingUser) {
        authProvider.fetchUser();
      }
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    // If there's a saved onboarding avatar path, offer to upload it first
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('user_avatar');
    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (await file.exists()) {
        if (!mounted) return;
        final useSaved = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Use saved avatar?'),
                content: const Text(
                  'A previously selected avatar from onboarding was found. Would you like to upload it now or choose a new one?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Choose New'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Use Saved'),
                  ),
                ],
              ),
        );

        if (useSaved == true) {
          await context.read<AuthProvider>().uploadAvatar(file);
          // Clear the stored path after attempting upload
          await prefs.remove('user_avatar');
          return;
        }
      }
    }

    // Default flow: let user pick a new image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      await context.read<AuthProvider>().uploadAvatar(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // User Info Section
            _buildUserInfo(context),
            const SizedBox(height: 32),

            // User Activity Section
            _buildSectionTitle(context, 'Hoạt động'),
            _buildProfileMenu(context, iconColor),
            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionTitle(context, 'Cài đặt & Bảo mật'),
            _buildAppSettingsMenu(context, iconColor),
            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(context, iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isFetchingUser) {
          return const Center(child: CircularProgressIndicator());
        }

        if (authProvider.fetchUserError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(authProvider.fetchUserError!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => authProvider.fetchUser(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final User? user = authProvider.user;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Could not load user profile.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => authProvider.fetchUser(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
        final avatarUrl = hasAvatar ? user.avatarUrl! : 'assets/logo/logo.png';

        final userName = user.name ?? 'Username';
        final email = user.email ?? 'No email';
        final bio = user.bio ?? 'No bio yet.';

        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      hasAvatar
                          ? NetworkImage(avatarUrl) as ImageProvider
                          : AssetImage(avatarUrl),
                  backgroundColor: Colors.grey.shade300,
                  onBackgroundImageError: (_, __) {},
                ),
                Positioned(
                  bottom: 0,
                  right: -10,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).cardColor,
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        size: 24,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black87,
                      ),
                      onPressed: _pickAndUploadAvatar,
                      tooltip: 'Change Avatar',
                    ),
                  ),
                ),
                if (authProvider.isUploadingAvatar)
                  const CircularProgressIndicator(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditBioDialog(context, bio),
                  tooltip: 'Edit Bio',
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showEditBioDialog(BuildContext context, String currentBio) {
    final bioController = TextEditingController(text: currentBio);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Bio'),
          content: TextField(
            controller: bioController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tell us about yourself...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newBio = bioController.text;
                if (newBio == currentBio) {
                  Navigator.pop(context);
                  return;
                }

                // Store references before the async gap
                final authProvider = context.read<AuthProvider>();
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop(); // Pop the dialog

                try {
                  await authProvider.updateUserBio(newBio);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Bio updated successfully!')),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to update bio: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(
            context,
          ).textTheme.bodySmall?.color?.withAlpha(153), // 0.6 opacity
        ),
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context, Color iconColor) {
    return _buildMenuCard(context, [
      _buildMenuTile(Icons.queue_music_outlined, 'Playlist của bạn', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserPlaylistsPage()),
        );
      }),
      _buildMenuTile(Icons.favorite_border, 'Bài hát yêu thích', () {
        // FavoritesPage requires a Playlist object, but it fetches songs internally.
        // We can pass a temporary Playlist object.
        final dummyPlaylist = Playlist(
          id: '-1',
          name: 'Favorite Songs',
          songs: [],
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FavoritesPage(favoritesPlaylist: dummyPlaylist),
          ),
        );
      }),
      _buildMenuTile(Icons.history, 'Lịch sử nghe', () {}),
    ]);
  }

  Widget _buildAppSettingsMenu(BuildContext context, Color iconColor) {
    return _buildMenuCard(context, [
      // Upgrade Pro button
      Consumer<SubscriptionProvider>(
        builder: (context, sub, _) {
          final title = sub.isPro ? 'Bạn đang ở gói Pro' : 'Đăng ký gói Pro';
          return ListTile(
            leading: Icon(
              Icons.workspace_premium,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(title),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () async {
              if (sub.isPro) {
                // Force refresh from server before navigating, to avoid stale state
                final sp = await SharedPreferences.getInstance();
                final token = sp.getString('jwt_token');
                if (token != null && token.isNotEmpty && context.mounted) {
                  await context
                      .read<SubscriptionProvider>()
                      .fetchMySubscription(token);
                }
                if (!context.mounted) return;
                Navigator.of(context).pushNamed('/subscription_status');
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpgradeProPage(),
                  ),
                );
              }
            },
          );
        },
      ),
      _buildMenuTile(Icons.lock_outline, 'Đổi mật khẩu', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
        );
      }),
      _buildMenuTile(Icons.notifications_none, 'Thông báo', () {}),
      _buildMenuTile(Icons.info_outline, 'Giới thiệu', () {}),
    ]);
  }

  Widget _buildLogoutButton(BuildContext context, Color iconColor) {
    return _buildMenuCard(context, [
      ListTile(
        leading: Icon(Icons.logout, color: Colors.redAccent.shade200),
        title: Text(
          'Đăng xuất',
          style: TextStyle(
            color: Colors.redAccent.shade200,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () async {
          await context.read<AuthProvider>().logout();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/signin_option',
              (route) => false,
            );
          }
        },
      ),
    ]);
  }

  Widget _buildMenuCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha(51), // 0.2 opacity
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  ListTile _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
