import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/preset_character.dart';
import '../models/vent_target.dart';
import 'io_io.dart' if (dart.library.html) 'io_stub.dart' as io;

class TargetImage {
  static const dataPrefix = 'data:image/jpeg;base64,';

  static bool isDataUri(String? path) =>
      path != null && path.startsWith('data:image/');

  static Uint8List? decodeDataUri(String path) {
    final comma = path.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(path.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  static String encodeJpegBytes(Uint8List bytes) =>
      '$dataPrefix${base64Encode(bytes)}';

  static Widget build({
    required VentTarget target,
    BoxFit fit = BoxFit.cover,
    double? emojiSize,
  }) {
    final preset = PresetCharacter.findById(target.presetId);

    if (target.hasPhoto) {
      final path = target.imagePath!;
      if (isDataUri(path)) {
        final bytes = decodeDataUri(path);
        if (bytes != null) {
          return Image.memory(bytes, fit: fit, gaplessPlayback: true);
        }
      } else if (!kIsWeb) {
        return io.fileImage(path, fit: fit);
      }
    }

    if (preset?.assetPath != null) {
      return Image.asset(
        preset!.assetPath!,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(preset, emojiSize),
      );
    }

    return _fallback(preset, emojiSize);
  }

  static Widget _fallback(PresetCharacter? preset, double? emojiSize) {
    return ColoredBox(
      color: preset?.color ?? const Color(0xFF2A2A3A),
      child: Center(
        child: Text(
          preset?.emoji ?? '🎯',
          style: TextStyle(fontSize: emojiSize ?? 48),
        ),
      ),
    );
  }
}
