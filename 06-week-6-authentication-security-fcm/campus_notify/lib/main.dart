import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';

import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import 'messaging/push_service.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Memicu redirect ulang saat status login berubah.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authStateProvider).value ?? false;
      final goingLogin = state.matchedLocation == Routes.login;

      if (!loggedIn && !goingLogin) return Routes.login;
      if (loggedIn && goingLogin) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: Routes.announcementById,
        builder: (_, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  registerBackgroundHandler(); // sebelum runApp

  await requestNotificationPermission();

  // Dio instance for backend calls (token registration).
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));

  await initFcmToken(
    onToken: (token) => sendTokenToBackend(dio, token),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Setelah frame pertama, router sudah siap dipakai untuk navigasi.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final router = ref.read(routerProvider);
      await initLocalNotifications(onTap: router.go);
      listenForeground(router.go);
      await handleTerminated(router.go);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}