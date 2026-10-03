import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------------------------------------------------------
// Background handler — MUST be a top-level function (not a class method).
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Do not touch BuildContext / Riverpod here.
  // Job: log / persist lightly. Navigation happens on click.
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ---------------------------------------------------------------------------
// Foreground listener + background-tapped handler
// ---------------------------------------------------------------------------

void listenForeground(void Function(String route) go) {
  // Foreground: the system shows NO banner automatically,
  // so display one manually via a local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = message.data['route'] ?? '/';

    // Android 13+ needs a notification channel; iOS needs presentation options.
    const androidDetails = AndroidNotificationDetails(
      'announcement', 'Campus Announcements',
      importance: Importance.high,
      priority: Priority.high,
    );

    // iOS/macOS — show alert + sound + badge while app is in foreground.
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Announcement',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: route,
    );
  });

  // Background -> tapped.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(message.data['route'] ?? '/');
  });
}

// ---------------------------------------------------------------------------
// Terminated -> opened from a notification
// ---------------------------------------------------------------------------

Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    go(initial.data['route'] ?? '/');
  }
  if (pendingDeepLink != null) {
    go(pendingDeepLink!);
  }
}

// ---------------------------------------------------------------------------
// Local notifications plugin (shared instance)
// ---------------------------------------------------------------------------

final _local = FlutterLocalNotificationsPlugin();

// ---------------------------------------------------------------------------
// Topic subscribe / unsubscribe
// ---------------------------------------------------------------------------

const topicName = 'campus-announcement';
const _subKey = 'topic_subscribed';
const _prefs = FlutterSecureStorage();

/// Returns `true` if the user is subscribed to the campus announcement topic.
/// Default is `true` because the app auto-subscribes on first launch.
Future<bool> isTopicSubscribed() async =>
    (await _prefs.read(key: _subKey)) != 'false';

Future<void> setTopicSubscribed(bool value) async {
  if (value) {
    await FirebaseMessaging.instance.subscribeToTopic(topicName);
  } else {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
  }
  await _prefs.write(key: _subKey, value: value.toString());
}

// ---------------------------------------------------------------------------
// Permission request
// ---------------------------------------------------------------------------

/// Requests notification permission.
/// On Android 13+ this triggers the runtime permission dialog.
/// On iOS this triggers the standard APNS permission sheet.
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

// ---------------------------------------------------------------------------
// Local-notification init (for foreground banner + tap handling)
// ---------------------------------------------------------------------------

Future<void> initLocalNotifications({
  required void Function(String route) onTap,
}) async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      final route = response.payload;
      if (route != null && route.isNotEmpty) onTap(route);
    },
  );
}

// ---------------------------------------------------------------------------
// FCM Token lifecycle
// ---------------------------------------------------------------------------

/// Sends the FCM device token to the backend via POST /devices.
/// Called on first launch and on every token refresh.
Future<void> sendTokenToBackend(Dio dio, String token) async {
  try {
    await dio.post('/devices', data: {
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
    debugPrint('[PushService] Token registered: ${token.substring(0, 12)}…');
  } catch (e) {
    // Non-fatal — the next token refresh will retry.
    debugPrint('[PushService] Failed to register token: $e');
  }
}

/// Gets the current FCM token, listens for refreshes, and auto-subscribes
/// to the campus-announcement topic if the user hasn't opted out.
Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await onToken(token);
  }

  // onTokenRefresh fires when FCM rotates the device token (e.g. app
  // restore, server-side invalidation). The new token MUST be sent to
  // the backend — otherwise the device becomes unreachable.
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  // Auto-subscribe to the default topic on first run.
  if (await isTopicSubscribed()) {
    await FirebaseMessaging.instance.subscribeToTopic(topicName);
  }
}

// ---------------------------------------------------------------------------
// Deep-link buffer (set by background handler, consumed after router ready)
// ---------------------------------------------------------------------------

String? pendingDeepLink;