import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/app_user.dart';

/// Contrato para orígenes de datos de autenticación.
abstract class AuthRepository {
  Future<AppUser?> signIn({required String email, required String password});
  Future<void> signOut();
  Future<AppUser?> getCurrentUser();
  Stream<AuthState> authStateChanges();
  Future<AppUser> buildUserFromSession(User user);
}
