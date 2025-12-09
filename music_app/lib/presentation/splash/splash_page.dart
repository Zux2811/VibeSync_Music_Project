import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_app/data/sources/api_service.dart';
import 'package:music_app/presentation/auth/signin_option_page.dart';
import 'package:music_app/presentation/home/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _heartbeatAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _heartbeatAnimation = Tween<double>(begin: 0.99, end: 1.01).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutCubic),
    );

    // ⏳ Sau 2.5 giây, kiểm tra token và điều hướng
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    final token = await ApiService.getToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacement(_createRoute(const HomePage()));
    } else {
      Navigator.of(
        context,
      ).pushReplacement(_createRoute(const SignInOptionPage()));
    }
  }

  // ✨ Hiệu ứng chuyển trang fade mượt mà
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return FadeTransition(opacity: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return Transform.scale(
              scale: _heartbeatAnimation.value,
              child: Image.asset(
                'assets/logo/logo_splash.jpg',
                width: size.width * 1,
                height: size.height * 0.6,
              ),
            );
          },
        ),
      ),
    );
  }
}
