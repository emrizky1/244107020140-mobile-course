import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/token_store.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';
import '../../data/api_client.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final loginProvider = Provider<Login>(
  (ref) => Login(ref.watch(authRepositoryProvider)),
);

final apiClientProvider = Provider(
  (ref) => buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  ),
);

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      final token = await ref.watch(tokenStoreProvider).readAccess();
      return token != null;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        error is Failure
            ? error
            : const LocalFailure('Sesi tidak dapat dibaca.'),
        stackTrace,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final session = await ref.read(loginProvider)(email, password);
      try {
        await ref
            .read(tokenStoreProvider)
            .save(access: session.access, refresh: session.refresh);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
          error is Failure
              ? error
              : const LocalFailure('Sesi gagal disimpan. Coba lagi.'),
          stackTrace,
        );
      }
      state = const AsyncData(true);
    } catch (error, stackTrace) {
      state = AsyncError(
        error is Failure
            ? error
            : const AuthFailure('Login gagal. Periksa data dan coba lagi.'),
        stackTrace,
      );
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(tokenStoreProvider).clear();
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      state = AsyncError(
        error is Failure
            ? error
            : const LocalFailure('Sesi gagal dihapus. Coba lagi.'),
        stackTrace,
      );
    }
  }
}
