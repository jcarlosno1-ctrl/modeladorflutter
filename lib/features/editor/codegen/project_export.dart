import 'dart:convert';
import 'dart:typed_data';

import 'package:modeladorflutter/features/projects/domain/project_theme.dart';

import '../domain/project_screen.dart';
import 'dart_code_generator.dart';
import 'export_stub.dart' if (dart.library.html) 'export_web.dart';

/// Archivo generado listo para exportar.
class ExportedFile {
  /// Crea el archivo con su ruta dentro de `lib/`.
  const ExportedFile(this.path, this.content);

  /// Ruta relativa, por ejemplo `lib/main.dart`.
  final String path;

  /// Código Dart completo.
  final String content;
}

/// Genera `lib/main.dart` y `lib/screens/*.dart` para todas las pantallas.
List<ExportedFile> buildProjectFiles({
  required List<ProjectScreen> screens,
  required String entryScreenId,
  ProjectTheme theme = const ProjectTheme(),
  String? initialScreenId,
  String projectName = 'Flutter Studio App',
}) {
  if (screens.isEmpty) {
    return const [];
  }
  final entry = screens.firstWhere(
    (screen) => screen.id == entryScreenId,
    orElse: () => screens.first,
  );

  final usedNames = <String>{};
  final planned = <({ProjectScreen screen, bool isEntry, String fileName})>[];

  for (final screen in screens) {
    if (screen.canvas == null) {
      continue;
    }
    final isEntry = screen.id == entry.id;
    var fileName = isEntry ? 'main.dart' : screen.name;
    if (!isEntry) {
      // Evita colisiones de nombre entre pantallas.
      final base = fileName.replaceAll('.dart', '');
      var candidate = base;
      var suffix = 2;
      while (!usedNames.add(candidate.toLowerCase())) {
        candidate = '${base}_$suffix';
        suffix++;
      }
      fileName = '$candidate.dart';
    }
    planned.add((screen: screen, isEntry: isEntry, fileName: fileName));
  }

  final routes = <String, ({String className, String path})>{
    for (final item in planned)
      if (!item.isEntry)
        item.screen.id: (
          className: DartCodeGenerator.classNameFor(
            fileName: item.fileName,
            isEntry: false,
          ),
          path: DartCodeGenerator.pathFor(
            fileName: item.fileName,
            isEntry: false,
          ),
        ),
  };

  final files = <ExportedFile>[];
  final initialRoute = initialScreenId == null || initialScreenId == entry.id
      ? null
      : '/screen/$initialScreenId';
  for (final item in planned) {
    final content = DartCodeGenerator.generate(
      screen: item.screen.canvas!,
      fileName: item.fileName,
      isEntry: item.isEntry,
      theme: theme,
      routes: routes,
      initialRoute: item.isEntry ? initialRoute : null,
    );
    files.add(
      ExportedFile(
        DartCodeGenerator.pathFor(
          fileName: item.fileName,
          isEntry: item.isEntry,
        ),
        content,
      ),
    );
  }
  final slug = projectName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final package = slug.isEmpty ? 'flutter_studio_app' : slug;
  files.add(
    ExportedFile(
      'pubspec.yaml',
      "name: $package\n"
      "description: Proyecto generado con Flutter Studio Apps.\n"
      "publish_to: 'none'\n"
      'version: 1.0.0+1\n'
      'environment:\n'
      "  sdk: '>=3.5.0 <4.0.0'\n"
      'dependencies:\n'
      '  flutter:\n'
      '    sdk: flutter\n'
      '  cupertino_icons: ^1.0.8\n'
      'dev_dependencies:\n'
      '  flutter_test:\n'
      '    sdk: flutter\n'
      '  flutter_lints: ^5.0.0\n'
      'flutter:\n'
      '  uses-material-design: true\n',
    ),
  );
  files.add(
    ExportedFile(
      'README.md',
      '# $projectName\n\n'
      'Proyecto generado con **Flutter Studio Apps**.\n\n'
      '## Abrir en VS Code\n\n'
      '1. Descomprimí el ZIP.\n'
      '2. Abrí la carpeta en VS Code.\n'
      '3. En la terminal: `flutter pub get`.\n'
      '4. Ejecutá: `flutter run`.\n\n'
      'La pantalla inicial se configura en el editor con la propiedad '
      '**Pantalla inicial**.\n',
    ),
  );
  return files;
}

/// Construye un ZIP (sin compresión) con los archivos generados.
Uint8List buildZipBytes(List<ExportedFile> files) {
  final local = BytesBuilder();
  final central = BytesBuilder();
  var offset = 0;
  var entries = 0;

  for (final file in files) {
    final name = utf8.encode(file.path);
    final data = utf8.encode(file.content);
    final crc = _crc32(data);

    final header = BytesBuilder();
    _u32(header, 0x04034b50);
    _u16(header, 20);
    _u16(header, 0x0800);
    _u16(header, 0);
    _u16(header, 0);
    _u16(header, 0);
    _u32(header, crc);
    _u32(header, data.length);
    _u32(header, data.length);
    _u16(header, name.length);
    _u16(header, 0);
    header.add(name);
    header.add(data);

    final bytes = header.takeBytes();
    local.add(bytes);

    final centralHeader = BytesBuilder();
    _u32(centralHeader, 0x02014b50);
    _u16(centralHeader, 20);
    _u16(centralHeader, 20);
    _u16(centralHeader, 0x0800);
    _u16(centralHeader, 0);
    _u16(centralHeader, 0);
    _u16(centralHeader, 0);
    _u32(centralHeader, crc);
    _u32(centralHeader, data.length);
    _u32(centralHeader, data.length);
    _u16(centralHeader, name.length);
    _u16(centralHeader, 0);
    _u16(centralHeader, 0);
    _u16(centralHeader, 0);
    _u16(centralHeader, 0);
    _u32(centralHeader, 0);
    _u32(centralHeader, offset);
    centralHeader.add(name);
    central.add(centralHeader.takeBytes());

    offset += bytes.length;
    entries++;
  }

  final centralBytes = central.takeBytes();
  final end = BytesBuilder();
  _u32(end, 0x06054b50);
  _u16(end, 0);
  _u16(end, 0);
  _u16(end, entries);
  _u16(end, entries);
  _u32(end, centralBytes.length);
  _u32(end, offset);
  _u16(end, 0);

  final result = BytesBuilder()
    ..add(local.takeBytes())
    ..add(centralBytes)
    ..add(end.takeBytes());
  return result.takeBytes();
}

/// Exporta el proyecto y devuelve cuántos archivos incluyó.
Future<int> exportProjectZip({
  required List<ProjectScreen> screens,
  required String entryScreenId,
  required String projectName,
  ProjectTheme theme = const ProjectTheme(),
  String? initialScreenId,
}) async {
  final files = buildProjectFiles(
    screens: screens,
    entryScreenId: entryScreenId,
    theme: theme,
    initialScreenId: initialScreenId,
    projectName: projectName,
  );
  if (files.isEmpty) {
    return 0;
  }
  final safeName = projectName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  await downloadBytes(
    buildZipBytes(files),
    '${safeName.isEmpty ? 'flutter_studio_app' : safeName}.zip',
  );
  return files.where((file) => file.path.endsWith('.dart')).length;
}

void _u16(BytesBuilder builder, int value) {
  final data = ByteData(2)..setUint16(0, value, Endian.little);
  builder.add(data.buffer.asUint8List());
}

void _u32(BytesBuilder builder, int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  builder.add(data.buffer.asUint8List());
}

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
