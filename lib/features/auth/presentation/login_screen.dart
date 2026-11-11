import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import '../application/login_controller.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'validators.dart';
import 'widgets/auth_card.dart';

/// Claves usadas por los tests del formulario.
abstract final class LoginKeys {
  /// Campo de correo.
  static const Key email = Key('login.email');

  /// Campo de contraseña.
  static const Key password = Key('login.password');

  /// Botón de envío.
  static const Key submit = Key('login.submit');

  /// Mensaje de error visible.
  static const Key error = Key('login.error');

  /// Enlace a la pantalla de registro.
  static const Key goToSignUp = Key('login.go_to_signup');

  /// Enlace a la recuperación de contraseña.
  static const Key goToForgotPassword = Key('login.go_to_forgot');
}

/// Pantalla de inicio de sesión.
///
/// Responsabilidad única: capturar credenciales y delegar en
/// [LoginController]. No conoce Supabase ni maneja `Session`.
class LoginScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(loginControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  void _openSignUp() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SignUpScreen()));
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final login = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLoading = login.isLoading;
    final error = login.error;

    return AuthCard(
      title: 'Flutter Studio Apps',
      subtitle: 'Inicia sesión para continuar',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: LoginKeys.email,
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
              key: LoginKeys.password,
              controller: _passwordController,
              enabled: !isLoading,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              validator: validatePassword,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error is Failure
                    ? error.message
                    : 'Ocurrió un error inesperado.',
                key: LoginKeys.error,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: LoginKeys.submit,
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton(
                  key: LoginKeys.goToSignUp,
                  onPressed: isLoading ? null : _openSignUp,
                  child: const Text('Crear cuenta'),
                ),
                TextButton(
                  key: LoginKeys.goToForgotPassword,
                  onPressed: isLoading ? null : _openForgotPassword,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
