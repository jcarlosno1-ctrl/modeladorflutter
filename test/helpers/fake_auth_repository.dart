import 'dart:async';

import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/auth/domain/auth_repository.dart';
import 'package:modeladorflutter/features/auth/domain/auth_signal.dart';
import 'package:modeladorflutter/features/auth/domain/auth_user.dart';

/// Doble de pruebas de [AuthRepository].
///
/// Simula el comportamiento observable de Supabase (emite sesión al entrar,
/// `null` al salir) sin red ni credenciales.
class FakeAuthRepository implements AuthRepository {
  /// Crea el doble con los resultados deseados.
  FakeAuthRepository({
    this.signInResult = const Ok<void>(null),
    this.signUpResult = const Ok<void>(null),
    this.resetResult = const Ok<void>(null),
    this.updatePasswordResult = const Ok<void>(null),
  });

  /// Resultado que devolverá `signIn`.
  final Result<void> signInResult;

  /// Resultado que devolverá `signUp`.
  final Result<void> signUpResult;

  /// Resultado que devolverá `requestPasswordReset`.
  final Result<void> resetResult;

  /// Resultado que devolverá `updatePassword`.
  final Result<void> updatePasswordResult;

  final StreamController<SessionUser?> _controller =
      StreamController<SessionUser?>.broadcast();
  final StreamController<AuthSignal> _signalController =
      StreamController<AuthSignal>.broadcast();

  SessionUser? _user;

  /// Cuántas veces se intentó iniciar sesión (para validar la UI).
  int signInCalls = 0;

  /// Cuántas veces se intentó registrar (para validar la UI).
  int signUpCalls = 0;

  /// Cuántas veces se pidió recuperación de contraseña.
  int resetCalls = 0;

  /// Cuántas veces se cambió la contraseña.
  int updatePasswordCalls = 0;

  @override
  Stream<SessionUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Stream<AuthSignal> authSignals() => _signalController.stream;

  @override
  Future<SessionUser?> currentUser() async => _user;

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    final result = signInResult;
    if (result is Ok<void>) {
      _user = SessionUser(id: 'user-1', email: email.trim());
      _controller.add(_user);
    }
    return result;
  }

  @override
  Future<Result<void>> signOut() async {
    _user = null;
    _controller.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    return signUpResult;
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    resetCalls++;
    return resetResult;
  }

  @override
  Future<Result<void>> updatePassword({required String newPassword}) async {
    updatePasswordCalls++;
    return updatePasswordResult;
  }

  /// Simula abrir un enlace de recuperación: hay sesión y señal de recovery.
  Future<void> emitPasswordRecovery({String email = 'ana@example.com'}) async {
    _user = SessionUser(id: 'recovery-1', email: email);
    _controller.add(_user);
    _signalController.add(AuthSignal.passwordRecovery);
  }

  /// Libera los streams del doble.
  Future<void> dispose() async {
    await _controller.close();
    await _signalController.close();
  }
}
