/// Señales de autenticación relevantes para la UI.
///
/// Se modelan en el dominio para no exponer `AuthChangeEvent` de Supabase en
/// la capa de presentación.
enum AuthSignal {
  /// El usuario inició sesión (o se restauró una sesión persistida).
  signedIn,

  /// El usuario cerró sesión.
  signedOut,

  /// El usuario abrió un enlace de recuperación de contraseña.
  passwordRecovery,

  /// Cualquier otro evento (refresh de token, etc.).
  other,
}
