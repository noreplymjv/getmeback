import 'dart:typed_data';

import 'package:flutter/widgets.dart';

Widget fileImage(String path, {BoxFit fit = BoxFit.cover}) {
  return const SizedBox.shrink();
}

// keep API aligned with io_io.dart

Future<void> copyFile(String source, String dest) async {}

Future<void> writeBytes(String dest, Uint8List bytes) async {}

Future<String> appDocumentsPath() async => '';

Future<void> ensureDir(String path) async {}

Future<void> deleteFileIfExists(String path) async {}
