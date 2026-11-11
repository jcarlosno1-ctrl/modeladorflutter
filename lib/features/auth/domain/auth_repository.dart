import 'package:modeladorflutter/core/result.dart';

import 'auth_signal.dart';
import 'auth_user.dart';

/// Contrato de autenticación.
///
/// El dominio (y la UI) dependen de esta interfaz, nunca de Supabase: eso
/// permite testear el login con un doble y cambiar de proveedor sin tocar la
/// capa de presentación.
abstract interface class AuthRepository {
  /// Emite el usuario actual y cada cambio de sesión.
  ///
  /// Debe emitir un primer valor (posiblemente `null`) al suscribirse y
  /// `null` tras cerrar sesión.
  Stream<SessionUser?> authStateChanges();

  /// Emite las señales de autenticación (incluida la recuperación).
  Stream<AuthSignal> authSignals();

  /// Usuario de la sesión persistida, si existe.
  Future<SessionUser?> currentUser();

  /// Inicia sesión con correo y contraseña.
  ///
  /// Devuelve [Err] con [AuthFailure] si las credenciales no son válidas, en
  /// lugar de lanzar excepciones.
  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  /// Cierra la sesión local y remota.
  Future<Result<void>> signOut();

  /// Registra una cuenta nueva.
  ///
  /// Devuelve [Ok] aunque el proyecto exija confirmar el correo: en ese caso
  /// no hay sesión y la UI debe pedirle al usuario que revise su bandeja.
  /// Un correo repetido se reporta como [AuthFailure].
  Future<Result<void>> signUp({
    required String email,
    required String password,
  });

  /// Solicita el correo de recuperación de contraseña.
  ///
  /// No revela si el correo existe (evita enumeración de cuentas): el éxito
  /// significa "enviamos el enlace si la cuenta existe".
  Future<Result<void>> requestPasswordReset({required String email});

  /// Cambia la contraseña de la sesión activa (flujo de recuperación).
  Future<Result<void>> updatePassword({required String newPassword});
}
