import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class QuestEmptyWidget extends StatelessWidget {
  const QuestEmptyWidget({
    super.key,
    this.title = AppStrings.noQuests,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/empty_quests.json',
              height: 150,
              repeat: true,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 14),
            const Icon(Icons.inventory_2_outlined, color: AppColors.gold),
          ],
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
      ),
    );
  }
}
