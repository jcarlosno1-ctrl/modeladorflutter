import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/auth/presentation/login_screen.dart';
import 'package:modeladorflutter/features/projects/application/project_providers.dart';
import 'package:modeladorflutter/features/projects/presentation/projects_screen.dart';
import 'package:modeladorflutter/main.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_project_repository.dart';

/// Monta la app completa con los repositorios falsos inyectados.
Future<void> _pumpApp(WidgetTester tester, FakeAuthRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        // Sin esto, al llegar a Proyectos se instanciaría el repositorio real.
        projectRepositoryProvider.overrideWithValue(FakeProjectRepository()),
      ],
      child: const ModeladorApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Rellena el formulario y pulsa "Entrar".
Future<void> _submitCredentials(
  WidgetTester tester, {
  String email = 'ana@example.com',
  String password = 'secreta123',
}) async {
  await tester.enterText(find.byKey(LoginKeys.email), email);
  await tester.enterText(find.byKey(LoginKeys.password), password);
  await tester.tap(find.byKey(LoginKeys.submit));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('credenciales válidas llevan a la pantalla de proyectos', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _pumpApp(tester, repo);

    await _submitCredentials(tester);

    expect(find.byType(ProjectsScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('ana@example.com'), findsOneWidget);
  });

  testWidgets('credenciales inválidas muestran el error y no navegan', (
    tester,
  ) async {
    final repo = FakeAuthRepository(
      signInResult: const Err(AuthFailure('Credenciales inválidas.')),
    );
    addTearDown(repo.dispose);
    await _pumpApp(tester, repo);

    await _submitCredentials(tester);

    expect(find.byKey(LoginKeys.error), findsOneWidget);
    expect(find.text('Credenciales inválidas.'), findsOneWidget);
    expect(find.byType(ProjectsScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('el formulario vacío no llama al backend', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _pumpApp(tester, repo);

    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu correo.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    expect(repo.signInCalls, 0);
  });

  testWidgets('cerrar sesión vuelve al login', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await _pumpApp(tester, repo);
    await _submitCredentials(tester);
    expect(find.byType(ProjectsScreen), findsOneWidget);

    await tester.tap(find.byKey(ProjectsKeys.logout));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProjectsScreen), findsNothing);
  });
}
