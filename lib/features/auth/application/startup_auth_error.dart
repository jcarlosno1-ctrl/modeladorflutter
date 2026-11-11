import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Error detectado al abrir la app con un enlace de autenticación inválido.
///
/// Se inicializa desde `main()` con el resultado de `AuthLinkHandler.process`.
class StartupAuthError extends Notifier<String?> {
  /// Crea el controlador con el mensaje inicial (o `null`).
  StartupAuthError([this._initial]);

  final String? _initial;

  @override
  String? build() => _initial;

  /// Oculta el error (por ejemplo, al pedir un enlace nuevo).
  void clear() => state = null;
}

/// Mensaje de error de enlace, si lo hubo.
final startupAuthErrorProvider = NotifierProvider<StartupAuthError, String?>(
  StartupAuthError.new,
);
