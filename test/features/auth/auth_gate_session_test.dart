import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/auth/domain/auth_user.dart';
import 'package:modeladorflutter/features/auth/presentation/auth_gate.dart';
import 'package:modeladorflutter/features/projects/application/project_providers.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_project_repository.dart';

void main() {
  testWidgets('al cambiar de usuario se recarga la lista de proyectos', (
    tester,
  ) async {
    final authChanges = StreamController<SessionUser?>.broadcast();
    addTearDown(authChanges.close);
    final repository = FakeProjectRepository(
      initial: [
        Project(
          id: 'p-1',
          name: 'Proyecto',
          createdAt: DateTime.utc(2026, 11, 12),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          authStateProvider.overrideWith((ref) => authChanges.stream),
          projectRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    authChanges.add(const SessionUser(id: 'user-1', email: 'uno@test.com'));
    await tester.pumpAndSettle();
    expect(repository.listCalls, 1);

    authChanges.add(const SessionUser(id: 'user-2', email: 'dos@test.com'));
    await tester.pumpAndSettle();
    expect(repository.listCalls, 2);
    expect(find.text('Proyecto'), findsOneWidget);
  });
}
