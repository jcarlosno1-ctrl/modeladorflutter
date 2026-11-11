import 'package:flutter/material.dart';

/// Tarjeta contenedora común a login, registro y recuperación.
///
/// En pantallas anchas muestra un panel de marca a la izquierda y el
/// formulario a la derecha; en móvil apila la marca sobre la tarjeta.
class AuthCard extends StatelessWidget {
  /// Crea la tarjeta.
  const AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.widgets_rounded,
    super.key,
  });

  /// Título principal.
  final String title;

  /// Texto de apoyo bajo el título.
  final String subtitle;

  /// Contenido de la tarjeta (formulario o mensaje de éxito).
  final Widget child;

  /// Ícono superior.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 780;
                  final card = _card(theme);
                  if (!wide) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BrandPanel(compact: true),
                        const SizedBox(height: 16),
                        card,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(child: _BrandPanel(compact: false)),
                      const SizedBox(width: 32),
                      SizedBox(width: 420, child: card),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _BrandLogo(size: 36, icon: Icons.widgets_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

/// Panel de marca con degradado.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B5F59), Color(0xFF0F766E), Color(0xFF12958B)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandLogo(size: compact ? 36 : 44, icon: Icons.widgets_rounded),
              SizedBox(height: compact ? 12 : 24),
              Text(
                'Flutter Studio Apps',
                style: TextStyle(
                  fontSize: compact ? 18 : 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Diseña, crea e innova apps con Flutter y Dart.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xCCFFFFFF),
                  height: 1.4,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 24),
                for (final item in const [
                  'Modelador visual de widgets',
                  'Código Dart listo para usar',
                  'Tus proyectos en la nube',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 15,
                          color: Color(0xFF99F6E4),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Marca cuadrada con el punto amarillo.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: Icon(
              icon,
              size: size * 0.5,
              color: const Color(0xFF0F766E),
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: const BoxDecoration(
                color: Color(0xFFFACC15),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
