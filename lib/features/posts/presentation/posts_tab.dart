import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../domain/post_entity.dart';
import 'posts_provider.dart';

class PostsTab extends ConsumerWidget {
  const PostsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postsProvider);
    final query = ref.watch(postsSearchProvider);
    final posts = ref.watch(filteredPostsProvider);

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () => ref.read(postsProvider.notifier).load(refresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: SearchBar(
                hintText: 'Search posts',
                leading: const Icon(
                  Icons.search_rounded,
                  color: AppColors.gold,
                ),
                onChanged: (value) =>
                    ref.read(postsSearchProvider.notifier).state = value,
                onSubmitted: (_) =>
                    ref.read(postsProvider.notifier).load(refresh: true),
                trailing: query.isEmpty
                    ? null
                    : [
                        IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            ref.read(postsSearchProvider.notifier).state = '';
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                backgroundColor: WidgetStatePropertyAll(
                  context.palette.surface,
                ),
                side: WidgetStatePropertyAll(
                  BorderSide(color: context.palette.border),
                ),
                elevation: const WidgetStatePropertyAll(0),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: AnimatedSwitcher(
                duration: 200.ms,
                child: state.status == PostsStatus.loading || state.isRefreshing
                    ? const LinearProgressIndicator(color: AppColors.gold)
                    : const SizedBox(height: 4),
              ),
            ),
          ),
          if (state.status == PostsStatus.error && state.posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: QuestErrorWidget(
                message: state.message ?? 'Failed to load posts.',
                onRetry: () =>
                    ref.read(postsProvider.notifier).load(refresh: true),
              ),
            )
          else if (state.status == PostsStatus.loaded && posts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: QuestEmptyWidget(
                title: 'No posts found',
                subtitle: 'Try a different search keyword.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = posts[index];
                  return _PostCard(
                    post: post,
                    index: index,
                    onTap: () =>
                        context.push('/explore/posts/${post.id}', extra: post),
                  );
                }, childCount: posts.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.index,
    required this.onTap,
  });

  final PostEntity post;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                post.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'User ${post.userId}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05);
  }
}
