// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

/// Descarga los bytes en el navegador (implementación web).
Future<void> downloadBytes(Uint8List bytes, String fileName) async {
  final blob = Blob([bytes], 'application/zip');
  final url = Url.createObjectUrlFromBlob(blob);
  AnchorElement(href: url)
    ..download = fileName
    ..click();
  Url.revokeObjectUrl(url);
}
