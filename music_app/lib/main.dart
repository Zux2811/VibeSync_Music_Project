import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'package:music_app/presentation/auth/signin_option_page.dart';
import 'presentation/auth/signin_page.dart';
import 'presentation/auth/signup_page.dart';
import 'presentation/auth/avatar_selection_page.dart';

import 'presentation/auth/auth_provider.dart'; // Import AuthProvider
import 'presentation/home/home_page.dart';
import 'presentation/splash/splash_page.dart';
import 'presentation/player/player_provider.dart';
import 'presentation/subscription/subscription_provider.dart';
import 'presentation/player/player_page.dart';
import 'presentation/theme/theme_provider.dart';
import 'presentation/theme/theme_selection_page.dart';
import 'presentation/home/tabs/library/library_provider.dart';
import 'presentation/subscription/subscription_status_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  // Treat missing onboarding flag as complete for legacy users
  // Onboarding semantics: this flag is set to false after register/login (for new users)
  // and flipped to true after theme is confirmed in onboarding. Avatar upload success
  // does NOT block onboarding completion; failed uploads can be retried later using
  // the retained 'user_avatar' path.
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? true;

  final startRoute =
      (token != null && token.isNotEmpty)
          ? (onboardingComplete ? '/home' : '/avatar_selection')
          : '/signin_option';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MusicApp(initialRoute: startRoute),
    ),
  );
}

class MusicApp extends StatelessWidget {
  final String? initialRoute;
  const MusicApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Music App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          routes: {
            '/splash': (context) => const SplashPage(),
            '/signin_option': (context) => const SignInOptionPage(),
            '/signin': (context) => const SignInPage(),
            '/signup': (context) => const SignUpPage(),
            '/avatar_selection': (context) => const AvatarSelectionPage(),
            '/avatar_selection_google':
                (context) => const AvatarSelectionPage(isGoogleSignIn: true),
            // Onboarding-only route for theme selection. Do not use outside signup flow.
            '/onboarding_theme_selection':
                (context) => const ThemeSelectionPage(isFirstTime: true),
            '/home': (context) => const HomePage(),
            '/player': (context) => const PlayerPage(),
            '/subscription_status': (context) => const SubscriptionStatusPage(),
          },
        );
      },
    );
  }
}
