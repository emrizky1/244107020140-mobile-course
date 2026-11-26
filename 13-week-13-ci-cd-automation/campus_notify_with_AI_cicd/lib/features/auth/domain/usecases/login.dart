import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);
  final AuthRepository _repository;

  Future<AuthSession> call(String email, String password) async {
    if (!email.trim().contains('@') || password.length < 6) {
      throw const AuthFailure('Email atau password tidak valid.');
    }
    return _repository.login(email: email.trim(), password: password);
  }
}
