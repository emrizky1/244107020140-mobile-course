import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/push_service.dart';
import '../../domain/repositories/notification_repository.dart';
import '../providers/notifications_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../routing/routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _token = 'loading...';
  bool? _subscribed; // null = masih loading
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final notifications = ref.read(notificationRepositoryProvider);
    _loadToken(notifications);
    notifications.isSubscribed().then((result) {
      if (!mounted) return;
      setState(() {
        _subscribed = result.failure == null ? result.subscribed : null;
        _errorMessage = result.failure?.message;
      });
    });
    notifications.tokenRefreshes.listen(
      _setToken,
      onError: (_) => _showError('Token notifikasi gagal diperbarui.'),
    );
  }

  Future<void> _loadToken(NotificationRepository notifications) async {
    final result = await notifications.currentToken();
    if (result.failure != null) {
      _showError(result.failure!.message);
    } else {
      _setToken(result.token);
    }
  }

  void _setToken(String? t) {
    if (!mounted) return;
    setState(() {
      _token = t == null
          ? 'null'
          : '${t.substring(0, t.length < 12 ? t.length : 12)}...';
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  Future<void> _toggle(bool value) async {
    final failure = await ref
        .read(notificationRepositoryProvider)
        .setSubscribed(value);
    if (!mounted) return;
    if (failure != null) {
      setState(() => _errorMessage = failure.message);
      return;
    }
    setState(() {
      _subscribed = value;
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? 'Subscribed' : 'Unsubscribed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSub = _subscribed == true;
    final color = _subscribed == null
        ? Colors.grey
        : isSub
        ? Colors.green
        : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Debug',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SelectableText('FCM token: $_token'),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),

          // ===== Indikator status topic =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _subscribed == null
                      ? Icons.hourglass_empty
                      : isSub
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Topic: $topicName'),
                      Text(
                        _subscribed == null
                            ? 'Checking...'
                            : isSub
                            ? 'SUBSCRIBED'
                            : 'UNSUBSCRIBED',
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _subscribed == false ? () => _toggle(true) : null,
                  child: const Text('Subscribe'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _subscribed == true ? () => _toggle(false) : null,
                  child: const Text('Unsubscribe'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () => context.push(Routes.notes),
            icon: const Icon(Icons.note_alt_outlined),
            label: const Text('Open Notes'),
          ),
          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () => context.push(Routes.announcement('3')),
            child: const Text('Open /announcement/3 (manual test)'),
          ),
        ],
      ),
    );
  }
}
