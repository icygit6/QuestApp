import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../gamification/presentation/gamification_provider.dart';
import '../../quests/domain/quest_entity.dart';

class StatsWidget extends StatelessWidget {
  const StatsWidget({required this.gamification, super.key});

  final GamificationState gamification;

  @override
  Widget build(BuildContext context) {
    final favoriteCategory = _favoriteCategory();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.05,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _StatCard(
          title: 'Quests',
          value: gamification.totalQuestsCompleted.toString(),
          icon: Icons.task_alt_rounded,
        ),
        _StatCard(
          title: 'Streak',
          value: '${gamification.streak}d',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.medium,
        ),
        _StatCard(
          title: 'Total XP',
          value: gamification.totalXpEarned.toString(),
          icon: Icons.monetization_on_rounded,
          color: AppColors.gold,
        ),
        _ChartCard(
          title: 'This Week',
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    7,
                    (index) => FlSpot(
                      index.toDouble(),
                      ((gamification.totalQuestsCompleted + index) % 5 + 1)
                          .toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: AppColors.xpBlue,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        _ChartCard(
          title: 'XP Progress',
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 28,
              sectionsSpace: 0,
              sections: [
                PieChartSectionData(
                  value: gamification.xp.toDouble(),
                  color: AppColors.xpBlue,
                  radius: 14,
                  title: '',
                ),
                PieChartSectionData(
                  value: (gamification.nextLevelXp - gamification.xp)
                      .clamp(1, gamification.nextLevelXp)
                      .toDouble(),
                  color: AppColors.borderColor,
                  radius: 14,
                  title: '',
                ),
              ],
            ),
          ),
        ),
        _ChartCard(
          title: favoriteCategory,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 20,
              sections: QuestCategory.values
                  .map((category) {
                    return PieChartSectionData(
                      value: (gamification.categoryCounts[category.label] ?? 0)
                          .clamp(1, 999)
                          .toDouble(),
                      color: _categoryColor(category),
                      radius: 22,
                      title: '',
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }

  String _favoriteCategory() {
    if (gamification.categoryCounts.isEmpty) {
      return 'Favorite';
    }
    final entries = gamification.categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.xpBlue,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          TweenAnimationBuilder<int>(
            tween: IntTween(
              begin: 0,
              end: int.tryParse(value.replaceAll('d', '')) ?? 0,
            ),
            duration: 700.ms,
            builder: (context, number, _) {
              return Text(
                value.endsWith('d') ? '${number}d' : number.toString(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 15),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: child,
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08);
  }
}

Color _categoryColor(QuestCategory category) {
  return switch (category) {
    QuestCategory.combat => AppColors.hard,
    QuestCategory.exploration => AppColors.xpBlue,
    QuestCategory.crafting => AppColors.medium,
    QuestCategory.social => AppColors.easy,
  };
}
