import 'dart:typed_data';

/// Descarga de archivos: en plataformas sin navegador no hace nada.
Future<void> downloadBytes(Uint8List bytes, String fileName) async {}
