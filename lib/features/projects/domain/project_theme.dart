/// Tema visual del proyecto (siempre modo claro, Material 3).
///
/// Se guarda como `jsonb` en `tenant_app.projects.theme`. Los colores son hex
/// `#RRGGBB`; la cadena vacía significa “usar el del tema base”.
class ProjectTheme {
  /// Crea un tema.
  const ProjectTheme({
    this.primary = '#6750A4',
    this.secondary = '#625B71',
    this.tertiary = '#7D5260',
    this.appBarBackground = '',
    this.appBarForeground = '',
    this.appBarTitleSize = 20,
    this.bodySize = 14,
    this.titleSize = 22,
    this.labelSize = 14,
    this.inputSize = 16,
    this.dividerColor = '',
    this.buttonRadius = 8,
  });

  /// Color primario de la app.
  final String primary;

  /// Color secundario.
  final String secondary;

  /// Color terciario.
  final String tertiary;

  /// Fondo por defecto de las AppBar (vacío = tema).
  final String appBarBackground;

  /// Texto/íconos por defecto de las AppBar (vacío = tema).
  final String appBarForeground;

  /// Tamaño del título de la AppBar.
  final double appBarTitleSize;

  /// Tamaño de textos normales (`bodyMedium`).
  final double bodySize;

  /// Tamaño de títulos (`titleLarge`).
  final double titleSize;

  /// Tamaño de etiquetas y botones (`labelLarge`).
  final double labelSize;

  /// Tamaño dentro de campos de texto (`bodyLarge`).
  final double inputSize;

  /// Color de líneas y divisores (vacío = tema).
  final String dividerColor;

  /// Radio de los botones.
  final double buttonRadius;

  /// `true` si no personalizó nada.
  bool get isDefault => this == const ProjectTheme();

  /// Construye desde JSON, tolerando valores inválidos.
  factory ProjectTheme.fromJson(Map<String, dynamic> json) {
    return ProjectTheme(
      primary: _hex(json['primary'], '#6750A4'),
      secondary: _hex(json['secondary'], '#625B71'),
      tertiary: _hex(json['tertiary'], '#7D5260'),
      appBarBackground: _hex(json['appBarBackground'], ''),
      appBarForeground: _hex(json['appBarForeground'], ''),
      appBarTitleSize: _size(json['appBarTitleSize'], 20, 12, 32),
      bodySize: _size(json['bodySize'], 14, 10, 24),
      titleSize: _size(json['titleSize'], 22, 12, 40),
      labelSize: _size(json['labelSize'], 14, 10, 24),
      inputSize: _size(json['inputSize'], 16, 10, 28),
      dividerColor: _hex(json['dividerColor'], ''),
      buttonRadius: _size(json['buttonRadius'], 8, 0, 32),
    );
  }

  /// Serializa solo lo que necesita persistirse.
  Map<String, Object?> toJson() => {
    'primary': primary,
    'secondary': secondary,
    'tertiary': tertiary,
    'appBarBackground': appBarBackground,
    'appBarForeground': appBarForeground,
    'appBarTitleSize': appBarTitleSize,
    'bodySize': bodySize,
    'titleSize': titleSize,
    'labelSize': labelSize,
    'inputSize': inputSize,
    'dividerColor': dividerColor,
    'buttonRadius': buttonRadius,
  };

  /// Copia con cambios.
  ProjectTheme copyWith({
    String? primary,
    String? secondary,
    String? tertiary,
    String? appBarBackground,
    String? appBarForeground,
    double? appBarTitleSize,
    double? bodySize,
    double? titleSize,
    double? labelSize,
    double? inputSize,
    String? dividerColor,
    double? buttonRadius,
  }) {
    return ProjectTheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      appBarBackground: appBarBackground ?? this.appBarBackground,
      appBarForeground: appBarForeground ?? this.appBarForeground,
      appBarTitleSize: appBarTitleSize ?? this.appBarTitleSize,
      bodySize: bodySize ?? this.bodySize,
      titleSize: titleSize ?? this.titleSize,
      labelSize: labelSize ?? this.labelSize,
      inputSize: inputSize ?? this.inputSize,
      dividerColor: dividerColor ?? this.dividerColor,
      buttonRadius: buttonRadius ?? this.buttonRadius,
    );
  }

  static final RegExp _hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  static String _hex(Object? value, String fallback) {
    if (value is! String) {
      return fallback;
    }
    if (value.isEmpty) {
      return '';
    }
    return _hexPattern.hasMatch(value) ? value.toUpperCase() : fallback;
  }

  static double _size(Object? value, double fallback, double min, double max) {
    if (value is! num) {
      return fallback;
    }
    return value.toDouble().clamp(min, max);
  }

  @override
  bool operator ==(Object other) =>
      other is ProjectTheme &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.tertiary == tertiary &&
      other.appBarBackground == appBarBackground &&
      other.appBarForeground == appBarForeground &&
      other.appBarTitleSize == appBarTitleSize &&
      other.bodySize == bodySize &&
      other.titleSize == titleSize &&
      other.labelSize == labelSize &&
      other.inputSize == inputSize &&
      other.dividerColor == dividerColor &&
      other.buttonRadius == buttonRadius;

  @override
  int get hashCode => Object.hash(
    primary,
    secondary,
    tertiary,
    appBarBackground,
    appBarForeground,
    appBarTitleSize,
    bodySize,
    titleSize,
    labelSize,
    inputSize,
    dividerColor,
    buttonRadius,
  );
}
