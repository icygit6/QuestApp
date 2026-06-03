import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    required this.currentXp,
    required this.nextLevelXp,
    super.key,
    this.height = 12,
  });

  final int currentXp;
  final int nextLevelXp;
  final double height;

  @override
  Widget build(BuildContext context) {
    final progress = nextLevelXp == 0 ? 0.0 : currentXp / nextLevelXp;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: AppColors.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.xpBlue),
          );
        },
      ),
    );
  }
}
