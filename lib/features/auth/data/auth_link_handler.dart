import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de procesar el enlace de autenticación con el que se abrió la app.
class AuthLinkResult {
  /// Crea el resultado.
  const AuthLinkResult({this.errorMessage});

  /// Mensaje para mostrar al usuario, o `null` si todo está en orden.
  final String? errorMessage;

  /// `true` cuando hubo un problema con el enlace.
  bool get hasError => errorMessage != null;
}

/// Procesa los parámetros que Supabase deja en la URL tras un correo.
///
/// Casos:
/// - `?error=...&error_code=otp_expired`: GoTrue rechazó el enlace (caducado o
///   ya usado). Se traduce a un mensaje accionable.
/// - `?token_hash=...&type=...`: confirmación por token hasheado. Se verifica
///   aquí, de modo que un antivirus o un escáner de correo que abra el enlace
///   **no** consume el token (solo lo consume la app al llamar `verifyOtp`).
abstract final class AuthLinkHandler {
  /// Procesa [uri] (por defecto la URL actual de la app).
  static Future<AuthLinkResult> process({Uri? uri}) async {
    final params = (uri ?? Uri.base).queryParameters;

    final errorCode = params['error_code'];
    if (errorCode != null) {
      return AuthLinkResult(errorMessage: messageFor(errorCode));
    }

    final tokenHash = params['token_hash'];
    final type = params['type'];
    if (tokenHash != null && tokenHash.isNotEmpty && type != null) {
      try {
        await Supabase.instance.client.auth.verifyOTP(
          tokenHash: tokenHash,
          type: otpTypeFor(type),
        );
        return const AuthLinkResult();
      } on AuthException {
        return const AuthLinkResult(
          errorMessage: 'El enlace ya no es válido. Solicita uno nuevo.',
        );
      }
    }

    return const AuthLinkResult();
  }

  /// Traduce el código de error de GoTrue a un mensaje para el usuario.
  static String messageFor(String errorCode) => switch (errorCode) {
    'otp_expired' =>
      'El enlace expiró o ya fue usado. Solicita uno nuevo desde '
          '"¿Olvidaste tu contraseña?" o registrándote otra vez.',
    'access_denied' =>
      'No pudimos validar el enlace. Solicita uno nuevo e inténtalo de nuevo.',
    _ => 'No pudimos validar el enlace. Solicita uno nuevo.',
  };

  /// Mapea el `type` del enlace al tipo de OTP de Supabase.
  static OtpType otpTypeFor(String type) => switch (type) {
    'recovery' => OtpType.recovery,
    'invite' => OtpType.invite,
    'magiclink' => OtpType.magiclink,
    'email_change' => OtpType.emailChange,
    _ => OtpType.signup,
  };
}
