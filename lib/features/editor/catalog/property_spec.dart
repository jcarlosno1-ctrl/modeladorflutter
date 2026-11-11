/// Tipo de valor que acepta una propiedad.
enum PropertyType {
  /// Texto de una línea.
  text,

  /// Texto multilínea.
  multilineText,

  /// Número (se acota a `min`/`max`).
  number,

  /// Interruptor.
  boolean,

  /// Una opción de una lista cerrada.
  choice,

  /// Color: token del theme (`surface`, `low`, …) o hex `#RRGGBB`.
  color,
}

/// Opción válida de una propiedad [PropertyType.choice].
class PropertyChoice {
  /// Crea una opción.
  const PropertyChoice(this.value, this.label);

  /// Valor persistido.
  final String value;

  /// Etiqueta mostrada en el panel.
  final String label;
}

/// Esquema de una propiedad de un componente.
///
/// El panel de propiedades se genera a partir de esta lista y el renderizador
/// **coacciona** cualquier valor recibido: si el JSON trae algo inválido, se
/// cae al valor por defecto en lugar de romper la UI.
class PropertySpec {
  /// Crea el esquema.
  const PropertySpec({
    required this.key,
    required this.label,
    required this.type,
    required this.defaultValue,
    this.choices = const [],
    this.min,
    this.max,
    this.maxLength,
    this.group = 'General',
    this.hint,
    this.suffix,
    this.step,
    this.integer = false,
    this.hidden = false,
  });

  /// Texto de una línea, con longitud máxima opcional.
  const PropertySpec.text(
    this.key,
    this.label, {
    this.defaultValue = '',
    this.maxLength = 120,
    this.group = 'General',
    this.hint,
    this.suffix,
    this.hidden = false,
  }) : type = PropertyType.text,
       choices = const [],
       min = null,
       max = null,
       step = null,
       integer = false;

  /// Texto multilínea.
  const PropertySpec.multiline(
    this.key,
    this.label, {
    this.defaultValue = '',
    this.maxLength = 2000,
    this.group = 'General',
    this.hint,
    this.suffix,
    this.hidden = false,
  }) : type = PropertyType.multilineText,
       choices = const [],
       min = null,
       max = null,
       step = null,
       integer = false;

  /// Número acotado.
  const PropertySpec.number(
    this.key,
    this.label, {
    required this.defaultValue,
    this.min,
    this.max,
    this.group = 'General',
    this.hint,
    this.suffix,
    this.step,
    this.integer = false,
    this.hidden = false,
  }) : type = PropertyType.number,
       choices = const [],
       maxLength = null;

  /// Booleano.
  const PropertySpec.boolean(
    this.key,
    this.label, {
    this.defaultValue = false,
    this.group = 'General',
    this.hint,
    this.suffix,
    this.hidden = false,
  }) : type = PropertyType.boolean,
       choices = const [],
       min = null,
       max = null,
       maxLength = null,
       step = null,
       integer = false;

  /// Opción cerrada; el valor por defecto debe estar entre [choices].
  const PropertySpec.choice(
    this.key,
    this.label, {
    required this.choices,
    required this.defaultValue,
    this.group = 'General',
    this.hint,
    this.suffix,
    this.hidden = false,
  }) : type = PropertyType.choice,
       min = null,
       max = null,
       maxLength = null,
       step = null,
       integer = false;

  /// Color: permite tokens del theme ([choices]) o un hex `#RRGGBB`.
  ///
  /// Cadena vacía = sin color explícito (se usa el del tema).
  const PropertySpec.color(
    this.key,
    this.label, {
    this.defaultValue = '',
    this.choices = const [],
    this.group = 'General',
    this.hint,
    this.suffix,
    this.hidden = false,
  }) : type = PropertyType.color,
       min = null,
       max = null,
       maxLength = null,
       step = null,
       integer = false;

  /// Clave en el mapa de propiedades.
  final String key;

  /// Etiqueta visible en el panel.
  final String label;

  /// Tipo esperado.
  final PropertyType type;

  /// Valor usado si falta o es inválido.
  final Object? defaultValue;

  /// Opciones para [PropertyType.choice].
  final List<PropertyChoice> choices;

  /// Mínimo para [PropertyType.number].
  final double? min;

  /// Máximo para [PropertyType.number].
  final double? max;

  /// Longitud máxima para textos.
  final int? maxLength;

  /// Sección del panel de propiedades (`Colores`, `Diseño`, …).
  final String group;

  /// Texto de ayuda bajo el control.
  final String? hint;

  /// Unidad mostrada junto al valor (`px`, `%`, …).
  final String? suffix;

  /// Incremento sugerido para [PropertyType.number].
  final double? step;

  /// `true` si el número debe mostrarse sin decimales.
  final bool integer;

  /// `true` si el valor existe en el modelo pero no se edita en el panel
  /// (por ejemplo, el dispositivo: lo controla la barra del lienzo).
  final bool hidden;

  /// `true` si el default es neutro (0, vacío, heredar, ninguno o false) y
  /// por tanto la propiedad puede ocultarse tras el modo Avanzado.
  bool get isAdvancedByDefault {
    if (hidden || type == PropertyType.color) {
      return false;
    }
    if (type == PropertyType.boolean) {
      return defaultValue == false;
    }
    if (type == PropertyType.number) {
      return defaultValue is num && (defaultValue as num) == 0;
    }
    final value = defaultValue;
    return value == null ||
        value == '' ||
        value == 'inherit' ||
        value == 'none';
  }

  /// `true` si [value] respeta el esquema.
  bool accepts(Object? value) {
    switch (type) {
      case PropertyType.text:
      case PropertyType.multilineText:
        return value is String &&
            (maxLength == null || value.length <= maxLength!);
      case PropertyType.number:
        if (value is! num) {
          return false;
        }
        final number = value.toDouble();
        if (min != null && number < min!) {
          return false;
        }
        if (max != null && number > max!) {
          return false;
        }
        return true;
      case PropertyType.boolean:
        return value is bool;
      case PropertyType.choice:
        return value is String && choices.any((c) => c.value == value);
      case PropertyType.color:
        if (value is! String) {
          return false;
        }
        if (value.isEmpty) {
          return true;
        }
        if (choices.any((choice) => choice.value == value)) {
          return true;
        }
        return _hexPattern.hasMatch(value);
    }
  }

  static final RegExp _hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// Devuelve [value] si es válido; si no, el valor por defecto.
  Object? coerce(Object? value) => accepts(value) ? value : defaultValue;

  /// `true` si el valor por defecto cumple el propio esquema.
  bool get hasValidDefault => accepts(defaultValue);
}
