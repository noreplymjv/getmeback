import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

Widget fileImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.file(
    File(path),
    fit: fit,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

Future<void> copyFile(String source, String dest) async {
  await File(source).copy(dest);
}

Future<void> writeBytes(String dest, Uint8List bytes) async {
  await File(dest).writeAsBytes(bytes);
}

Future<String> appDocumentsPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

Future<void> ensureDir(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

Future<void> deleteFileIfExists(String path) async {
  if (path.isEmpty) return;
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}
