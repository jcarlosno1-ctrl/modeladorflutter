/// Resultado explícito de una operación que puede fallar.
///
/// El dominio no lanza excepciones: devuelve [Ok] o [Err] para que el
/// llamador esté obligado a decidir qué hacer (patrón Either).
sealed class Result<T> {
  const Result();

  /// `true` cuando la operación terminó bien.
  bool get isOk => this is Ok<T>;

  /// `true` cuando la operación falló.
  bool get isErr => this is Err<T>;
}

/// Éxito con valor.
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

/// Fallo con su causa tipada.
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

/// Causa tipada de un fallo.
///
/// Las subclases acotan el universo de errores que la UI debe traducir; así
/// nunca se muestra un mensaje técnico crudo al usuario.
sealed class Failure {
  const Failure(this.message);

  /// Mensaje apto para mostrar al usuario (nunca incluye tokens ni SQL).
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// Credenciales inválidas, cuenta sin confirmar o sesión expirada.
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Falta configuración (URL/clave) o es inválida.
final class ConfigFailure extends Failure {
  const ConfigFailure(super.message);
}

/// Red caída, timeout o respuesta inesperada del backend.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Cualquier caso no contemplado.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
