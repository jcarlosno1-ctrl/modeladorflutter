import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_admin_repository.dart';
import '../data/supabase_usage_session_repository.dart';
import '../domain/admin_repository.dart';
import '../domain/usage_session_repository.dart';

/// Repositorio de estadísticas de administración.
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => SupabaseAdminRepository(),
);

/// Registro de sesiones de uso del editor.
final usageSessionRepositoryProvider = Provider<UsageSessionRepository>(
  (ref) => SupabaseUsageSessionRepository(),
);
