/// Functional Either type used by repositories.
sealed class Either<L, R> {
  const Either();

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return switch (this) {
      Left<L, R>(:final value) => onLeft(value),
      Right<L, R>(:final value) => onRight(value),
    };
  }

  bool get isRight => this is Right<L, R>;
  bool get isLeft => this is Left<L, R>;
}

class Left<L, R> extends Either<L, R> {
  const Left(this.value);

  final L value;
}

class Right<L, R> extends Either<L, R> {
  const Right(this.value);

  final R value;
}

/// User-readable application failure.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request timed out.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'The realm server is unavailable.']);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Your session expired. Please login again.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'The requested quest could not be found.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Offline data is unavailable.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
