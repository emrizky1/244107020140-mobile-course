import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';
import '../providers/providers.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

/// Settings page content (used inside the bottom-nav scaffold).
class SettingsPageBody extends ConsumerWidget {
  const SettingsPageBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final isOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle app theme'),
            value: darkMode.value ?? false,
            onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Force Offline'),
            subtitle: const Text(
              'Simulate airplane mode – network calls are skipped',
            ),
            secondary: Icon(
              isOffline ? Icons.airplanemode_active : Icons.wifi,
            ),
            value: isOffline,
            onChanged: (v) =>
                ref.read(forceOfflineProvider.notifier).toggle(v),
          ),
        ],
      ),
    );
  }
}