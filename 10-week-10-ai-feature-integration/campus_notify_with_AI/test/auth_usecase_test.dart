import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  String? receivedEmail;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    receivedEmail = email;
    return AuthSession(access: 'access', refresh: 'refresh');
  }

  @override
  Future<String> refresh(String refreshToken) async => 'renewed';
}

void main() {
  test('Login validates credentials before calling the repository', () async {
    final repository = FakeAuthRepository();
    final login = Login(repository);

    await expectLater(
      login('invalid-email', 'short'),
      throwsA(isA<AuthFailure>()),
    );
    expect(repository.receivedEmail, isNull);

    final session = await login('  student@example.edu  ', 'password123');
    expect(repository.receivedEmail, 'student@example.edu');
    expect(session.access, 'access');
  });
}
