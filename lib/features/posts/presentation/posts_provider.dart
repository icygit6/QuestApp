import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/providers.dart';
import '../data/posts_local_datasource.dart';
import '../data/posts_remote_datasource.dart';
import '../data/posts_repository_impl.dart';
import '../domain/comment_entity.dart';
import '../domain/post_entity.dart';
import '../domain/post_repository.dart';

final postsRemoteDataSourceProvider = Provider<PostsRemoteDataSource>(
  (ref) => PostsRemoteDataSource(ref.watch(dioClientProvider)),
);

final userPostsBoxProvider = Provider<Box<String>>(
  (ref) => Hive.box<String>('user_posts'),
);

final postsLocalDataSourceProvider = Provider<PostsLocalDataSource>(
  (ref) => PostsLocalDataSource(ref.watch(userPostsBoxProvider)),
);

final postsRepositoryProvider = Provider<PostRepository>(
  (ref) => PostsRepositoryImpl(
    ref.watch(postsRemoteDataSourceProvider),
    ref.watch(postsLocalDataSourceProvider),
  ),
);

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>(
  (ref) =>
      PostsNotifier(repository: ref.watch(postsRepositoryProvider))..load(),
);

final postsSearchProvider = StateProvider<String>((ref) => '');

final filteredPostsProvider = Provider<List<PostEntity>>((ref) {
  final query = ref.watch(postsSearchProvider).trim().toLowerCase();
  final posts = ref.watch(postsProvider).posts;
  if (query.isEmpty) {
    return posts;
  }
  return posts
      .where(
        (post) =>
            post.title.toLowerCase().contains(query) ||
            post.body.toLowerCase().contains(query),
      )
      .toList(growable: false);
});

final postDetailProvider = FutureProvider.family<PostEntity, int>((
  ref,
  id,
) async {
  final result = await ref.watch(postsRepositoryProvider).getPostDetail(id);
  return result.fold((failure) => throw failure.message, (post) => post);
});

final postCommentsProvider =
    FutureProvider.family<List<CommentEntity>, int>((ref, postId) async {
      final result = await ref
          .watch(postsRepositoryProvider)
          .getComments(postId);
      return result.fold((failure) => throw failure.message, (comments) => comments);
    });

enum PostsStatus { loading, loaded, error }

class PostsState {
  const PostsState({
    required this.status,
    required this.posts,
    required this.isRefreshing,
    this.message,
  });

  factory PostsState.initial() {
    return const PostsState(
      status: PostsStatus.loading,
      posts: <PostEntity>[],
      isRefreshing: false,
    );
  }

  final PostsStatus status;
  final List<PostEntity> posts;
  final bool isRefreshing;
  final String? message;

  PostsState copyWith({
    PostsStatus? status,
    List<PostEntity>? posts,
    bool? isRefreshing,
    String? message,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: message,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  PostsNotifier({required PostRepository repository})
    : _repository = repository,
      super(PostsState.initial());

  final PostRepository _repository;

  /// Creates a new post. Returns an error message on failure, null on success.
  Future<String?> create({
    required String title,
    required String body,
    required int userId,
  }) async {
    final result = await _repository.createPost(
      title: title,
      body: body,
      userId: userId,
    );
    return result.fold(
      (failure) => failure.message,
      (post) {
        state = state.copyWith(posts: [post, ...state.posts]);
        return null;
      },
    );
  }

  Future<void> load({bool refresh = false}) async {
    if (refresh && state.posts.isNotEmpty) {
      state = state.copyWith(isRefreshing: true, message: null);
    } else {
      state = state.copyWith(
        status: PostsStatus.loading,
        posts: refresh ? <PostEntity>[] : state.posts,
        isRefreshing: false,
        message: null,
      );
    }

    final result = await _repository.getPosts();
    state = result.fold(
      (failure) => state.copyWith(
        status: PostsStatus.error,
        message: failure.message,
        isRefreshing: false,
      ),
      (posts) => state.copyWith(
        status: PostsStatus.loaded,
        posts: posts,
        isRefreshing: false,
      ),
    );
  }
}
