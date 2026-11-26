import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/data/token_store.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTokenStore extends TokenStore {
  @override
  Future<String?> readAccess() async => null;

  @override
  Future<String?> readRefresh() async => null;

  @override
  Future<void> save({required String access, required String refresh}) async {}

  @override
  Future<void> clear() async {}
}

class _ThrowingAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => throw Exception('raw backend detail');

  @override
  Future<String> refresh(String refreshToken) async => 'renewed';
}

void main() {
  test(
    'auth notifier converts raw repository exceptions to a Failure',
    () async {
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
          authRepositoryProvider.overrideWithValue(_ThrowingAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authStateProvider.notifier)
          .login('student@example.edu', 'password123');

      final error = container.read(authStateProvider).error;
      expect(error, isA<AuthFailure>());
      expect(
        (error! as Failure).message,
        'Login gagal. Periksa data dan coba lagi.',
      );
      expect(error.toString(), isNot(contains('raw backend detail')));
    },
  );
}
