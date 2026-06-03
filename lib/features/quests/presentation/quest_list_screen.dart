import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/quest_snack_bar.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../../core/widgets/xp_progress_bar.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../gamification/domain/achievement.dart';
import '../../gamification/presentation/gamification_provider.dart';
import '../domain/quest_entity.dart';
import 'quest_card_widget.dart';
import 'quest_provider.dart';

class QuestListScreen extends ConsumerStatefulWidget {
  const QuestListScreen({super.key});

  @override
  ConsumerState<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends ConsumerState<QuestListScreen> {
  final _scrollController = ScrollController();
  final Set<int> _flashingQuestIds = <int>{};
  String? _floatingXp;
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSwipeHint());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 360) {
      ref.read(questsProvider.notifier).loadMore();
    }
  }

  Future<void> _loadSwipeHint() async {
    final preferences = ref.read(sharedPreferencesProvider);
    final seen = preferences.getBool('has_seen_swipe_hint') ?? false;
    if (!mounted || seen) {
      return;
    }
    setState(() => _showSwipeHint = true);
    await Future<void>.delayed(const Duration(seconds: 3));
    await preferences.setBool('has_seen_swipe_hint', true);
    if (mounted) {
      setState(() => _showSwipeHint = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questState = ref.watch(questsProvider);
    final quests = ref.watch(filteredQuestsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final user = ref.watch(authStateProvider).user;
    final gamification = ref.watch(gamificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.realmTitle),
            const SizedBox(height: 6),
            SizedBox(
              width: 180,
              child: XpProgressBar(
                currentXp: gamification.xp,
                nextLevelXp: gamification.nextLevelXp,
                height: 6,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: context.palette.surfaceAlt,
              foregroundImage: user?.image.isNotEmpty == true
                  ? CachedNetworkImageProvider(user!.image)
                  : null,
              child: user?.image.isNotEmpty == true
                  ? null
                  : const Icon(Icons.person_rounded),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: context.palette.surface,
            onRefresh: () =>
                ref.read(questsProvider.notifier).load(refresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              clipBehavior: Clip.hardEdge,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                    child: Column(
                      children: [
                        _HeaderCard(gamification: gamification),
                        const SizedBox(height: 16),
                        const _QuestSearchBar(),
                        const SizedBox(height: 12),
                        const _FilterRow(),
                      ],
                    ),
                  ),
                ),
                if (questState.status == QuestStatus.loading)
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverToBoxAdapter(child: _LoadingCards()),
                  )
                else if (questState.status == QuestStatus.error)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: QuestErrorWidget(
                      message: questState.message ?? 'Unable to load quests.',
                      onRetry: () =>
                          ref.read(questsProvider.notifier).load(refresh: true),
                    ),
                  )
                else if (quests.isEmpty && searchQuery.trim().isNotEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySearchState(),
                  )
                else if (quests.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: QuestEmptyWidget(
                      subtitle: 'Try a different search or filter.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList.builder(
                      itemCount:
                          quests.length + (questState.isFetchingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= quests.length) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 18),
                            child: ShimmerCard(),
                          );
                        }
                        final quest = quests[index];
                        return ClipRect(
                          child: Stack(
                            children: [
                              QuestCard(
                                quest: quest,
                                index: index,
                                justCompleted: _flashingQuestIds.contains(
                                  quest.id,
                                ),
                                onTap: () => context.push(
                                  '/quests/${quest.id}',
                                  extra: quest,
                                ),
                                onComplete: () => _completeQuest(quest),
                              ),
                              if (index == 0 && _showSwipeHint)
                                Positioned(
                                  top: 8,
                                  right: 10,
                                  child:
                                      Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.palette.surfaceAlt,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: AppColors.gold,
                                              ),
                                            ),
                                            child: Text(
                                              'Swipe to complete ->',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (controller) => controller
                                                .repeat(reverse: true),
                                          )
                                          .moveX(end: 8, duration: 650.ms),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_floatingXp != null)
            Positioned(
              left: 0,
              right: 0,
              top: 120,
              child: Center(
                child:
                    Text(
                          _floatingXp!,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.gold,
                                shadows: const [
                                  Shadow(
                                    color: AppColors.goldGlow,
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                        )
                        .animate()
                        .fadeIn()
                        .then(delay: 800.ms)
                        .moveY(
                          end: -60,
                          duration: 1000.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _completeQuest(QuestEntity quest) async {
    if (quest.isCompleted) {
      return;
    }
    await HapticFeedback.mediumImpact();
    await ref
        .read(sharedPreferencesProvider)
        .setBool('has_seen_swipe_hint', true);
    if (mounted) {
      setState(() {
        _showSwipeHint = false;
        _flashingQuestIds.add(quest.id);
      });
    }

    final failure = await ref.read(questsProvider.notifier).complete(quest);
    if (failure != null) {
      if (mounted) {
        setState(() => _flashingQuestIds.remove(quest.id));
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
    if (!mounted) {
      return;
    }
    setState(() => _floatingXp = '+${event.xpGained} XP');
    Future<void>.delayed(450.ms, () {
      if (mounted) {
        setState(() => _flashingQuestIds.remove(quest.id));
      }
    });
    Future<void>.delayed(1600.ms, () {
      if (mounted) {
        setState(() => _floatingXp = null);
      }
    });
    if (!mounted) {
      return;
    }
    for (final achievement in event.unlockedAchievements) {
      await _showAchievementDialog(context, achievement);
    }
    if (event.leveledUp && mounted) {
      await _showLevelUpDialog(context, event.newLevel);
    }
  }

  Future<void> _showAchievementDialog(
    BuildContext context,
    Achievement achievement,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.palette.surface,
          title: Text(
            achievement.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          content:
              Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/animations/achievement.json',
                        height: 128,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                  .animate()
                  .shake(duration: 600.ms)
                  .then()
                  .shimmer(color: AppColors.gold, duration: 1500.ms),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLAIM'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLevelUpDialog(BuildContext context, int level) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.palette.surface,
          content:
              Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/animations/level_up.json',
                        height: 150,
                      ),
                      Text(
                        'LEVEL $level',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(color: AppColors.gold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your legend grows.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    curve: Curves.elasticOut,
                  )
                  .shimmer(duration: 2000.ms, color: AppColors.gold),
        );
      },
    );
  }
}

class _EmptySearchState extends ConsumerWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: context.palette.textSecondary,
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              'No quests match your search',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () =>
                  ref.read(searchQueryProvider.notifier).state = '',
              icon: const Icon(Icons.close_rounded),
              label: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.gamification});

  final GamificationState gamification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.surfaceAlt, context.palette.surface],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${gamification.level}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onAccent,
                    ),
                  ),
                ),
              ).animate().scale(curve: Curves.elasticOut),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${gamification.level} Adventurer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${gamification.xp} / ${gamification.nextLevelXp} XP',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: gamification.streak > 0
                    ? '${gamification.streak}-day streak'
                    : 'Complete a quest to start a streak',
                child: Opacity(
                  opacity: gamification.streak > 0 ? 1 : 0.4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset('assets/animations/streak.json', width: 42),
                      Text(
                        '${gamification.streak}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          XpProgressBar(
            currentXp: gamification.xp,
            nextLevelXp: gamification.nextLevelXp,
          ),
        ],
      ),
    );
  }
}

class _QuestSearchBar extends ConsumerWidget {
  const _QuestSearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    return SearchBar(
      hintText: 'Search quests',
      leading: Icon(
        query.isEmpty ? Icons.search_rounded : Icons.close_rounded,
        color: AppColors.gold,
      ).animate(key: ValueKey(query.isEmpty)).scale(duration: 180.ms),
      onChanged: (value) =>
          ref.read(searchQueryProvider.notifier).state = value,
      trailing: query.isEmpty
          ? null
          : [
              IconButton(
                tooltip: 'Clear search',
                onPressed: () =>
                    ref.read(searchQueryProvider.notifier).state = '',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
      backgroundColor: WidgetStatePropertyAll(context.palette.surface),
      side: WidgetStatePropertyAll(
        BorderSide(color: context.palette.border),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(difficultyFilterProvider);
    final category = ref.watch(categoryFilterProvider);
    final completed = ref.watch(completionFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: AppStrings.all,
            selected: difficulty == null && category == null && !completed,
            onSelected: () {
              ref.read(difficultyFilterProvider.notifier).state = null;
              ref.read(categoryFilterProvider.notifier).state = null;
              ref.read(completionFilterProvider.notifier).state = false;
            },
          ),
          for (final item in QuestDifficulty.values)
            _FilterChip(
              label: item.label,
              selected: difficulty == item.label,
              onSelected: () {
                ref.read(difficultyFilterProvider.notifier).state =
                    difficulty == item.label ? null : item.label;
              },
            ),
          _FilterChip(
            label: AppStrings.completed,
            selected: completed,
            onSelected: () {
              ref.read(completionFilterProvider.notifier).state = !completed;
            },
          ),
          for (final item in QuestCategory.values)
            _FilterChip(
              label: item.label,
              selected: category == item.label,
              onSelected: () {
                ref.read(categoryFilterProvider.notifier).state =
                    category == item.label ? null : item.label;
              },
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: 180.ms,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.gold : context.palette.border,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? AppColors.onAccent
                    : context.palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [ShimmerCard(), ShimmerCard(), ShimmerCard()],
    );
  }
}
