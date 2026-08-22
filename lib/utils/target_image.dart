import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/preset_character.dart';
import '../models/vent_target.dart';
import 'io_io.dart' if (dart.library.html) 'io_stub.dart' as io;
import 'web_blob_store.dart' as blobs;

class TargetImage {
  static const dataPrefix = 'data:image/jpeg;base64,';
  static const webBlobPrefix = 'idb:';
  static const relativeDir = 'target_images';

  static final Map<String, Uint8List> _blobMemoryCache = {};
  static final Map<String, String> _pathMemoryCache = {};

  static void cacheBlob(String id, Uint8List bytes) {
    _blobMemoryCache[id] = bytes;
  }

  static Future<void> preloadTarget(VentTarget target) async {
    if (!target.hasPhoto) return;
    final path = target.imagePath!;
    if (isWebBlobRef(path)) {
      final id = webBlobId(path)!;
      if (!_blobMemoryCache.containsKey(id)) {
        final bytes = await blobs.getPhotoBlob(id);
        if (bytes != null) _blobMemoryCache[id] = bytes;
      }
    } else if (!kIsWeb && isRelativeFileRef(path)) {
      if (!_pathMemoryCache.containsKey(path)) {
        final abs = await resolveAbsolutePath(path);
        _pathMemoryCache[path] = abs;
      }
    }
  }

  static bool isDataUri(String? path) =>
      path != null && path.startsWith('data:image/');

  static bool isWebBlobRef(String? path) =>
      path != null && path.startsWith(webBlobPrefix);

  static String webBlobRef(String id) => '$webBlobPrefix$id';

  static String? webBlobId(String path) =>
      isWebBlobRef(path) ? path.substring(webBlobPrefix.length) : null;

  /// True when [path] is a relative docs path like `target_images/uuid.jpg`.
  static bool isRelativeFileRef(String? path) =>
      path != null &&
      !isDataUri(path) &&
      !isWebBlobRef(path) &&
      !path.startsWith('/') &&
      !RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);

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

  static Future<String> resolveAbsolutePath(String stored) async {
    if (isDataUri(stored) || isWebBlobRef(stored) || !isRelativeFileRef(stored)) {
      return stored;
    }
    final docs = await io.appDocumentsPath();
    if (docs.isEmpty) return stored;
    return '$docs/$stored';
  }

  /// Drop in-memory caches for a stored photo path.
  static void forgetPath(String? path) {
    if (path == null || path.isEmpty) return;
    if (isWebBlobRef(path)) {
      final id = webBlobId(path);
      if (id != null) _blobMemoryCache.remove(id);
    }
    _pathMemoryCache.remove(path);
  }

  /// Deletes web blob or native `target_images/*.jpg` for a target photo.
  static Future<void> deleteStoredPhoto(String? path) async {
    if (path == null || path.isEmpty) return;
    forgetPath(path);
    if (isWebBlobRef(path)) {
      final id = webBlobId(path);
      if (id != null) await blobs.deletePhotoBlob(id);
      return;
    }
    if (kIsWeb || isDataUri(path)) return;
    final abs = await resolveAbsolutePath(path);
    await io.deleteFileIfExists(abs);
  }

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
      } else if (isWebBlobRef(path)) {
        final id = webBlobId(path)!;
        final cached = _blobMemoryCache[id];
        if (cached != null) {
          return Image.memory(cached, fit: fit, gaplessPlayback: true);
        }
        return FutureBuilder<Uint8List?>(
          future: blobs.getPhotoBlob(id),
          builder: (context, snap) {
            final bytes = snap.data;
            if (bytes != null) {
              _blobMemoryCache[id] = bytes;
              return Image.memory(bytes, fit: fit, gaplessPlayback: true);
            }
            return _fallback(preset, emojiSize);
          },
        );
      } else if (!kIsWeb) {
        final cachedAbs = _pathMemoryCache[path];
        if (cachedAbs != null) {
          return io.fileImage(cachedAbs, fit: fit);
        }
        return FutureBuilder<String>(
          future: resolveAbsolutePath(path),
          builder: (context, snap) {
            final abs = snap.data;
            if (abs == null) return _fallback(preset, emojiSize);
            _pathMemoryCache[path] = abs;
            return io.fileImage(abs, fit: fit);
          },
        );
      }
    }

    if (preset?.assetPath != null) {
      return Image.asset(
        preset!.assetPath!,
        fit: fit,
        errorBuilder: (_, _, _) => _fallback(preset, emojiSize),
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
