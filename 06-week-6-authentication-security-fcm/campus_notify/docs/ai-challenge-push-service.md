# AI Challenge — PushService Documentation

## 1. AI Prompt (Original)

```
Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Generate a PushService with:
- requestPermission + getToken + onTokenRefresh (send to POST /devices)
- onMessage (show a local notification manually)
- onMessageOpenedApp + getInitialMessage (navigate to data.route)
- subscribe/unsubscribe topic campus-announcement
- top-level background handler with @pragma('vm:entry-point')
Mark which parts DIFFER for Android 13+ vs iOS,
and which parts must never touch BuildContext.
```

---

## 2. Initial AI Output (Before Manual Fixes)

The AI generated `lib/messaging/push_service.dart` with the following structure:

- ✅ Top-level `firebaseMessagingBackgroundHandler` with `@pragma('vm:entry-point')`
- ✅ `registerBackgroundHandler()` — calls `FirebaseMessaging.onBackgroundMessage`
- ✅ `listenForeground(go)` — `onMessage` + `onMessageOpenedApp`
- ✅ `handleTerminated(go)` — `getInitialMessage` + `pendingDeepLink`
- ✅ `requestNotificationPermission()` — asks for alert/badge/sound
- ✅ `initLocalNotifications(onTap:)` — sets up `FlutterLocalNotificationsPlugin`
- ✅ `initFcmToken(onToken:)` — `getToken` + `onTokenRefresh` + topic auto-subscribe
- ✅ `setTopicSubscribed(bool)` / `isTopicSubscribed()`
- ❌ `onTokenRefresh` callback only called `debugPrint` — did NOT post to backend
- ❌ Foreground `show()` lacked iOS `DarwinNotificationDetails`

---

## 3. Manual Fix List

| # | File | What was wrong | Fix applied |
|---|------|---------------|-------------|
| 1 | `push_service.dart` | `onTokenRefresh` callback only logged to console, never sent to backend | Added `sendTokenToBackend(Dio, String)` that POSTs `{ token, platform }` to `/devices` |
| 2 | `main.dart` | `onToken` callback was `debugPrint` + TODO comment | Replaced with `sendTokenToBackend(dio, token)` using a `Dio` instance |
| 3 | `push_service.dart` | Foreground `show()` only had `AndroidNotificationDetails` — no iOS banner | Added `DarwinNotificationDetails(presentAlert/Badge/Sound: true)` |
| 4 | `push_service.dart` | Mixed indentation (2-space vs 4-space) in `initFcmToken` | Fixed to consistent 2-space |
| 5 | `push_service.dart` | No import for `dart:io` (needed for `Platform.isIOS`) | Added `import 'dart:io' show Platform` |
| 6 | `push_service.dart` | No import for `package:dio/dio.dart` | Added import |
| 7 | `push_service.dart` | No import for `package:flutter/foundation.dart` (debugPrint) | Added import |

---

## 4. Three-State Test Table

Tests notification routing for all three app lifecycle states.

| # | State | How to trigger | Expected: tapped notification opens... | Data payload used | Result |
|---|-------|---------------|----------------------------------------|-------------------|--------|
| 1 | **Foreground** | App is open → send FCM with `data.route = /announcement/1` | Local banner appears (via `flutter_local_notifications`). Tapping it navigates to `/announcement/1` via `onDidReceiveNotificationResponse` → `onTap(route)` → `router.go('/announcement/1')` | `{ "route": "/announcement/1" }` | ⬜ Pass / ⬜ Fail |
| 2 | **Background** | App is in recents → send FCM with `data.route = /announcement/2` | System tray notification appears (auto by OS). Tapping it resumes app and navigates to `/announcement/2` via `onMessageOpenedApp` → `go(route)` | `{ "route": "/announcement/2" }` | ⬜ Pass / ⬜ Fail |
| 3 | **Terminated** | App killed → send FCM with `data.route = /announcement/3` | Tapping the system notification cold-starts the app. After init, `getInitialMessage()` returns the message and navigates to `/announcement/3` | `{ "route": "/announcement/3" }` | ⬜ Pass / ⬜ Fail |

### How to send test FCM:

```bash
# Using Firebase Console → Cloud Messaging → "Send test message"
# Or using curl with a server key:
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test Announcement",
      "body": "Testing route navigation"
    },
    "data": {
      "route": "/announcement/42"
    }
  }'
```

---

## 5. Android 13+ vs iOS — Platform Differences

| Aspect | Android 13+ (API 33+) | iOS |
|--------|----------------------|-----|
| **Permission** | Runtime `POST_NOTIFICATIONS` permission required (`AndroidManifest.xml` + `requestPermission()`) | APNS permission sheet via `requestPermission()` |
| **Foreground banner** | Must show manually via `flutter_local_notifications` — FCM only delivers to `onMessage`, no visible banner | Same — must show manually. Added `DarwinNotificationDetails(presentAlert/Badge/Sound: true)` |
| **Notification channel** | Required. Created via `AndroidNotificationDetails('announcement', 'Campus Announcements')` | Not applicable (no channels on iOS) |
| **Background handler** | `@pragma('vm:entry-point')` top-level function. Runs in isolate — **must not touch `BuildContext` or Riverpod** | Same restriction — top-level, no BuildContext |
| **Token type** | FCM token (GCM/FCM infrastructure) | APNS token mapped to FCM token by the SDK |
| **Topic subscribe** | Works directly via `subscribeToTopic()` | Same API, but requires APNS token to be available first |

---

## 6. Token Lifecycle (Demo Explanation)

1. **App Launch** → `FirebaseMessaging.instance.getToken()` retrieves the current FCM device token
2. **Token sent to backend** → `sendTokenToBackend(dio, token)` POSTs `{ token, platform }` to `POST /devices`
3. **Token rotation** → FCM may rotate the token at any time (app restore, server invalidation, etc.)
4. **`onTokenRefresh`** fires → the same `sendTokenToBackend()` is called again, ensuring the backend always has the latest token
5. **Why this matters**: If the old token is stale and the backend hasn't received the new one, push notifications silently fail — the device becomes unreachable
6. **Security**: Tokens are never logged in full (only first 12 chars), stored in `flutter_secure_storage` (encrypted), and transmitted over HTTPS

---

## 7. What Must Never Touch `BuildContext`

The **background message handler** (`firebaseMessagingBackgroundHandler`) runs in a separate Dart isolate on Android. It has:
- ❌ No access to `BuildContext`
- ❌ No access to Riverpod providers
- ❌ No access to `Navigator` or `GoRouter`
- ✅ Can do lightweight work: logging, writing to shared prefs, database inserts

Navigation from a background notification happens only when the user **taps** it, which triggers `onMessageOpenedApp` in the main isolate where `BuildContext` is available.
