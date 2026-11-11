import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import '../application/auth_providers.dart';
import '../application/signup_controller.dart';
import 'validators.dart';
import 'widgets/auth_card.dart';

/// Claves usadas por los tests del registro.
abstract final class SignUpKeys {
  /// Campo de correo.
  static const Key email = Key('signup.email');

  /// Campo de contraseña.
  static const Key password = Key('signup.password');

  /// Campo de confirmación.
  static const Key confirm = Key('signup.confirm');

  /// Botón de envío.
  static const Key submit = Key('signup.submit');

  /// Mensaje de error visible.
  static const Key error = Key('signup.error');

  /// Panel de éxito (revisar correo).
  static const Key success = Key('signup.success');

  /// Volver al login desde el panel de éxito.
  static const Key back = Key('signup.back');

  /// Volver al login desde el formulario (p. ej. si el correo ya existe).
  static const Key goToLogin = Key('signup.go_to_login');
}

/// Pantalla de creación de cuenta.
///
/// Si el proyecto exige confirmar el correo, tras el alta se muestra un aviso
/// y no se navega; si ya hay sesión (confirmación desactivada), se cierra la
/// pantalla y el `AuthGate` muestra los proyectos.
class SignUpScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla.
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(signUpControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    final state = ref.read(signUpControllerProvider);
    if (state.hasValue && state.value == true) {
      // Con confirmación desactivada Supabase ya devolvió sesión: no tiene
      // sentido mostrar "revisa tu correo".
      final user = await ref.read(authRepositoryProvider).currentUser();
      if (!mounted) {
        return;
      }
      if (user != null) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUp = ref.watch(signUpControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLoading = signUp.isLoading;
    final error = signUp.error;
    final isSuccess = signUp.hasValue && signUp.value == true;

    if (isSuccess) {
      return AuthCard(
        icon: Icons.mark_email_read_outlined,
        title: 'Revisa tu correo',
        subtitle: 'Casi listo',
        child: Column(
          key: SignUpKeys.success,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enviamos un enlace de confirmación a ${_emailController.text.trim()}. '
              'Ábrelo para activar tu cuenta.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextButton(
              key: SignUpKeys.back,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      );
    }

    return AuthCard(
      title: 'Crear cuenta',
      subtitle: 'Regístrate para guardar tus proyectos',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: SignUpKeys.email,
              controller: _emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: SignUpKeys.password,
              controller: _passwordController,
              enabled: !isLoading,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                helperText: 'Mínimo 8 caracteres',
                border: OutlineInputBorder(),
              ),
              validator: validatePassword,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: SignUpKeys.confirm,
              controller: _confirmController,
              enabled: !isLoading,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden.';
                }
                return validatePassword(value);
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error is Failure ? error.message : 'Ocurrió un error inesperado.',
                key: SignUpKeys.error,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: SignUpKeys.submit,
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear cuenta'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: SignUpKeys.goToLogin,
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
