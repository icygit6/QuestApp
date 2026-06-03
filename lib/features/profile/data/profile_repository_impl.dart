import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/profile_entity.dart';
import '../domain/profile_repository.dart';
import 'profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile(int userId) async {
    try {
      return Right(await _remoteDataSource.getProfile(userId));
    } catch (error) {
      return Left(mapDioFailure(error));
    }
  }
}
