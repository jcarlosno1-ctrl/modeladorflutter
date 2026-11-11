import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/auth/presentation/reset_password_screen.dart';
import 'package:modeladorflutter/features/projects/application/project_providers.dart';
import 'package:modeladorflutter/features/projects/presentation/projects_screen.dart';
import 'package:modeladorflutter/main.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_project_repository.dart';

/// Monta la app con los repositorios falsos.
Future<void> _pumpApp(WidgetTester tester, FakeAuthRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        projectRepositoryProvider.overrideWithValue(FakeProjectRepository()),
      ],
      child: const ModeladorApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Escribe la nueva contraseña y confirma.
Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String password = 'nuevaClave123',
  String? confirm,
}) async {
  await tester.enterText(find.byKey(ResetPasswordKeys.password), password);
  await tester.enterText(find.byKey(ResetPasswordKeys.confirm), confirm ?? password);
  await tester.tap(find.byKey(ResetPasswordKeys.submit));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el enlace de recuperación pide la nueva contraseña', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _pumpApp(tester, repo);

    await repo.emitPasswordRecovery();
    await tester.pumpAndSettle();

    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.byType(ProjectsScreen), findsNothing);
  });

  testWidgets('guardar la contraseña cierra el modo recuperación', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _pumpApp(tester, repo);
    await repo.emitPasswordRecovery();
    await tester.pumpAndSettle();

    await _fillAndSubmit(tester);

    expect(repo.updatePasswordCalls, 1);
    expect(find.byType(ResetPasswordScreen), findsNothing);
    expect(find.byType(ProjectsScreen), findsOneWidget);
  });

  testWidgets('contraseñas distintas no llaman al backend', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _pumpApp(tester, repo);
    await repo.emitPasswordRecovery();
    await tester.pumpAndSettle();

    await _fillAndSubmit(tester, confirm: 'otraClave999');

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(repo.updatePasswordCalls, 0);
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
  });

  testWidgets('un fallo al guardar muestra el error y no cierra el modo', (
    tester,
  ) async {
    final repo = FakeAuthRepository(
      updatePasswordResult: const Err(
        AuthFailure('La contraseña no cumple los requisitos mínimos.'),
      ),
    );
    addTearDown(repo.dispose);
    await _pumpApp(tester, repo);
    await repo.emitPasswordRecovery();
    await tester.pumpAndSettle();

    await _fillAndSubmit(tester);

    expect(find.byKey(ResetPasswordKeys.error), findsOneWidget);
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.byType(ProjectsScreen), findsNothing);
  });
}
