import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/utils/xp_calculator.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../auth/domain/user_entity.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../gamification/presentation/gamification_provider.dart';
import '../../quests/data/quest_repository_impl.dart';
import '../../quests/domain/quest_entity.dart';
import '../../quests/presentation/quest_provider.dart';
import 'achievement_card.dart';
import 'profile_provider.dart';
import 'stats_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final gamification = ref.watch(gamificationProvider);
    final completedCount = ref
        .watch(questsProvider)
        .quests
        .where((quest) => quest.isCompleted)
        .length;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = ref.watch(profileProvider(user.id));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.profile)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: profile.when(
                data: (loaded) => _HeroSection(
                  user: UserEntity(
                    id: loaded.id,
                    username: loaded.username,
                    email: loaded.email,
                    firstName: loaded.firstName,
                    lastName: loaded.lastName,
                    image: loaded.image,
                  ),
                  gamification: gamification,
                ),
                loading: () =>
                    _HeroSection(user: user, gamification: gamification),
                error: (_, _) =>
                    _HeroSection(user: user, gamification: gamification),
              ),
            ),
            TabBar(
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.gold,
              labelStyle: const TextStyle(
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                const Tab(text: 'STATS'),
                Tab(
                  child: Badge(
                    isLabelVisible: completedCount > 0,
                    label: Text('$completedCount'),
                    backgroundColor: AppColors.gold,
                    textColor: AppColors.background,
                    child: const Text('COMPLETED QUESTS'),
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _StatsTab(gamification: gamification),
                  const _CompletedQuestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.gamification});

  final GamificationState gamification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text('Stats', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        StatsWidget(gamification: gamification),
        const SizedBox(height: 24),
        Text('Achievements', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gamification.achievements.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return AchievementCard(
                achievement: gamification.achievements[index],
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        GradientButton(
          label: AppStrings.logoutAction,
          icon: Icons.logout_rounded,
          danger: true,
          onPressed: () async {
            await ref.read(authStateProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }
}

class _CompletedQuestsTab extends ConsumerWidget {
  const _CompletedQuestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questState = ref.watch(questsProvider);
    if (questState.status == QuestStatus.loading) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: const [ShimmerCard(), ShimmerCard(), ShimmerCard()],
      );
    }
    if (questState.status == QuestStatus.error) {
      return QuestErrorWidget(
        message: questState.message ?? 'Unable to load completed quests.',
        onRetry: () => ref.read(questsProvider.notifier).load(refresh: true),
      );
    }

    final completionTimes = _completionTimes(ref);
    final completed =
        questState.quests
            .where((quest) => quest.isCompleted)
            .toList(growable: false)
          ..sort((a, b) {
            final bTime =
                completionTimes[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
            final aTime =
                completionTimes[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

    if (completed.isEmpty) {
      return const _EmptyCompletedState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: completed.length,
      itemBuilder: (context, index) {
        final quest = completed[index];
        return _CompletedQuestTile(
          quest: quest,
        ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.2);
      },
    );
  }

  Map<int, DateTime> _completionTimes(WidgetRef ref) {
    final raw = ref
        .watch(sharedPreferencesProvider)
        .getString(QuestRepositoryImpl.completionTimesKey);
    if (raw == null || raw.isEmpty) {
      return <int, DateTime>{};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) {
      return MapEntry(
        int.tryParse(key) ?? -1,
        DateTime.tryParse(value.toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    })..remove(-1);
  }
}

class _CompletedQuestTile extends StatelessWidget {
  const _CompletedQuestTile({required this.quest});

  final QuestEntity quest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 88, color: AppColors.easy),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.easy,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _DifficultyBadge(difficulty: quest.difficulty),
                            Text(
                              '+${quest.xpReward} XP',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.gold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    final color = switch (difficulty) {
      QuestDifficulty.easy => AppColors.easy,
      QuestDifficulty.medium => AppColors.medium,
      QuestDifficulty.hard => AppColors.hard,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        difficulty.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _EmptyCompletedState extends StatelessWidget {
  const _EmptyCompletedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_outlined,
              color: AppColors.textSecondary,
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              'No completed quests yet',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a quest to add it to your heroic record.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.user, required this.gamification});

  final UserEntity user;
  final GamificationState gamification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
              boxShadow: [BoxShadow(color: AppColors.goldGlow, blurRadius: 24)],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.surfaceAlt,
              foregroundImage: user.image.isNotEmpty
                  ? CachedNetworkImageProvider(user.image)
                  : null,
              child: user.image.isNotEmpty
                  ? null
                  : const Icon(Icons.person_rounded, size: 42),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Level ${gamification.level} ${XpCalculator.titleForLevel(gamification.level)}',
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2400.ms, color: Colors.white54),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08);
  }
}
