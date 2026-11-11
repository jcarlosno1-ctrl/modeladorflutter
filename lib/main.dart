import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/app/app_theme.dart';
import 'package:modeladorflutter/core/config/app_config.dart';
import 'package:modeladorflutter/features/auth/application/startup_auth_error.dart';
import 'package:modeladorflutter/features/auth/data/auth_link_handler.dart';
import 'package:modeladorflutter/features/auth/presentation/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración primero: si falta `.env`, es mejor fallar aquí con un
  // mensaje claro que mostrar un login que nunca funciona.
  await AppConfig.load();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    // Todas las tablas de negocio viven en `tenant_app`; así `.from(...)`
    // apunta ahí sin repetir el esquema en cada consulta.
    postgrestOptions: const PostgrestClientOptions(schema: 'tenant_app'),
  );

  // Enlaces de correo: verifica el token o detecta que expiró, antes de
  // decidir qué pantalla mostrar.
  final link = await AuthLinkHandler.process();

  runApp(
    ProviderScope(
      overrides: [
        startupAuthErrorProvider.overrideWith(
          () => StartupAuthError(link.errorMessage),
        ),
      ],
      child: const ModeladorApp(),
    ),
  );
}

/// Raíz de la aplicación: tema Material 3 y gate de sesión.
class ModeladorApp extends StatelessWidget {
  /// Crea la aplicación.
  const ModeladorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Studio Apps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
