import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/post_entity.dart';
import '../domain/post_repository.dart';
import 'posts_remote_datasource.dart';

class PostsRepositoryImpl implements PostRepository {
  const PostsRepositoryImpl(this._remoteDataSource);

  final PostsRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<PostEntity>>> getPosts() async {
    try {
      final posts = await _remoteDataSource.getPosts();
      return Right(posts);
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
      if (error is Failure) {
        return Left(error);
      }
      return Left(mapDioFailure(error));
    }
  }
}
