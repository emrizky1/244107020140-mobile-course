import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/push_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    FirebaseMessaging? messaging,
    FlutterSecureStorage? storage,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _storage = storage ?? const FlutterSecureStorage();

  final FirebaseMessaging _messaging;
  final FlutterSecureStorage _storage;
  static const _subKey = 'topic_subscribed';

  @override
  Future<({String? token, Failure? failure})> currentToken() async {
    try {
      return (token: await _messaging.getToken(), failure: null);
    } catch (_) {
      return (
        token: null,
        failure: const NotificationFailure('Token notifikasi tidak tersedia.'),
      );
    }
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh.transform(
    StreamTransformer<String, String>.fromHandlers(
      handleError: (error, stackTrace, sink) => sink.addError(
        const NotificationFailure('Token notifikasi gagal diperbarui.'),
        stackTrace,
      ),
    ),
  );

  @override
  Future<({bool subscribed, Failure? failure})> isSubscribed() async {
    try {
      return (
        subscribed: (await _storage.read(key: _subKey)) != 'false',
        failure: null,
      );
    } catch (_) {
      return (
        subscribed: false,
        failure: const LocalFailure('Preferensi notifikasi gagal dibaca.'),
      );
    }
  }

  @override
  Future<Failure?> setSubscribed(bool value) async {
    try {
      if (value) {
        await _messaging.subscribeToTopic(topicName);
      } else {
        await _messaging.unsubscribeFromTopic(topicName);
      }
      await _storage.write(key: _subKey, value: value.toString());
      return null;
    } catch (_) {
      return const NotificationFailure(
        'Preferensi notifikasi gagal diperbarui.',
      );
    }
  }
}
