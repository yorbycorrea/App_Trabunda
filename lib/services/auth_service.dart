import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de usuario para la app
class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // admin, planillero, saneamiento, operador, etc.

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isPlanillero => role == 'planillero';
  bool get isSupervisorSaneamiento => role == 'saneamiento';

  @override
  String toString() =>
      'AppUser(id: $id, email: $email, name: $name, role: $role)';
}

class AuthService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  AppUser? currentUser;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      currentUser = await _buildUserWithProfile(user);
      notifyListeners();
    }

    _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final user = session?.user;
      if (user != null) {
        currentUser = await _buildUserWithProfile(user);
      } else {
        currentUser = null;
      }
      notifyListeners();
    });
  }

  /// Construye AppUser intentando leer `profiles`.
  /// Si no puede, usa un fallback por email.
  Future<AppUser> _buildUserWithProfile(User user) async {
    String? displayNameFromProfile;
    String role = 'planillero';

    try {
      final data = await _client
          .from('profiles')
          .select('id, display_name, role')
          .eq('id', user.id);

      debugPrint('profiles data for ${user.id}: $data');

      if (data is List && data.isNotEmpty) {
        final row = data.first;
        if (row is Map) {
          if (row['display_name'] is String) {
            displayNameFromProfile =
                (row['display_name'] as String).trim();
          }
          if (row['role'] is String) {
            role = (row['role'] as String).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando profile: $e');
    }

    // ========= Fallback por email =========
    // Si no pudo leer role/display_name desde la tabla,
    // definimos manualmente algunos usuarios clave.
    if ((displayNameFromProfile == null || displayNameFromProfile.isEmpty) &&
        (role == 'planillero' || role.isEmpty)) {
      switch (user.email) {
        case 'admin@trabunda.com':
          displayNameFromProfile = 'Admin';
          role = 'admin';
          break;
        case 'curay@trabunda.com':
          displayNameFromProfile = 'Curay Floriano Luis Martin';
          role = 'saneamiento';
          break;
      // aquí puedes ir agregando más usuarios:
      // case 'ivan@trabunda.com':
      //   displayNameFromProfile = 'Iván';
      //   role = 'planillero';
      //   break;
        default:
        // se queda con planillero y nombre por correo
          break;
      }
    }

    final name = _extractName(user, displayNameFromProfile);

    debugPrint(
      'AuthService -> usuario logueado: email=${user.email}, name=$name, role=$role',
    );

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: name,
      role: role,
    );
  }

  /// 1) display_name de profiles o fallback
  /// 2) metadata["name"]
  /// 3) parte antes de @ en el email
  /// 4) "Usuario"
  String _extractName(User user, String? displayName) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final meta = user.userMetadata ?? {};
    final metaName = meta['name'];
    if (metaName is String && metaName.trim().isNotEmpty) {
      return metaName.trim();
    }

    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }

    return 'Usuario';
  }

  // --------- Métodos de auth ----------

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user != null) {
      currentUser = await _buildUserWithProfile(user);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    currentUser = null;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
    final user = res.user;
    if (user != null) {
      currentUser = await _buildUserWithProfile(user);
      notifyListeners();
    }
  }

  // --------- Alias para tu código viejo ----------

  Future<bool> login(String email, String password) async {
    await signIn(email: email, password: password);
    return currentUser != null;
  }

  Future<void> logout() => signOut();
}

/// InheritedWidget para acceder al AuthService
class AuthScope extends InheritedWidget {
  final AuthService service;

  const AuthScope({
    super.key,
    required this.service,
    required super.child,
  });

  static AuthService watch(BuildContext context) {
    final scope =
    context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No se encontró AuthScope en el árbol de widgets');
    return scope!.service;
  }

  static AuthService read(BuildContext context) {
    final element =
    context.getElementForInheritedWidgetOfExactType<AuthScope>();
    assert(element != null, 'No se encontró AuthScope en el árbol de widgets');
    final scope = element!.widget as AuthScope;
    return scope.service;
  }

  static AuthService of(BuildContext context) => watch(context);

  @override
  bool updateShouldNotify(AuthScope oldWidget) {
    return oldWidget.service != service;
  }
}
