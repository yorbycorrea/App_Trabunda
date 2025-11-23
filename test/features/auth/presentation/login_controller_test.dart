import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

enum LoginStatus { idle, loading, success, error }

abstract class AuthController {
  Future<bool> login(String email, String password);
}

class MockAuthController extends Mock implements AuthController {}

class LoginController extends ChangeNotifier {
  LoginController(this._authController);

  final AuthController _authController;
  LoginStatus status = LoginStatus.idle;

  Future<void> login(String email, String password) async {
    status = LoginStatus.loading;
    notifyListeners();
    try {
      final result = await _authController.login(email, password);
      status = result ? LoginStatus.success : LoginStatus.error;
    } catch (_) {
      status = LoginStatus.error;
    }
    notifyListeners();
  }
}

void main() {
  group('LoginController', () {
    late MockAuthController authController;
    late LoginController loginController;

    setUp(() {
      authController = MockAuthController();
      loginController = LoginController(authController);
    });

    test('emits loading then success when login succeeds', () async {
      when(() => authController.login('user@test.com', 'pass'))
          .thenAnswer((_) async => true);

      final statusChanges = <LoginStatus>[];
      loginController.addListener(() => statusChanges.add(loginController.status));

      await loginController.login('user@test.com', 'pass');

      expect(statusChanges, containsAllInOrder([LoginStatus.loading, LoginStatus.success]));
    });

    test('emits loading then error when login fails', () async {
      when(() => authController.login('user@test.com', 'wrong'))
          .thenAnswer((_) async => false);

      final statusChanges = <LoginStatus>[];
      loginController.addListener(() => statusChanges.add(loginController.status));

      await loginController.login('user@test.com', 'wrong');

      expect(statusChanges, containsAllInOrder([LoginStatus.loading, LoginStatus.error]));
    });
  });
}
