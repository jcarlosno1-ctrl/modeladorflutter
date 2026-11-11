/// Usuario autenticado, en el vocabulario del dominio.
///
/// Es un espejo mínimo de `auth.users`: el dominio no debe conocer los tipos
/// de Supabase (`User`, `Session`).
class SessionUser {
  /// Crea un usuario de dominio.
  const SessionUser({required this.id, required this.email});

  /// Identificador estable (`auth.users.id`).
  final String id;

  /// Correo con el que se registró.
  final String email;

  @override
  bool operator ==(Object other) =>
      other is SessionUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);

  @override
  String toString() => 'SessionUser($id, $email)';
}
