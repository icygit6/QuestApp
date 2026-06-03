import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_state_widget.dart';
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

class _PostDetailBody extends StatelessWidget {
  const _PostDetailBody({required this.post});

  final PostEntity post;

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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Text(
                post.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
