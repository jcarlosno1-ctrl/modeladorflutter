import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/auth/application/startup_auth_error.dart';
import 'package:modeladorflutter/features/auth/data/auth_link_handler.dart';
import 'package:modeladorflutter/features/auth/presentation/forgot_password_screen.dart';
import 'package:modeladorflutter/features/auth/presentation/login_screen.dart';
import 'package:modeladorflutter/features/projects/application/project_providers.dart';
import 'package:modeladorflutter/features/projects/presentation/projects_screen.dart';
import 'package:modeladorflutter/main.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_project_repository.dart';

Future<void> _pumpWithLinkError(
  WidgetTester tester,
  String message,
  FakeAuthRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        projectRepositoryProvider.overrideWithValue(FakeProjectRepository()),
        startupAuthErrorProvider.overrideWith(
          () => StartupAuthError(message),
        ),
      ],
      child: const ModeladorApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AuthLinkHandler', () {
    test('otp_expired se traduce a un mensaje accionable', () {
      final message = AuthLinkHandler.messageFor('otp_expired');

      expect(message, contains('expiró'));
      expect(message, contains('Solicita uno nuevo'));
    });

    test('un código desconocido usa el mensaje genérico', () {
      expect(
        AuthLinkHandler.messageFor('algo_raro'),
        'No pudimos validar el enlace. Solicita uno nuevo.',
      );
    });

    test('los tipos de enlace se mapean correctamente', () {
      expect(AuthLinkHandler.otpTypeFor('recovery').name, contains('recovery'));
      expect(AuthLinkHandler.otpTypeFor('signup').name, contains('signup'));
      expect(AuthLinkHandler.otpTypeFor('desconocido').name, contains('signup'));
    });
  });

  group('pantalla de enlace inválido', () {
    testWidgets('con sesión activa, un enlace usado no bloquea la app', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);

      // El usuario ya inició sesión antes de abrir un enlace viejo.
      await repo.signIn(email: 'ana@example.com', password: 'secreta123');
      await _pumpWithLinkError(tester, 'El enlace expiró.', repo);

      expect(find.byType(ProjectsScreen), findsOneWidget);
      expect(find.text('Enlace no válido'), findsNothing);
    });

    testWidgets('muestra el mensaje y permite pedir uno nuevo', (tester) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);

      await _pumpWithLinkError(
        tester,
        'El enlace expiró o ya fue usado.',
        repo,
      );

      expect(find.text('Enlace no válido'), findsOneWidget);
      expect(find.text('El enlace expiró o ya fue usado.'), findsOneWidget);

      await tester.tap(find.text('Solicitar enlace nuevo'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('volver al inicio lleva al login', (tester) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);

      await _pumpWithLinkError(tester, 'El enlace expiró.', repo);

      await tester.tap(find.text('Volver al inicio de sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
