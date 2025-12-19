import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:music_app/presentation/auth/signin_page.dart';
import 'package:music_app/presentation/auth/signup_page.dart';
import 'package:music_app/presentation/auth/auth_provider.dart';
import 'package:music_app/core/constants/api_constants.dart';
import 'package:music_app/core/constants/app_colors.dart';
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
      // For web: use clientId with scopes to get idToken
      // For mobile: use serverClientId
      final google =
          kIsWeb
              ? GoogleSignIn(
                clientId: ApiConstants.googleWebClientId,
                scopes: ['email', 'openid', 'profile'],
              )
              : GoogleSignIn(
                serverClientId: ApiConstants.googleWebClientId,
                scopes: ['email', 'openid', 'profile'],
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
      final accessToken = auth.accessToken;

      // On web, idToken might be null, use accessToken as fallback
      if (idToken == null && accessToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được token từ Google')),
        );
        return;
      }

      // Use AuthProvider to handle Google login with both tokens
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );

      if (success) {
        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();

        // Check if this is a returning user (previously authenticated on this device)
        final isReturningUser =
            prefs.getBool('device_authenticated_before') ?? false;

        // Save Google photoUrl for avatar selection (works on both web and mobile)
        try {
          var photoUrl = account.photoUrl;
          if (photoUrl != null && photoUrl.isNotEmpty) {
            // Request higher resolution Google avatar if available
            if (!photoUrl.contains('sz=')) {
              photoUrl = '$photoUrl${photoUrl.contains('?') ? '&' : '?'}sz=512';
            }
            // Save URL instead of file path (works on web and mobile)
            await prefs.setString('google_avatar_url', photoUrl);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Center(
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 80,
                  height: 80,
                ),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'Millions of songs.\nFree on VibeSync.',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Sign up free button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Sign up free',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Continue with Google
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.textDark,
                    side: BorderSide(
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon:
                      _isGoogleLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const FaIcon(FontAwesomeIcons.google, size: 18),
                  label: Text(
                    _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Continue with Facebook (placeholder)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.textDark,
                    side: BorderSide(
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.facebook, size: 18),
                  label: const Text(
                    'Continue with Facebook',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Continue with Apple (placeholder)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.textDark,
                    side: BorderSide(
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.apple, size: 18),
                  label: const Text(
                    'Continue with Apple',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Log in link
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  );
                },
                child: Text(
                  'Log in',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 40),
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
