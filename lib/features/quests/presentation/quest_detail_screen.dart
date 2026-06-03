import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/quest_snack_bar.dart';
import '../../gamification/presentation/gamification_provider.dart';
import '../domain/quest_entity.dart';
import 'quest_provider.dart';

class QuestDetailScreen extends ConsumerStatefulWidget {
  const QuestDetailScreen({
    required this.questId,
    super.key,
    this.initialQuest,
  });

  final int questId;
  final QuestEntity? initialQuest;

  @override
  ConsumerState<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends ConsumerState<QuestDetailScreen> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final loadedQuest = ref
        .watch(questsProvider)
        .quests
        .cast<QuestEntity?>()
        .firstWhere((item) => item?.id == widget.questId, orElse: () => null);
    final quest = loadedQuest ?? widget.initialQuest;

    if (quest == null) {
      return const Scaffold(body: Center(child: Text('Quest not found')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: context.pop,
        ),
        title: Text(quest.category.label),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(
                tag: 'quest_hero_${quest.id}',
                flightShuttleBuilder:
                    (context, animation, direction, fromContext, toContext) {
                      return Material(
                        color: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _DetailHeroPanel(quest: quest),
                        ),
                      );
                    },
                child: Material(
                  color: Colors.transparent,
                  child: _DetailHeroPanel(quest: quest),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08),
              const SizedBox(height: 20),
              _DetailPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quest Brief',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      quest.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _StatBadge(
                          icon: Icons.star_rounded,
                          label: _starsFor(quest.difficulty),
                        ),
                        const SizedBox(width: 10),
                        _StatBadge(
                          icon: Icons.schedule_rounded,
                          label: '${quest.estimatedMinutes} min',
                        ),
                        const SizedBox(width: 10),
                        _StatBadge(
                          icon: Icons.monetization_on_rounded,
                          label: '${quest.xpReward} XP',
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _CompleteQuestButton(
                completed: quest.isCompleted,
                isLoading: _isCompleting,
                onPressed: () => _completeQuest(quest),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeQuest(QuestEntity quest) async {
    if (_isCompleting || quest.isCompleted) {
      return;
    }
    setState(() => _isCompleting = true);
    await HapticFeedback.mediumImpact();

    final failure = await ref.read(questsProvider.notifier).complete(quest);
    if (failure != null) {
      if (mounted) {
        setState(() => _isCompleting = false);
        showQuestSnackBar(
          context,
          message: failure.message,
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        );
      }
      return;
    }

    final event = await ref
        .read(gamificationProvider.notifier)
        .completeQuest(quest);
    if (mounted) {
      setState(() => _isCompleting = false);
      await _showCompletion(context, event);
    }
  }

  Future<void> _showCompletion(
    BuildContext context,
    GamificationEvent event,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.palette.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animations/confetti.json', height: 130),
              Text(
                '+${event.xpGained} XP',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate().fadeIn().moveY(
                end: -12,
                duration: 900.ms,
                curve: Curves.easeOut,
              ),
              if (event.leveledUp) ...[
                const SizedBox(height: 10),
                Text('Level ${event.newLevel}')
                    .animate()
                    .scale(curve: Curves.elasticOut)
                    .shimmer(color: AppColors.gold),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailHeroPanel extends StatelessWidget {
  const _DetailHeroPanel({required this.quest});

  final QuestEntity quest;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        children: [
          Icon(_categoryIcon(quest.category), size: 78, color: AppColors.gold)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1800.ms, color: AppColors.goldGlow),
          const SizedBox(height: 18),
          Text(
            quest.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ],
      ),
    );
  }
}

class _CompleteQuestButton extends StatelessWidget {
  const _CompleteQuestButton({
    required this.completed,
    required this.isLoading,
    required this.onPressed,
  });

  final bool completed;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: completed || isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: completed ? Colors.grey.shade800 : AppColors.gold,
        foregroundColor: completed
            ? Colors.grey.shade500
            : AppColors.onAccent,
        disabledBackgroundColor: isLoading
            ? AppColors.goldDark
            : Colors.grey.shade800,
        disabledForegroundColor: isLoading
            ? AppColors.onAccent
            : Colors.grey.shade500,
      ),
      child: SizedBox(
        height: 52,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onAccent,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      completed ? 'QUEST COMPLETED' : AppStrings.completeQuest,
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: child,
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? context.palette.textPrimary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.palette.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(label, style: Theme.of(context).textTheme.labelSmall),
            ),
          ],
        ),
      ),
    );
  }
}

String _starsFor(QuestDifficulty difficulty) {
  return switch (difficulty) {
    QuestDifficulty.easy => '1 Star',
    QuestDifficulty.medium => '2 Stars',
    QuestDifficulty.hard => '3 Stars',
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
