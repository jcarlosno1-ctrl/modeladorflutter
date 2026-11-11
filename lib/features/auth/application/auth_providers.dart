import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Cliente Supabase ya inicializado en `main()`.
///
/// Se expone como provider para que los repositorios no usen singletons y
/// puedan sustituirse en tests.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Repositorio de autenticación (interfaz de dominio).
///
/// En tests se reemplaza con `overrideWithValue(...)`; por eso ningún widget
/// debe importar `SupabaseAuthRepository` directamente.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final redirect = AppConfig.authRedirectUrl;
  return SupabaseAuthRepository(
    ref.watch(supabaseClientProvider),
    redirectUrl: redirect.isEmpty ? null : redirect,
  );
});

/// Sesión actual, reactiva.
///
/// Emite `null` cuando no hay sesión; es la fuente de verdad para el
/// `AuthGate`.
final authStateProvider = StreamProvider<SessionUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
