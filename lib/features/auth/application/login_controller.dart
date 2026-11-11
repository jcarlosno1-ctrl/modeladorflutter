import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import '../application/auth_providers.dart';

/// Estado del formulario de login.
///
/// `false` = sin enviar / ya enviado con éxito; el error se expone vía
/// [AsyncError] para que la UI lo muestre sin duplicar estado.
class LoginController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  /// Envía las credenciales al repositorio.
  ///
  /// No relanza excepciones: cualquier fallo queda reflejado en [state].
  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();

    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);

    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

/// Controlador del formulario de login.
final loginControllerProvider =
    AsyncNotifierProvider<LoginController, bool>(LoginController.new);
