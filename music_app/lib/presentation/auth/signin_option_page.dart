import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:music_app/presentation/auth/signin_page.dart';
import 'package:music_app/presentation/auth/signup_page.dart';
import 'package:music_app/presentation/auth/auth_provider.dart';
import 'package:music_app/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInOptionPage extends StatefulWidget {
  const SignInOptionPage({super.key});

  @override
  State<SignInOptionPage> createState() => _SignInOptionPageState();
}

class _SignInOptionPageState extends State<SignInOptionPage> {
  bool _isGoogleLoading = false;

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final google = GoogleSignIn(
        serverClientId: ApiConstants.googleWebClientId,
      );
      final account = await google.signIn();
      if (account == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã huỷ đăng nhập Google')),
        );
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được idToken từ Google')),
        );
        return;
      }

      // Use AuthProvider to handle Google login
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.loginWithGoogle(idToken);

      if (success) {
        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();

        // Check if this is a returning user (previously authenticated on this device)
        final isReturningUser =
            prefs.getBool('device_authenticated_before') ?? false;

        // Try to use Google photoUrl as profile avatar automatically
        try {
          final google = GoogleSignIn(scopes: const ['email', 'profile']);
          final current = await google.signInSilently();
          var photoUrl = (current ?? account).photoUrl;
          if (photoUrl != null && photoUrl.isNotEmpty) {
            // Request higher resolution Google avatar if available
            if (!photoUrl.contains('sz=')) {
              photoUrl = '$photoUrl${photoUrl.contains('?') ? '&' : '?'}sz=512';
            }
            final resp = await http.get(Uri.parse(photoUrl));
            if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
              final tmpPath =
                  '${Directory.systemTemp.path}/google_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final file = File(tmpPath);
              await file.writeAsBytes(resp.bodyBytes);
              // Save path to SharedPreferences for confirmation at AvatarSelectionPage
              await prefs.setString('user_avatar', file.path);
            }
          }
        } catch (_) {
          // best-effort only; ignore errors
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập Google thành công!')),
        );
        await Future.delayed(const Duration(milliseconds: 400));

        // Navigation logic based on sign-in history
        if (isReturningUser) {
          // Returning user: skip avatar and theme selection, go directly to home
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // First-time user: show avatar selection
          Navigator.pushReplacementNamed(context, '/avatar_selection');
        }
      } else {
        final msg = authProvider.errorMessage ?? 'Đăng nhập Google thất bại';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google Sign-In Error: $e')));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading:
            canPop
                ? IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                )
                : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 200,
                  height: 200,
                ),
              ),

              Text(
                "Let's get you in",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 40),

              // Gmail button with loading state
              OutlinedButton.icon(
                onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(61),
                  ),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon:
                    _isGoogleLoading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Icon(
                          FontAwesomeIcons.google,
                          size: 20,
                          color: Theme.of(context).iconTheme.color,
                        ),
                label: Text(
                  _isGoogleLoading ? 'Signing in…' : 'Continue with Gmail',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 15),
              _buildSocialButton(Icons.facebook, 'Continue with Facebook'),
              const SizedBox(height: 15),
              _buildSocialButton(Icons.apple, 'Continue with Apple'),

              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).dividerColor,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).dividerColor,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Login with password
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log in with a password',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String text) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
