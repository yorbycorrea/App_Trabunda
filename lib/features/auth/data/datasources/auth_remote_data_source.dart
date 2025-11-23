import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';

/// Fuente de datos remota basada en Supabase para autenticación.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _buildUserWithProfile(user);
  }

  Future<AppUser?> signIn({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    final user = res.user;
    if (user == null) return null;
    return _buildUserWithProfile(user);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<AppUser> buildUser(User user) => _buildUserWithProfile(user);

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
            displayNameFromProfile = (row['display_name'] as String).trim();
          }
          if (row['role'] is String) {
            role = (row['role'] as String).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando profile: $e');
    }

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
        default:
          break;
      }
    }

    final name = _extractName(user, displayNameFromProfile);

    debugPrint(
      'AuthRemoteDataSource -> usuario logueado: email=${user.email}, name=$name, role=$role',
    );

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: name,
      role: role,
    );
  }

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
}
