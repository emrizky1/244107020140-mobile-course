sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class NotificationFailure extends Failure {
  const NotificationFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
