/// Registro de sesiones de uso del editor (heartbeat).
abstract interface class UsageSessionRepository {
  /// Inicia una sesión y devuelve su id, o `null` sin usuario.
  Future<String?> start();

  /// Actualiza el último latido.
  Future<void> heartbeat(String sessionId);

  /// Cierra la sesión (deja el último latido).
  Future<void> end(String sessionId);
}
