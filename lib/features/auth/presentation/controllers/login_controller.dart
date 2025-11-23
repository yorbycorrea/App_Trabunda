import 'package:flutter/foundation.dart';

import '../../domain/entities/app_user.dart';
import 'auth_controller.dart';

/// Controlador de la pantalla de login.
class LoginController extends ChangeNotifier {
  LoginController(this._authController);

  final AuthController _authController;

  bool isLoading = false;
  String? errorMessage;

  Future<AppUser?> login(String email, String password) async {
    if (isLoading) return null;

    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      final user = await _authController.login(email, password);
      if (user == null) {
        errorMessage =
            'Credenciales incorrectas. Verifica tu correo y contraseña.';
      }
      return user;
    } catch (_) {
      errorMessage = 'No se pudo iniciar sesión. Intenta nuevamente.';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
