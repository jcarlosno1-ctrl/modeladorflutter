import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import 'auth_providers.dart';

/// Estado del formulario de recuperación de contraseña.
///
/// `true` = solicitud aceptada (no implica que la cuenta exista).
class ForgotPasswordController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  /// Pide el enlace de recuperación. No revela si el correo existe.
  Future<void> submit({required String email}) async {
    state = const AsyncLoading();

    final result = await ref
        .read(authRepositoryProvider)
        .requestPasswordReset(email: email);

    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

/// Controlador de la recuperación de contraseña.
final forgotPasswordControllerProvider =
    AsyncNotifierProvider<ForgotPasswordController, bool>(
      ForgotPasswordController.new,
    );
