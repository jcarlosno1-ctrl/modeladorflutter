import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import 'auth_providers.dart';

/// Estado del formulario de registro.
///
/// `true` = cuenta creada (posiblemente pendiente de confirmar por correo).
class SignUpController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  /// Crea la cuenta. No relanza excepciones: todo fallo queda en [state].
  Future<void> submit({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(authRepositoryProvider)
        .signUp(email: email, password: password);

    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

/// Controlador del registro.
final signUpControllerProvider =
    AsyncNotifierProvider<SignUpController, bool>(SignUpController.new);
