import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/auth/presentation/forgot_password_screen.dart';
import 'package:modeladorflutter/features/auth/presentation/login_screen.dart';
import 'package:modeladorflutter/main.dart';

import '../../helpers/fake_auth_repository.dart';

/// Monta la app y navega al formulario de recuperación.
Future<void> _openForgot(
  WidgetTester tester,
  FakeAuthRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const ModeladorApp(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(LoginKeys.goToForgotPassword));
  await tester.pumpAndSettle();
  expect(find.byType(ForgotPasswordScreen), findsOneWidget);
}

void main() {
  testWidgets('el enlace se envía y el mensaje no revela si la cuenta existe', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _openForgot(tester, repo);

    await tester.enterText(
      find.byKey(ForgotPasswordKeys.email),
      'desconocido@example.com',
    );
    await tester.tap(find.byKey(ForgotPasswordKeys.submit));
    await tester.pumpAndSettle();

    expect(repo.resetCalls, 1);
    expect(find.byKey(ForgotPasswordKeys.success), findsOneWidget);
    expect(find.textContaining('Si el correo está registrado'), findsOneWidget);
  });

  testWidgets('un fallo de red muestra el error', (tester) async {
    final repo = FakeAuthRepository(
      resetResult: const Err(
        NetworkFailure('No hay conexión con el servidor. Intenta de nuevo.'),
      ),
    );
    addTearDown(repo.dispose);
    await _openForgot(tester, repo);

    await tester.enterText(
      find.byKey(ForgotPasswordKeys.email),
      'ana@example.com',
    );
    await tester.tap(find.byKey(ForgotPasswordKeys.submit));
    await tester.pumpAndSettle();

    expect(find.byKey(ForgotPasswordKeys.error), findsOneWidget);
    expect(find.byKey(ForgotPasswordKeys.success), findsNothing);
  });

  testWidgets('correo inválido no llama al backend', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _openForgot(tester, repo);

    await tester.enterText(find.byKey(ForgotPasswordKeys.email), 'no-es-correo');
    await tester.tap(find.byKey(ForgotPasswordKeys.submit));
    await tester.pumpAndSettle();

    expect(find.text('El correo no parece válido.'), findsOneWidget);
    expect(repo.resetCalls, 0);
  });
}
