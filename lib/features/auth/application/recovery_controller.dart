import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_signal.dart';
import 'auth_providers.dart';

/// Indica si el usuario llegó por un enlace de recuperación de contraseña.
///
/// Se mantiene aparte de la sesión porque Supabase, al abrir el enlace,
/// entrega una **sesión de recuperación**: sin esta bandera la app mostraría
/// los proyectos y el usuario no tendría dónde poner su contraseña nueva.
class RecoveryController extends Notifier<bool> {
  @override
  bool build() {
    final subscription = ref
        .watch(authRepositoryProvider)
        .authSignals()
        .listen((signal) {
          if (signal == AuthSignal.passwordRecovery) {
            state = true;
          }
        });

    ref.onDispose(subscription.cancel);
    return false;
  }

  /// Marca el flujo como terminado (contraseña actualizada).
  void finish() => state = false;
}

/// Modo recuperación activo.
final recoveryProvider = NotifierProvider<RecoveryController, bool>(
  RecoveryController.new,
);
