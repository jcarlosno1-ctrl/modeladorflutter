import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/projects/presentation/projects_screen.dart';

import '../application/auth_providers.dart';
import '../application/recovery_controller.dart';
import '../application/startup_auth_error.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

/// Decide qué pantalla mostrar según la sesión.
///
/// Es el único punto que lee [authStateProvider]: las pantallas no consultan
/// la sesión por su cuenta.
class AuthGate extends ConsumerWidget {
  /// Crea el gate.
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final hasSession = switch (auth) {
      AsyncData(:final value) => value != null,
      _ => false,
    };

    // Un enlace inválido/expirado se muestra con salida, pero **solo si no hay
    // sesión**: si el usuario ya entró, un enlace usado (doble clic, recarga)
    // no debe bloquear la app.
    final linkError = ref.watch(startupAuthErrorProvider);
    if (linkError != null && !hasSession) {
      return _AuthLinkErrorScreen(
        message: linkError,
        onDismiss: () => ref.read(startupAuthErrorProvider.notifier).clear(),
        onRequestNewLink: () {
          ref.read(startupAuthErrorProvider.notifier).clear();
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
          );
        },
      );
    }
    if (linkError != null) {
      // Hay sesión: el error quedó obsoleto, se limpia para no reaparecer al
      // cerrar sesión.
      Future<void>.microtask(
        () => ref.read(startupAuthErrorProvider.notifier).clear(),
      );
    }

    // Un enlace de recuperación entrega sesión: si no se intercepta primero,
    // el usuario nunca podría escribir su contraseña nueva.
    if (ref.watch(recoveryProvider)) {
      return const ResetPasswordScreen();
    }

    return switch (auth) {
      AsyncData(:final value) =>
        value == null ? const LoginScreen() : ProjectsScreen(user: value),
      AsyncError(:final error) => _AuthErrorScreen(
        message: error is Failure
            ? error.message
            : 'No se pudo verificar la sesión.',
      ),
      _ => const _AuthLoadingScreen(),
    };
  }
}

/// Pantalla de carga mientras se restaura la sesión persistida.
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Error irrecuperable al leer la sesión (configuración o red).
class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: scheme.error),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error de enlace de correo, con acciones para recuperarse.
class _AuthLinkErrorScreen extends StatelessWidget {
  const _AuthLinkErrorScreen({
    required this.message,
    required this.onDismiss,
    required this.onRequestNewLink,
  });

  final String message;
  final VoidCallback onDismiss;
  final VoidCallback onRequestNewLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_off, size: 40, color: scheme.error),
                const SizedBox(height: 12),
                Text('Enlace no válido', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRequestNewLink,
                  child: const Text('Solicitar enlace nuevo'),
                ),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
