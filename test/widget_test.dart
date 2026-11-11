import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/auth/presentation/login_screen.dart';
import 'package:modeladorflutter/main.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  testWidgets('sin sesión, la app arranca en el login', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const ModeladorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(LoginKeys.email), findsOneWidget);
    expect(find.byKey(LoginKeys.password), findsOneWidget);
  });
}
