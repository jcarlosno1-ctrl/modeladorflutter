import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/auth/presentation/login_screen.dart';
import 'package:modeladorflutter/features/auth/presentation/signup_screen.dart';
import 'package:modeladorflutter/main.dart';

import '../../helpers/fake_auth_repository.dart';

/// Monta la app y navega desde el login al registro.
Future<void> _openSignUp(WidgetTester tester, FakeAuthRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const ModeladorApp(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(LoginKeys.goToSignUp));
  await tester.pumpAndSettle();
  expect(find.byType(SignUpScreen), findsOneWidget);
}

/// Rellena el formulario de registro.
Future<void> _fillSignUp(
  WidgetTester tester, {
  String email = 'nuevo@example.com',
  String password = 'secreta123',
  String? confirm,
}) async {
  await tester.enterText(find.byKey(SignUpKeys.email), email);
  await tester.enterText(find.byKey(SignUpKeys.password), password);
  await tester.enterText(find.byKey(SignUpKeys.confirm), confirm ?? password);
}

void main() {
  testWidgets('registro válido pide confirmar el correo', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _openSignUp(tester, repo);

    await _fillSignUp(tester);
    await tester.tap(find.byKey(SignUpKeys.submit));
    await tester.pumpAndSettle();

    expect(repo.signUpCalls, 1);
    expect(find.byKey(SignUpKeys.success), findsOneWidget);
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.byKey(SignUpKeys.error), findsNothing);
  });

  testWidgets('contraseñas distintas no llaman al backend', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _openSignUp(tester, repo);

    await _fillSignUp(tester, confirm: 'otraClave99');
    await tester.tap(find.byKey(SignUpKeys.submit));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(repo.signUpCalls, 0);
    expect(find.byKey(SignUpKeys.success), findsNothing);
  });

  testWidgets('correo ya registrado muestra el error', (tester) async {
    final repo = FakeAuthRepository(
      signUpResult: const Err(AuthFailure('Ese correo ya está registrado.')),
    );
    addTearDown(repo.dispose);
    await _openSignUp(tester, repo);

    await _fillSignUp(tester);
    await tester.tap(find.byKey(SignUpKeys.submit));
    await tester.pumpAndSettle();

    expect(find.byKey(SignUpKeys.error), findsOneWidget);
    expect(find.text('Ese correo ya está registrado.'), findsOneWidget);
    expect(find.byKey(SignUpKeys.success), findsNothing);
  });

  testWidgets('desde el formulario se puede volver al login', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _openSignUp(tester, repo);

    await tester.tap(find.byKey(SignUpKeys.goToLogin));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);
  });

  testWidgets('desde el registro se puede volver al login', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _openSignUp(tester, repo);

    await _fillSignUp(tester);
    await tester.tap(find.byKey(SignUpKeys.submit));
    await tester.pumpAndSettle();
    expect(find.byKey(SignUpKeys.success), findsOneWidget);

    await tester.tap(find.byKey(SignUpKeys.back));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);
  });
}
