import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../domain/leaderboard_entity.dart';
import 'leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _scrollController = ScrollController();
  int? _lastAutoScrolledRank;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(filteredLeaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.rankings)),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => ref.refresh(leaderboardProvider.future),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            SearchBar(
              hintText: 'Search heroes',
              leading: const Icon(Icons.search_rounded, color: AppColors.gold),
              onChanged: (value) =>
                  ref.read(leaderboardSearchProvider.notifier).state = value,
              backgroundColor: WidgetStatePropertyAll(context.palette.surface),
              side: WidgetStatePropertyAll(
                BorderSide(color: context.palette.border),
              ),
              elevation: const WidgetStatePropertyAll(0),
            ),
            const SizedBox(height: 18),
            entries.when(
              loading: () => const _LeaderboardLoading(),
              error: (error, _) => SizedBox(
                height: 460,
                child: QuestErrorWidget(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(leaderboardProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox(
                    height: 460,
                    child: Center(child: Text('No ranked heroes found.')),
                  );
                }
                _scheduleCurrentUserScroll(items);
                final top = items.take(3).toList(growable: false);
                final rest = items.skip(3).toList(growable: false);
                return Column(
                  children: [
                    _Podium(entries: top),
                    const SizedBox(height: 18),
                    for (final entry in rest)
                      _LeaderboardRow(
                        entry: entry,
                        highlighted: entry.isCurrentUser,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleCurrentUserScroll(List<LeaderboardEntry> items) {
    final index = items.indexWhere((entry) => entry.isCurrentUser);
    if (index < 0) {
      return;
    }
    final rank = items[index].rank;
    if (_lastAutoScrolledRank == rank) {
      return;
    }
    _lastAutoScrolledRank = rank;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final offset = index <= 2 ? 0.0 : 338.0 + ((index - 3) * 82.0);
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: 500.ms,
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ordered = <LeaderboardEntry?>[
      entries.length > 1 ? entries[1] : null,
      entries.isNotEmpty ? entries[0] : null,
      entries.length > 2 ? entries[2] : null,
    ];
    return SizedBox(
      height: 246,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < ordered.length; i++)
            Expanded(
              child: ordered[i] == null
                  ? const SizedBox.shrink()
                  : _PodiumSpot(
                      entry: ordered[i]!,
                      height: i == 1 ? 220 : 184,
                    ).animate(delay: (i * 110).ms).fadeIn().slideY(begin: 0.2),
            ),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({required this.entry, required this.height});

  final LeaderboardEntry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.rank) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      _ => AppColors.bronze,
    };
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.gold.withValues(alpha: 0.15)
            : context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 190;
          final avatarRadius = compact ? 22.0 : 28.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                    Icons.workspace_premium_rounded,
                    color: color,
                    size: compact ? 20 : 24,
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1800.ms, color: color),
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: context.palette.surfaceAlt,
                foregroundImage: entry.avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(entry.avatarUrl)
                    : null,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '#${entry.rank}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontSize: compact ? 19 : 22,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.isCurrentUser
                        ? '${entry.username} (You)'
                        : entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${entry.xp} XP',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.highlighted});

  final LeaderboardEntry entry;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.gold.withValues(alpha: 0.15)
            : context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppColors.gold : context.palette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 72,
            color: highlighted ? AppColors.gold : Colors.transparent,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 34,
            child: Text(
              '#${entry.rank}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          CircleAvatar(
            backgroundColor: context.palette.surfaceAlt,
            foregroundImage: entry.avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(entry.avatarUrl)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  highlighted ? '${entry.username} (You)' : entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${entry.xp} XP',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardLoading extends StatelessWidget {
  const _LeaderboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [ShimmerCard(), ShimmerCard(), ShimmerCard(), ShimmerCard()],
    );
  }
}
