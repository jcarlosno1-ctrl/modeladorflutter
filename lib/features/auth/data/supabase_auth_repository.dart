import 'package:modeladorflutter/core/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_signal.dart';
import '../domain/auth_user.dart';

/// Implementación de [AuthRepository] sobre Supabase Auth.
///
/// Traduce excepciones de Supabase a [Result]: la capa de arriba nunca ve
/// `AuthException` ni mensajes técnicos en inglés.
class SupabaseAuthRepository implements AuthRepository {
  /// Crea el repositorio sobre un cliente ya inicializado.
  ///
  /// [redirectUrl] es la URL a la que Supabase devuelve al usuario tras
  /// confirmar el correo o restablecer la contraseña. Si es `null` se usa el
  /// Site URL configurado en el proyecto.
  const SupabaseAuthRepository(this._client, {this.redirectUrl});

  final SupabaseClient _client;

  /// Destino de los enlaces enviados por correo.
  final String? redirectUrl;

  @override
  Stream<SessionUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.map(
      (state) => _toSessionUser(state.session?.user),
    );
  }

  @override
  Stream<AuthSignal> authSignals() {
    return _client.auth.onAuthStateChange.map(
      (state) => _toSignal(state.event),
    );
  }

  @override
  Future<SessionUser?> currentUser() async =>
      _toSessionUser(_client.auth.currentUser);

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session == null) {
        return const Err(
          AuthFailure('No se pudo iniciar sesión. Verifica tu correo.'),
        );
      }
      return const Ok(null);
    } on AuthException catch (error) {
      return Err(AuthFailure(_translate(error.message)));
    } on Exception {
      return const Err(
        NetworkFailure('No hay conexión con el servidor. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Ok(null);
    } on Exception {
      return const Err(
        NetworkFailure('No se pudo cerrar sesión. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: redirectUrl,
      );

      // Supabase, con "Confirm email" activo, responde *éxito falso* cuando el
      // correo ya existe (anti-enumeración): devuelve un usuario con
      // `identities` vacío y no envía correo. Lo detectamos para dar un
      // mensaje honesto. Contrapartida: esto permite enumerar correos, así que
      // hay que mantener los rate limits de Auth activos.
      final identities = response.user?.identities;
      if (identities != null && identities.isEmpty) {
        return const Err(
          AuthFailure(
            'Ese correo ya está registrado. Inicia sesión o recupera tu '
            'contraseña.',
          ),
        );
      }

      // Si el proyecto exige confirmar el correo, no habrá sesión; la UI
      // muestra el aviso correspondiente.
      return const Ok(null);
    } on AuthException catch (error) {
      return Err(AuthFailure(_translate(error.message)));
    } on Exception {
      return const Err(
        NetworkFailure('No hay conexión con el servidor. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectUrl,
      );
      return const Ok(null);
    } on AuthException {
      // No se confirma ni se niega si el correo existe (anti-enumeración).
      return const Ok(null);
    } on Exception {
      return const Err(
        NetworkFailure('No hay conexión con el servidor. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Result<void>> updatePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const Ok(null);
    } on AuthException catch (error) {
      return Err(AuthFailure(_translate(error.message)));
    } on Exception {
      return const Err(
        NetworkFailure('No hay conexión con el servidor. Intenta de nuevo.'),
      );
    }
  }

  /// Convierte el usuario de Supabase al modelo de dominio.
  static SessionUser? _toSessionUser(User? user) {
    if (user == null) {
      return null;
    }
    return SessionUser(id: user.id, email: user.email ?? '');
  }

  /// Traduce el evento de Supabase a la señal de dominio.
  static AuthSignal _toSignal(AuthChangeEvent event) => switch (event) {
    AuthChangeEvent.passwordRecovery => AuthSignal.passwordRecovery,
    AuthChangeEvent.signedIn => AuthSignal.signedIn,
    AuthChangeEvent.signedOut => AuthSignal.signedOut,
    _ => AuthSignal.other,
  };

  /// Mensajes de Supabase Auth → mensajes que sí le sirven al usuario.
  ///
  /// No se propaga el texto original porque filtra detalles internos y está
  /// en otro idioma.
  static String _translate(String raw) {
    final message = raw.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'Ese correo ya está registrado.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Credenciales inválidas.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirma tu correo antes de entrar.';
    }
    if (message.contains('password should be')) {
      return 'La contraseña no cumple los requisitos mínimos.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    return 'No se pudo completar la operación.';
  }
}
