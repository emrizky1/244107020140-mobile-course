import '../../../../core/failures.dart';

abstract interface class NotificationRepository {
  Future<({String? token, Failure? failure})> currentToken();
  Stream<String> get tokenRefreshes;
  Future<({bool subscribed, Failure? failure})> isSubscribed();
  Future<Failure?> setSubscribed(bool value);
}
