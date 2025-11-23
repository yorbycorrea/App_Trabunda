import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class Credentials {
  Credentials(this.email, this.password);
  final String email;
  final String password;
}

abstract class AuthRepository {
  Future<void> login(Credentials credentials);
}

class MockAuthRepository extends Mock implements AuthRepository {}

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(Credentials credentials) {
    return _repository.login(credentials);
  }
}

void main() {
  group('LoginUseCase', () {
    late MockAuthRepository repository;
    late LoginUseCase useCase;

    setUp(() {
      repository = MockAuthRepository();
      useCase = LoginUseCase(repository);
    });

    test('delegates login to repository', () async {
      final credentials = Credentials('user@test.com', 'password');
      when(() => repository.login(credentials)).thenAnswer((_) async {});

      await useCase(credentials);

      verify(() => repository.login(credentials)).called(1);
    });
  });
}
