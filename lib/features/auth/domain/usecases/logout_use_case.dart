import '../repositories/auth_repository.dart';

/// Caso de uso para cerrar sesión.
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> execute() {
    return repository.signOut();
  }
}
