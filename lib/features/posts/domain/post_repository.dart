import '../../../core/errors/failures.dart';
import 'comment_entity.dart';
import 'post_entity.dart';

abstract interface class PostRepository {
  Future<Either<Failure, List<PostEntity>>> getPosts();

  Future<Either<Failure, PostEntity>> getPostDetail(int id);

  Future<Either<Failure, PostEntity>> createPost({
    required String title,
    required String body,
    required int userId,
  });

  Future<Either<Failure, List<CommentEntity>>> getComments(int postId);
}
