import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _token = 'loading...';
  bool? _subscribed; // null = masih loading

  @override
  void initState() {
    super.initState();
    _loadToken();
    isTopicSubscribed().then((v) {
      if (mounted) setState(() => _subscribed = v);
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(_setToken);
  }

  Future<void> _loadToken() async {
    _setToken(await FirebaseMessaging.instance.getToken());
  }

  void _setToken(String? t) {
    if (!mounted) return;
    setState(() => _token = t == null ? 'null' : '${t.substring(0, 12)}...');
  }

  Future<void> _toggle(bool value) async {
    await setTopicSubscribed(value);
    if (!mounted) return;
    setState(() => _subscribed = value);
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
          const Text('Debug',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText('FCM token: $_token'),
          const SizedBox(height: 24),

          // ===== Indikator status topic =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
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

          OutlinedButton(
            onPressed: () => context.push('/announcement/3'),
            child: const Text('Open /announcement/3 (manual test)'),
          ),
        ],
      ),
    );
  }
}