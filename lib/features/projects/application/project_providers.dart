import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/supabase_project_repository.dart';
import '../domain/project_repository.dart';

/// Repositorio de proyectos (interfaz de dominio).
///
/// En tests se reemplaza con `overrideWithValue(...)`.
final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => SupabaseProjectRepository(ref.watch(supabaseClientProvider)),
);
