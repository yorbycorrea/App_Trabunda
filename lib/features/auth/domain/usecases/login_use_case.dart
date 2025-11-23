import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión.
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AppUser?> execute(String email, String password) {
    return repository.signIn(email: email, password: password);
  }
}
