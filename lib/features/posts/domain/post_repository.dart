import '../../../core/errors/failures.dart';
import 'post_entity.dart';

abstract interface class PostRepository {
  Future<Either<Failure, List<PostEntity>>> getPosts();

  Future<Either<Failure, PostEntity>> getPostDetail(int id);
}
