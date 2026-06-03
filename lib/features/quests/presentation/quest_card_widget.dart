import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/quest_entity.dart';

class QuestCard extends StatelessWidget {
  const QuestCard({
    required this.quest,
    required this.index,
    required this.onTap,
    required this.onComplete,
    super.key,
    this.justCompleted = false,
  });

  final QuestEntity quest;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool justCompleted;

  @override
  Widget build(BuildContext context) {
    final accent = _difficultyColor(quest.difficulty);
    return Dismissible(
      key: ValueKey('quest_card_${quest.id}_${quest.isCompleted}'),
      direction: quest.isCompleted
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onComplete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColors.easy.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check_circle, color: AppColors.easy),
      ),
      child: ClipRect(
        child:
            Hero(
                  tag: 'quest_hero_${quest.id}',
                  flightShuttleBuilder:
                      (
                        flightContext,
                        animation,
                        direction,
                        fromContext,
                        toContext,
                      ) {
                        return Material(
                          color: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _QuestCardFrame(
                              quest: quest,
                              accent: accent,
                              justCompleted: false,
                              onTap: null,
                              onComplete: onComplete,
                            ),
                          ),
                        );
                      },
                  child: Material(
                    color: Colors.transparent,
                    child: _QuestCardFrame(
                      quest: quest,
                      accent: accent,
                      justCompleted: justCompleted,
                      onTap: onTap,
                      onComplete: onComplete,
                    ),
                  ),
                )
                .animate(delay: (index * 80).ms)
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.18, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _QuestCardFrame extends StatelessWidget {
  const _QuestCardFrame({
    required this.quest,
    required this.accent,
    required this.justCompleted,
    required this.onComplete,
    this.onTap,
  });

  final QuestEntity quest;
  final Color accent;
  final bool justCompleted;
  final VoidCallback? onTap;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: 260.ms,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: justCompleted
            ? AppColors.easy.withValues(alpha: 0.18)
            : context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: justCompleted ? AppColors.easy : context.palette.border,
        ),
        boxShadow: quest.isCompleted || justCompleted
            ? const [
                BoxShadow(
                  color: Color(0x334CAF50),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: 180.ms,
            opacity: quest.isCompleted ? 0.6 : 1,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 128,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _CategoryIcon(category: quest.category),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quest.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: quest.isCompleted
                                              ? context.palette.textSecondary
                                              : context.palette.textPrimary,
                                          decoration: quest.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                  ),
                                  if (quest.isCompleted) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'COMPLETED',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: AppColors.easy),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CompletionCheckbox(
                              completed: quest.isCompleted,
                              onPressed: onComplete,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _DifficultyBadge(difficulty: quest.difficulty),
                            _MetaPill(
                              icon: Icons.category_rounded,
                              label: quest.category.label,
                            ),
                            _MetaPill(
                              icon: Icons.monetization_on_rounded,
                              label: '${quest.xpReward} XP',
                              color: AppColors.gold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (quest.isCompleted)
            Positioned(
              top: 8,
              right: 8,
              child: const _CompletedBadge().animate().fadeIn(duration: 180.ms),
            ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onTap == null ? null : () => _showQuestMenu(context),
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }

  void _showQuestMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_full_rounded),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.of(context).pop();
                  onTap?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: const Text('Mark Complete'),
                enabled: !quest.isCompleted,
                onTap: () {
                  Navigator.of(context).pop();
                  onComplete();
                },
              ),
              ListTile(
                leading: const Icon(Icons.skip_next_rounded),
                title: const Text('Skip'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletionCheckbox extends StatelessWidget {
  const _CompletionCheckbox({required this.completed, required this.onPressed});

  final bool completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: completed,
      onChanged: completed ? null : (_) => onPressed(),
      activeColor: AppColors.easy,
      checkColor: Colors.white,
      side: BorderSide(
        color: completed ? AppColors.easy : context.palette.border,
      ),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (completed) {
          return AppColors.easy;
        }
        return Colors.transparent;
      }),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.easy.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.easy),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: AppColors.easy),
          SizedBox(width: 4),
          Text(
            'DONE',
            style: TextStyle(
              color: AppColors.easy,
              fontSize: 10,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final QuestDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_difficultyIcon(difficulty), color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            difficulty.label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final QuestCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.palette.border),
      ),
      child: Icon(_categoryIcon(category), color: AppColors.gold, size: 20),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pillColor = color ?? context.palette.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: pillColor, size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: pillColor),
        ),
      ],
    );
  }
}

Color _difficultyColor(QuestDifficulty difficulty) {
  return switch (difficulty) {
    QuestDifficulty.easy => AppColors.easy,
    QuestDifficulty.medium => AppColors.medium,
    QuestDifficulty.hard => AppColors.hard,
  };
}

IconData _difficultyIcon(QuestDifficulty difficulty) {
  return switch (difficulty) {
    QuestDifficulty.easy => Icons.sports_martial_arts_rounded,
    QuestDifficulty.medium => Icons.shield_outlined,
    QuestDifficulty.hard => Icons.dangerous_outlined,
  };
}

IconData _categoryIcon(QuestCategory category) {
  return switch (category) {
    QuestCategory.combat => Icons.local_fire_department_rounded,
    QuestCategory.exploration => Icons.explore_rounded,
    QuestCategory.crafting => Icons.hardware_rounded,
    QuestCategory.social => Icons.forum_rounded,
  };
}
