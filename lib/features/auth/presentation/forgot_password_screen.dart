import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import '../application/forgot_password_controller.dart';
import 'validators.dart';
import 'widgets/auth_card.dart';

/// Claves usadas por los tests de recuperación.
abstract final class ForgotPasswordKeys {
  /// Campo de correo.
  static const Key email = Key('forgot.email');

  /// Botón de envío.
  static const Key submit = Key('forgot.submit');

  /// Mensaje de error visible.
  static const Key error = Key('forgot.error');

  /// Panel de éxito.
  static const Key success = Key('forgot.success');
}

/// Pantalla de recuperación de contraseña.
///
/// Por seguridad no revela si el correo está registrado: el mensaje de éxito
/// es neutral (evita enumeración de cuentas).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla.
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(email: _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final forgot = ref.watch(forgotPasswordControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLoading = forgot.isLoading;
    final error = forgot.error;
    final isSuccess = forgot.hasValue && forgot.value == true;

    if (isSuccess) {
      return AuthCard(
        icon: Icons.mark_email_read_outlined,
        title: 'Revisa tu correo',
        subtitle: 'Solicitud enviada',
        child: Column(
          key: ForgotPasswordKeys.success,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Si el correo está registrado, recibirás un enlace para '
              'restablecer tu contraseña. Revisa también la carpeta de spam.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      );
    }

    return AuthCard(
      icon: Icons.lock_reset_outlined,
      title: 'Recuperar contraseña',
      subtitle: 'Te enviaremos un enlace a tu correo',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: ForgotPasswordKeys.email,
              controller: _emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
              validator: validateEmail,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error is Failure ? error.message : 'Ocurrió un error inesperado.',
                key: ForgotPasswordKeys.error,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: ForgotPasswordKeys.submit,
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar enlace'),
            ),
          ],
        ),
      ),
    );
  }
}
