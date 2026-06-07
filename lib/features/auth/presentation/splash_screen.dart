import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(2500.ms, _routeAfterDelay);
  }

  void _routeAfterDelay() {
    if (!mounted) {
      return;
    }
    final auth = ref.read(authStateProvider);
    if (auth.status == AuthStatus.authenticated) {
      context.go('/quests');
    } else if (auth.status != AuthStatus.loading) {
      context.go('/login');
    } else {
      Future<void>.delayed(400.ms, _routeAfterDelay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 168)
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                )
                .then()
                .shimmer(duration: 1800.ms, color: AppColors.goldGlow),
            const SizedBox(height: 16),
            Text(
                  AppStrings.appTitle,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.gold,
                    shadows: const [
                      Shadow(color: AppColors.goldGlow, blurRadius: 22),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.82, 0.82),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 10),
            Text(
              AppStrings.loading,
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
