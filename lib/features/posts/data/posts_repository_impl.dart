import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/comment_entity.dart';
import '../domain/post_entity.dart';
import '../domain/post_repository.dart';
import 'post_model.dart';
import 'posts_local_datasource.dart';
import 'posts_remote_datasource.dart';

class PostsRepositoryImpl implements PostRepository {
  const PostsRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final PostsRemoteDataSource _remoteDataSource;
  final PostsLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, List<PostEntity>>> getPosts() async {
    try {
      final remote = await _remoteDataSource.getPosts();
      // User-created posts live only on-device; show them on top, and dedupe
      // by id so a post never appears twice.
      final userPosts = _localDataSource.getUserPosts();
      final seen = {for (final post in userPosts) post.id};
      final merged = <PostEntity>[
        ...userPosts,
        ...remote.where((post) => !seen.contains(post.id)),
      ];
      return Right(merged);
    } catch (error) {
      if (error is Failure) {
        return Left(error);
      }
      return Left(mapDioFailure(error));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> getPostDetail(int id) async {
    try {
      final post = await _remoteDataSource.getPostDetail(id);
      return Right(post);
    } catch (error) {
      if (error is Failure) return Left(error);
      return Left(mapDioFailure(error));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    try {
      // Still hit the real API so the integration is exercised, but ignore its
      // echoed id (JSONPlaceholder always returns 101). We mint our own unique,
      // collision-free id from the current timestamp and persist locally.
      await _remoteDataSource.createPost(
        title: title,
        body: body,
        userId: userId,
      );
      final localPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        title: title,
        body: body,
      );
      await _localDataSource.addUserPost(localPost);
      return Right(localPost);
    } catch (error) {
      if (error is Failure) return Left(error);
      return Left(mapDioFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<CommentEntity>>> getComments(int postId) async {
    try {
      final comments = await _remoteDataSource.getComments(postId);
      return Right(comments);
    } catch (error) {
      if (error is Failure) return Left(error);
      return Left(mapDioFailure(error));
    }
  }
}
