import 'package:flutter/material.dart';

import '../domain/canvas_node.dart';

/// Plantilla de pantalla completa.
class ScreenTemplate {
  /// Crea la plantilla.
  const ScreenTemplate({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.fileName,
    required this.canvas,
  });

  /// Clave estable.
  final String id;

  /// Nombre visible.
  final String label;

  /// Descripción corta.
  final String description;

  /// Ícono de la tarjeta.
  final IconData icon;

  /// Nombre sugerido del archivo.
  final String fileName;

  /// Árbol de la pantalla.
  final CanvasNode canvas;
}

CanvasNode _screen(
  String id,
  List<CanvasNode> children, {
  bool initial = false,
}) => CanvasNode(
  id: 'root_$id',
  type: 'screen',
  properties: {if (initial) 'initial': true},
  children: children,
);

/// Plantillas listas para crear pantallas nuevas.
final List<ScreenTemplate> screenTemplates = [
  ScreenTemplate(
    id: 'splash',
    label: 'Splash Screen',
    description: 'Logo, nombre y carga inicial.',
    icon: Icons.rocket_launch_outlined,
    fileName: 'splash.dart',
    canvas: _screen('splash', initial: true, [
      CanvasNode(
        id: 'splash_center',
        type: 'center',
        children: [
          CanvasNode(
            id: 'splash_column',
            type: 'column',
            children: const [
              CanvasNode(
                id: 'splash_icon',
                type: 'icon',
                properties: {'icon': 'star', 'size': 72},
              ),
              CanvasNode(
                id: 'splash_title',
                type: 'text',
                properties: {'text': 'Mi App', 'size': 26},
              ),
              CanvasNode(
                id: 'splash_sub',
                type: 'text',
                properties: {'text': 'Cargando…', 'size': 13},
              ),
            ],
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'onboarding',
    label: 'Onboarding',
    description: 'Bienvenida con pasos y botón.',
    icon: Icons.auto_awesome_outlined,
    fileName: 'onboarding.dart',
    canvas: _screen('onboarding', [
      CanvasNode(
        id: 'onboarding_column',
        type: 'column',
        children: const [
          CanvasNode(
            id: 'onboarding_icon',
            type: 'icon',
            properties: {'icon': 'star', 'size': 64},
          ),
          CanvasNode(
            id: 'onboarding_title',
            type: 'text',
            properties: {'text': 'Bienvenido a Mi App', 'size': 24},
          ),
          CanvasNode(
            id: 'onboarding_text',
            type: 'text',
            properties: {
              'text': 'Descubrí todo lo que podés hacer en pocos pasos.',
              'size': 14,
            },
          ),
          CanvasNode(
            id: 'onboarding_button',
            type: 'button',
            properties: {'label': 'Continuar'},
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'login',
    label: 'Login',
    description: 'Correo, contraseña y acceso.',
    icon: Icons.login_outlined,
    fileName: 'login.dart',
    canvas: _screen('login', [
      CanvasNode(
        id: 'login_column',
        type: 'column',
        children: const [
          CanvasNode(
            id: 'login_title',
            type: 'text',
            properties: {'text': 'Iniciar sesión', 'size': 24},
          ),
          CanvasNode(
            id: 'login_email',
            type: 'textField',
            properties: {'label': 'Correo electrónico'},
          ),
          CanvasNode(
            id: 'login_password',
            type: 'textField',
            properties: {'label': 'Contraseña', 'obscure': true},
          ),
          CanvasNode(
            id: 'login_button',
            type: 'button',
            properties: {'label': 'Entrar'},
          ),
          CanvasNode(
            id: 'login_forgot',
            type: 'button',
            properties: {'label': '¿Olvidaste tu contraseña?', 'variant': 'text'},
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'register',
    label: 'Registro',
    description: 'Nombre, correo y contraseña.',
    icon: Icons.person_add_alt_outlined,
    fileName: 'registro.dart',
    canvas: _screen('register', [
      CanvasNode(
        id: 'register_column',
        type: 'column',
        children: const [
          CanvasNode(
            id: 'register_title',
            type: 'text',
            properties: {'text': 'Crear cuenta', 'size': 24},
          ),
          CanvasNode(
            id: 'register_name',
            type: 'textField',
            properties: {'label': 'Nombre'},
          ),
          CanvasNode(
            id: 'register_email',
            type: 'textField',
            properties: {'label': 'Correo electrónico'},
          ),
          CanvasNode(
            id: 'register_password',
            type: 'textField',
            properties: {'label': 'Contraseña', 'obscure': true},
          ),
          CanvasNode(
            id: 'register_button',
            type: 'button',
            properties: {'label': 'Registrarme'},
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'recovery',
    label: 'Recuperar contraseña',
    description: 'Correo para enviar el enlace.',
    icon: Icons.lock_reset_outlined,
    fileName: 'recuperar.dart',
    canvas: _screen('recovery', [
      CanvasNode(
        id: 'recovery_column',
        type: 'column',
        children: const [
          CanvasNode(
            id: 'recovery_title',
            type: 'text',
            properties: {'text': 'Recuperar contraseña', 'size': 22},
          ),
          CanvasNode(
            id: 'recovery_text',
            type: 'text',
            properties: {
              'text': 'Te enviaremos un enlace para restablecerla.',
              'size': 14,
            },
          ),
          CanvasNode(
            id: 'recovery_email',
            type: 'textField',
            properties: {'label': 'Correo electrónico'},
          ),
          CanvasNode(
            id: 'recovery_button',
            type: 'button',
            properties: {'label': 'Enviar enlace'},
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'home',
    label: 'Home / Dashboard',
    description: 'Encabezado y accesos rápidos.',
    icon: Icons.dashboard_outlined,
    fileName: 'home.dart',
    canvas: _screen('home', [
      CanvasNode(
        id: 'home_column',
        type: 'column',
        children: const [
          CanvasNode(
            id: 'home_title',
            type: 'text',
            properties: {'text': 'Hola 👋', 'size': 24},
          ),
          CanvasNode(
            id: 'home_sub',
            type: 'text',
            properties: {'text': 'Esto es tu panel principal', 'size': 14},
          ),
          CanvasNode(
            id: 'home_item1',
            type: 'listTile',
            properties: {
              'title': 'Mi perfil',
              'subtitle': 'Datos y preferencias',
              'icon': 'person',
            },
          ),
          CanvasNode(
            id: 'home_item2',
            type: 'listTile',
            properties: {
              'title': 'Notificaciones',
              'subtitle': 'Novedades de la app',
              'icon': 'notifications',
            },
          ),
          CanvasNode(
            id: 'home_item3',
            type: 'listTile',
            properties: {
              'title': 'Ajustes',
              'subtitle': 'Configuración general',
              'icon': 'settings',
            },
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'profile',
    label: 'Perfil y ajustes',
    description: 'Datos del usuario y preferencias.',
    icon: Icons.manage_accounts_outlined,
    fileName: 'perfil.dart',
    canvas: _screen('profile', [
      CanvasNode(
        id: 'profile_column',
        type: 'column',
        children: const [
          CanvasNode(
            id: 'profile_avatar',
            type: 'avatar',
            properties: {'radius': 36},
          ),
          CanvasNode(
            id: 'profile_title',
            type: 'text',
            properties: {'text': 'Tu perfil', 'size': 22},
          ),
          CanvasNode(
            id: 'profile_name',
            type: 'textField',
            properties: {'label': 'Nombre'},
          ),
          CanvasNode(
            id: 'profile_email',
            type: 'textField',
            properties: {'label': 'Correo electrónico'},
          ),
          CanvasNode(
            id: 'profile_switch',
            type: 'switchTile',
            properties: {'title': 'Notificaciones', 'value': true},
          ),
          CanvasNode(
            id: 'profile_button',
            type: 'button',
            properties: {'label': 'Guardar cambios'},
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'empty',
    label: 'Estado vacío',
    description: 'Sin datos, con acción para empezar.',
    icon: Icons.inbox_outlined,
    fileName: 'vacio.dart',
    canvas: _screen('empty', [
      CanvasNode(
        id: 'empty_center',
        type: 'center',
        children: [
          CanvasNode(
            id: 'empty_column',
            type: 'column',
            children: const [
              CanvasNode(
                id: 'empty_icon',
                type: 'icon',
                properties: {'icon': 'folder', 'size': 56},
              ),
              CanvasNode(
                id: 'empty_title',
                type: 'text',
                properties: {'text': 'Nada por aquí todavía', 'size': 20},
              ),
              CanvasNode(
                id: 'empty_text',
                type: 'text',
                properties: {'text': 'Creá el primer elemento.', 'size': 14},
              ),
              CanvasNode(
                id: 'empty_button',
                type: 'button',
                properties: {'label': 'Crear'},
              ),
            ],
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'error',
    label: 'Estado de error',
    description: 'Mensaje de error y reintento.',
    icon: Icons.error_outline,
    fileName: 'error.dart',
    canvas: _screen('error', [
      CanvasNode(
        id: 'error_center',
        type: 'center',
        children: [
          CanvasNode(
            id: 'error_column',
            type: 'column',
            children: const [
              CanvasNode(
                id: 'error_icon',
                type: 'icon',
                properties: {'icon': 'close', 'size': 56},
              ),
              CanvasNode(
                id: 'error_title',
                type: 'text',
                properties: {'text': 'Algo salió mal', 'size': 20},
              ),
              CanvasNode(
                id: 'error_text',
                type: 'text',
                properties: {'text': 'Intentá de nuevo en unos segundos.', 'size': 14},
              ),
              CanvasNode(
                id: 'error_button',
                type: 'button',
                properties: {'label': 'Reintentar'},
              ),
            ],
          ),
        ],
      ),
    ]),
  ),
  ScreenTemplate(
    id: 'loading',
    label: 'Estado de carga',
    description: 'Indicador de progreso y texto.',
    icon: Icons.hourglass_empty,
    fileName: 'cargando.dart',
    canvas: _screen('loading', [
      CanvasNode(
        id: 'loading_center',
        type: 'center',
        children: [
          CanvasNode(
            id: 'loading_column',
            type: 'column',
            children: const [
              CanvasNode(
                id: 'loading_progress',
                type: 'progress',
                properties: {'value': 0.6},
              ),
              CanvasNode(
                id: 'loading_text',
                type: 'text',
                properties: {'text': 'Cargando…', 'size': 14},
              ),
            ],
          ),
        ],
      ),
    ]),
  ),
];
