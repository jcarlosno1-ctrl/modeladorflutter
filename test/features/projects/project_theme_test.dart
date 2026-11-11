import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/projects/domain/project_theme.dart';

void main() {
  test('fromJson tolera datos inválidos y acota los tamaños', () {
    final theme = ProjectTheme.fromJson({
      'primary': 'no-es-hex',
      'bodySize': 999,
      'buttonRadius': -5,
    });

    expect(theme.primary, '#6750A4');
    expect(theme.bodySize, 24);
    expect(theme.buttonRadius, 0);
  });

  test('idempotente al serializar y deserializar', () {
    const theme = ProjectTheme(
      primary: '#112233',
      secondary: '#445566',
      tertiary: '#778899',
      bodySize: 15,
      appBarBackground: '#AABBCC',
      dividerColor: '#010203',
      buttonRadius: 12,
    );

    expect(ProjectTheme.fromJson(theme.toJson()), theme);
  });

  test('el tema por defecto se detecta', () {
    expect(const ProjectTheme().isDefault, isTrue);
    expect(const ProjectTheme(primary: '#000000').isDefault, isFalse);
  });
}
