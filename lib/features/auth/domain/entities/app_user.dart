/// Usuario autenticado dentro de la aplicación.
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
  String toString() => 'AppUser(id: $id, email: $email, name: $name, role: $role)';
}
