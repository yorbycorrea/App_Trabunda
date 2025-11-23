import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';

/// Controlador que coordina el estado de autenticación usando casos de uso.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _repository = repository,
        _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase {
    _init();
    _authSubscription = _repository.authStateChanges().listen(_handleAuthChange);
  }

  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  StreamSubscription<AuthState>? _authSubscription;

  AppUser? currentUser;

  Future<void> _init() async {
    currentUser = await _repository.getCurrentUser();
    notifyListeners();
  }

  Future<AppUser?> login(String email, String password) async {
    final user = await _loginUseCase.execute(email, password);
    currentUser = user;
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    await _logoutUseCase.execute();
    currentUser = null;
    notifyListeners();
  }

  Future<void> _handleAuthChange(AuthState event) async {
    final session = event.session;
    final user = session?.user;
    if (user != null) {
      currentUser = await _repository.buildUserFromSession(user);
    } else {
      currentUser = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// InheritedWidget para acceder al [AuthController].
class AuthScope extends InheritedWidget {
  final AuthController controller;

  const AuthScope({
    super.key,
    required this.controller,
    required super.child,
  });

  String? get currentUserId => controller.currentUser?.id;
  String? get currentUserName => controller.currentUser?.name;
  String? get currentUserRole => controller.currentUser?.role;

  static AuthController watch(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No se encontró AuthScope en el árbol de widgets');
    return scope!.controller;
  }

  static AuthController read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AuthScope>();
    assert(element != null, 'No se encontró AuthScope en el árbol de widgets');
    final scope = element!.widget as AuthScope;
    return scope.controller;
  }

  static AuthController of(BuildContext context) => watch(context);

  @override
  bool updateShouldNotify(AuthScope oldWidget) {
    return oldWidget.controller != controller;
  }
}
