import 'package:flutter/material.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/shared/widgets/bottom_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScaffold(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppConstants.logoPath,
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'القرآن الكريم والأذكار',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 16,
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 150,
                  child: LinearProgressIndicator(
                    backgroundColor: color.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}