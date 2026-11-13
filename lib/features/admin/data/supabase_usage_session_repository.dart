import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/usage_session_repository.dart';

/// Heartbeat contra `tenant_app.usage_sessions`.
class SupabaseUsageSessionRepository implements UsageSessionRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String?> start() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return null;
      }
      final row = await _client
          .schema('tenant_app')
          .from('usage_sessions')
          .insert({
            'user_id': user.id,
            'platform': 'editor',
          })
          .select('id')
          .single();
      return row['id'] as String?;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> heartbeat(String sessionId) async {
    try {
      await _client
          .schema('tenant_app')
          .from('usage_sessions')
          .update({'last_seen_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', sessionId);
    } on Object {
      // El uso no debe romper el editor.
    }
  }

  @override
  Future<void> end(String sessionId) async {
    await heartbeat(sessionId);
  }
}
