import '../../../core/errors/failures.dart';
import 'profile_entity.dart';

abstract interface class ProfileRepository {
  /// Loads a public profile by DummyJSON user id.
  Future<Either<Failure, ProfileEntity>> getProfile(int userId);
}
