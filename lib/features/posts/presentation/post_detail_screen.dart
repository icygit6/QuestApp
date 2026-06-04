import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../favorites/presentation/favorites_provider.dart';
import '../domain/comment_entity.dart';
import '../domain/post_entity.dart';
import 'posts_provider.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({required this.postId, super.key, this.initialPost});

  final int postId;
  final PostEntity? initialPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = initialPost;
    if (post != null) {
      return _PostDetailBody(post: post);
    }

    final asyncPost = ref.watch(postDetailProvider(postId));
    return asyncPost.when(
      data: (loaded) => _PostDetailBody(post: loaded),
      loading: () => const _PostDetailLoading(),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: context.pop,
          ),
          title: const Text('Post'),
        ),
        body: QuestErrorWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(postDetailProvider(postId)),
        ),
      ),
    );
  }
}

class _PostDetailLoading extends StatelessWidget {
  const _PostDetailLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Post'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(18),
        child: LinearProgressIndicator(color: AppColors.gold),
      ),
    );
  }
}

class _PostDetailBody extends ConsumerWidget {
  const _PostDetailBody({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((state) => state.isPostFavorite(post.id)),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Post'),
        actions: [
          IconButton(
            tooltip: isFavorite
                ? 'Remove from favorites'
                : 'Save to favorites',
            icon: Icon(
              isFavorite
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isFavorite ? AppColors.gold : null,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).togglePost(post.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn().slideY(begin: 0.06),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_rounded, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(
                  'User ${post.userId}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.palette.border),
              ),
              child: Text(
                post.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'COMMENTS',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            _CommentsSection(postId: post.id),
          ],
        ),
      ),
    );
  }
}

/// Loads and renders the real comments for a post
/// (JSONPlaceholder `/posts/{id}/comments`).
class _CommentsSection extends ConsumerWidget {
  const _CommentsSection({required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(postCommentsProvider(postId));
    return comments.when(
      loading: () => const Column(
        children: [ShimmerCard(), ShimmerCard()],
      ),
      error: (error, _) => QuestErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(postCommentsProvider(postId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No comments yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i++)
              _CommentCard(comment: items[i])
                  .animate(delay: (i * 50).ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutCubic),
          ],
        );
      },
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final CommentEntity comment;

  @override
  Widget build(BuildContext context) {
    final initial = comment.name.isNotEmpty
        ? comment.name.characters.first.toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: context.palette.surfaceAlt,
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.gold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 14),
                    ),
                    Text(
                      comment.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
