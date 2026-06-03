import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../gamification/domain/achievement.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({required this.achievement, super.key});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: achievement.isUnlocked
          ? () => _showDetails(context, achievement)
          : null,
      child:
          Container(
                width: 150,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: achievement.isUnlocked
                        ? AppColors.gold
                        : AppColors.borderColor,
                  ),
                  boxShadow: achievement.isUnlocked
                      ? const [
                          BoxShadow(
                            color: AppColors.goldGlow,
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          achievement.isUnlocked
                              ? Icons.emoji_events_rounded
                              : Icons.lock_rounded,
                          color: achievement.isUnlocked
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          achievement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          achievement.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (!achievement.isUnlocked)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.36),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              )
              .animate(target: achievement.isUnlocked ? 1 : 0)
              .shimmer(color: AppColors.goldGlow, duration: 1800.ms),
    );
  }

  void _showDetails(BuildContext context, Achievement achievement) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(achievement.title),
          content: Text(
            achievement.unlockedAt == null
                ? achievement.description
                : '${achievement.description}\nUnlocked ${DateFormatter.readable(achievement.unlockedAt!)}',
          ),
        );
      },
    );
  }
}
