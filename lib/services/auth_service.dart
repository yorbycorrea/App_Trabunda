import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Simple user model to keep track of application roles and credentials.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // 'admin' | 'planillero'

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isPlanillero => role == 'planillero';
  bool get isSupervisorSaneamiento =>
      role == 'Supervisor de Saneamiento';
}

/// In-memory authentication service with a fixed catalogue of users.
class AuthService extends ChangeNotifier {
  AuthService();

  final List<AppUser> _users = const [
    AppUser(
      id: 'programador',
      name: 'Programador',
      email: 'programador@trabunda.com',
      password: 'programador123',
      role: 'admin',
    ),
    AppUser(
      id: 'gerente',
      name: 'Gerente Rony',
      email: 'gerente@trabunda.com',
      password: 'gerente123',
      role: 'admin',
    ),
    AppUser(
      id: 'planillero1',
      name: 'Vera Gennell Ivan',
      email: 'ivan@trabunda.com',
      password: 'ivan123456',
      role: 'planillero',
    ),
    AppUser(
      id: 'planillero2',
      name: 'Macalupu Timana Raquel',
      email: 'raquel@trabunda.com',
      password: 'raquel123456',
      role: 'planillero',
    ),
    AppUser(
      id: 'planillero3',
      name: 'Curay Floriano Luis Martin',
      email: 'curay@trabunda.com',
      password: 'curay123456',
      role: 'Supervisor de Saneamiento',
    ),
    AppUser(
      id: 'planillero4',
      name: 'Planillero Cuatro',
      email: 'planillero4@trabunda.com',
      password: 'planillero4',
      role: 'Supervisor de Saneamiento',
    ),
  ];

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get users => List.unmodifiable(_users);

  Future<bool> login(String email, String password) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    AppUser? matched;
    for (final user in _users) {
      if (user.email.toLowerCase() == trimmedEmail &&
          user.password == trimmedPassword) {
        matched = user;
        break;
      }
    }

    if (matched == null) {
      return false;
    }

    _currentUser = matched;
    notifyListeners();
    return true;
  }

  void logout() {
    if (_currentUser == null) return;
    _currentUser = null;
    notifyListeners();
  }
}

/// Lightweight inherited notifier to expose [AuthService] without packages.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService service,
    required super.child,
  }) : super(notifier: service);

  static AuthService watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found in context');
    return scope!.notifier!;
  }

  static AuthService read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AuthScope>()?.widget;
    assert(element is AuthScope, 'No AuthScope found in context');
    return (element as AuthScope).notifier!;
  }

  @override
  bool updateShouldNotify(covariant AuthScope oldWidget) {
    return notifier != oldWidget.notifier;
  }
}
