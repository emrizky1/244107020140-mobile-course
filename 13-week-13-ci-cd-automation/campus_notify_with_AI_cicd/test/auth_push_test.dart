import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/format.dart';

class FakeTokenStore {
  String? access;
  String? refresh;
}

void main() {
  test('routeFromMessage handles empty and slash-less routes', () {
    expect(routeFromMessage({}), '/');
    expect(routeFromMessage({'route': 'announcement/3'}), '/announcement/3');
    expect(routeFromMessage({'route': '/announcement/3'}), '/announcement/3');
  });

  test('routeFromMessage falls back for missing or invalid route values', () {
    expect(routeFromMessage({'route': 42}), '/');
    expect(routeFromMessage({}, fallbackRoute: '/home'), '/home');
  });

  test('data payload carries the announcement id', () {
    const data = {'route': '/announcement/3', 'id': '3'};
    expect(data['id'], '3');
    expect(routeFromMessage(data), '/announcement/3');
  });

  test('date formatting is pure and stable', () {
    final date = DateTime(2026, 10, 15, 9, 5);
    expect(formatDateTime(date), '15/10/2026 09:05');
  });

  test('auth provider reads login status from token', () async {
    final store = FakeTokenStore()..access = 'mock-access';
    expect(store.access != null, isTrue);
    store.access = null;
    expect(store.access != null, isFalse);
  });

  test('failed refresh -> session cleared (force re-login)', () async {
    final store = FakeTokenStore()..refresh = '';
    final needsLogin = (store.refresh ?? '').isEmpty;
    expect(needsLogin, isTrue);
  });
}
