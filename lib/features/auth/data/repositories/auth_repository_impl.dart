import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementación de [AuthRepository] usando Supabase.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AuthState> authStateChanges() => _remoteDataSource.authStateChanges();

  @override
  Future<AppUser> buildUserFromSession(User user) => _remoteDataSource.buildUser(user);

  @override
  Future<AppUser?> getCurrentUser() => _remoteDataSource.getCurrentUser();

  @override
  Future<AppUser?> signIn({required String email, required String password}) {
    return _remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() => _remoteDataSource.signOut();
}
