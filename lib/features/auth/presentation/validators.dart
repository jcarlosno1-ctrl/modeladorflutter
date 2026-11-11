/// Validaciones de los formularios de autenticación.
///
/// Se comparten entre login, registro y recuperación para que el criterio sea
/// idéntico en todas las pantallas (y no se dupliquen expresiones regulares).
library;

/// Longitud mínima de contraseña que exige la UI.
///
/// Supabase admite 6; usamos 8 por defecto (más seguro) y documentamos que el
/// backend puede ser más estricto.
const int kMinPasswordLength = 8;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Valida un correo con forma razonable.
///
/// La validez definitiva la decide el backend; esto solo evita viajes inútiles.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Escribe tu correo.';
  }
  if (!_emailPattern.hasMatch(email)) {
    return 'El correo no parece válido.';
  }
  return null;
}

/// Valida que la contraseña tenga el mínimo aceptado.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Escribe tu contraseña.';
  }
  if (password.length < kMinPasswordLength) {
    return 'Mínimo $kMinPasswordLength caracteres.';
  }
  return null;
}
