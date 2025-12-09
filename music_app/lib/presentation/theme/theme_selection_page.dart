import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import '../auth/auth_provider.dart';

class ThemeSelectionPage extends StatefulWidget {
  final bool isFirstTime;

  const ThemeSelectionPage({Key? key, this.isFirstTime = false})
    : super(key: key);

  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  AppThemeMode? _selectedTheme;

  @override
  void initState() {
    super.initState();
    // Initialize with the current theme from provider
    _selectedTheme = context.read<ThemeProvider>().themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        color: theme.scaffoldBackgroundColor, // Dynamic background
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Choose Your Theme',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a theme that suits your preference',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Theme Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ThemeCard(
                      title: 'Light Theme',
                      description: 'Bright and clean interface',
                      icon: Icons.light_mode_outlined,
                      isSelected: _selectedTheme == AppThemeMode.light,
                      onTap: () => _previewTheme(AppThemeMode.light),
                    ),
                    const SizedBox(height: 24),
                    _ThemeCard(
                      title: 'Dark Theme',
                      description: 'Easy on the eyes',
                      icon: Icons.dark_mode_outlined,
                      isSelected: _selectedTheme == AppThemeMode.dark,
                      onTap: () => _previewTheme(AppThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Continue Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: _confirmTheme,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previewTheme(AppThemeMode mode) {
    setState(() {
      _selectedTheme = mode;
    });
    context.read<ThemeProvider>().previewTheme(mode);
  }

  void _confirmTheme() async {
    if (_selectedTheme == null) return;

    // Optional safety: ensure token exists when running onboarding-specific logic
    final prefs = await SharedPreferences.getInstance();
    if (widget.isFirstTime) {
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please sign in again.'),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/signin_option',
          (_) => false,
        );
        return;
      }
    }

    final themeProvider = context.read<ThemeProvider>();
    await themeProvider.setTheme(_selectedTheme!);

    if (!mounted) return;

    if (widget.isFirstTime) {
      await _handleOnboardingAfterThemeConfirmation(prefs);
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  // Onboarding handler extracted for clarity. Note: onboarding completion is tied
  // to theme confirmation, not avatar upload success. If upload fails or the file
  // is missing, we still mark onboarding_complete = true and retain 'user_avatar'
  // to allow a later retry from profile/settings.
  Future<void> _handleOnboardingAfterThemeConfirmation(
    SharedPreferences prefs,
  ) async {
    final avatarPath = prefs.getString('user_avatar');

    if (avatarPath != null && avatarPath.isNotEmpty) {
      bool needsFetch = false;

      // Verify the file still exists before attempting upload
      final avatarFile = File(avatarPath);
      if (await avatarFile.exists()) {
        // Upload avatar
        final authProvider = context.read<AuthProvider>();
        final uploadSuccess = await authProvider.uploadAvatar(avatarFile);

        if (!mounted) return;

        if (!uploadSuccess) {
          // Upload failed; we'll fetch user explicitly
          needsFetch = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Failed to upload avatar. Your profile picture will be updated later.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // On success, uploadAvatar() already fetched user; no extra fetch.
      } else {
        // File no longer exists; fetch user to ensure state is populated
        needsFetch = true;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Avatar file not found. Using default avatar.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (needsFetch) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.fetchUser();
      }

      // Documenting semantics: onboarding completion is tied to theme, not avatar upload
      await prefs.setBool('onboarding_complete', true);

      // Only clear stored avatar path after a successful upload.
      // Keep it if upload failed or file was missing to allow retry later.
      if (!needsFetch) {
        await prefs.remove('user_avatar');
      }
    } else {
      // If no avatar was selected in the onboarding flow, fetch user data once
      final authProvider = context.read<AuthProvider>();
      await authProvider.fetchUser();

      // Documenting semantics: completion when no avatar was selected
      await prefs.setBool('onboarding_complete', true);
    }
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 3 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),

            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary)
            else
              Icon(Icons.arrow_forward_ios, color: colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}
