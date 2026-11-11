import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import '../application/recovery_controller.dart';
import '../application/update_password_controller.dart';
import 'validators.dart';
import 'widgets/auth_card.dart';

/// Claves usadas por los tests de la nueva contraseña.
abstract final class ResetPasswordKeys {
  /// Nueva contraseña.
  static const Key password = Key('reset.password');

  /// Confirmación.
  static const Key confirm = Key('reset.confirm');

  /// Botón de envío.
  static const Key submit = Key('reset.submit');

  /// Mensaje de error.
  static const Key error = Key('reset.error');
}

/// Pantalla para definir la contraseña tras abrir el enlace de recuperación.
///
/// Se muestra cuando [recoveryProvider] está activo; al guardar, cierra el
/// modo recuperación y el `AuthGate` continúa con la sesión ya iniciada.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla.
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(updatePasswordControllerProvider.notifier)
        .submit(password: _passwordController.text);

    if (!mounted) {
      return;
    }

    final state = ref.read(updatePasswordControllerProvider);
    if (state.hasValue && state.value == true) {
      ref.read(recoveryProvider.notifier).finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(updatePasswordControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLoading = update.isLoading;
    final error = update.error;

    return AuthCard(
      icon: Icons.lock_reset_outlined,
      title: 'Nueva contraseña',
      subtitle: 'Elige una contraseña segura para tu cuenta',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: ResetPasswordKeys.password,
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
              key: ResetPasswordKeys.confirm,
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
                key: ResetPasswordKeys.error,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: ResetPasswordKeys.submit,
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
