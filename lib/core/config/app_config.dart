import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de entorno (Supabase).
///
/// Los valores viven en `.env` (ignorado por git). En CI se puede generar ese
/// archivo desde los secretos del pipeline o migrar a `--dart-define`.
abstract final class AppConfig {
  static const String _urlKey = 'SUPABASE_URL';
  static const String _publishableKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const String _redirectKey = 'AUTH_REDIRECT_URL';

  /// Carga `.env` y falla rápido si falta configuración.
  ///
  /// Un error de configuración debe verse al arrancar, no como un 401
  /// silencioso al intentar iniciar sesión.
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    if (supabaseUrl.isEmpty) {
      throw StateError('Falta SUPABASE_URL en .env');
    }
    if (supabasePublishableKey.isEmpty) {
      throw StateError('Falta SUPABASE_PUBLISHABLE_KEY en .env');
    }
  }

  /// URL del proyecto Supabase.
  static String get supabaseUrl => (dotenv.env[_urlKey] ?? '').trim();

  /// Clave pública (publishable/anon). **Nunca** la `service_role`.
  static String get supabasePublishableKey =>
      (dotenv.env[_publishableKey] ?? '').trim();

  /// URL a la que Supabase redirige tras confirmar el correo o restablecer la
  /// contraseña. Debe estar registrada en *Authentication → URL Configuration*.
  ///
  /// Vacía = se usa el Site URL del proyecto (comportamiento por defecto).
  static String get authRedirectUrl => (dotenv.env[_redirectKey] ?? '').trim();
}
