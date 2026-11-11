import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import 'auth_providers.dart';

/// Estado del formulario de nueva contraseña.
class UpdatePasswordController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  /// Cambia la contraseña de la sesión activa.
  Future<void> submit({required String password}) async {
    state = const AsyncLoading();

    final result = await ref
        .read(authRepositoryProvider)
        .updatePassword(newPassword: password);

    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

/// Controlador de la nueva contraseña.
final updatePasswordControllerProvider =
    AsyncNotifierProvider<UpdatePasswordController, bool>(
      UpdatePasswordController.new,
    );
