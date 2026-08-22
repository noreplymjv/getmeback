import 'package:flutter/material.dart';

/// Normalized (0–1) tap points tuned to each illustrated room background.
/// x = left→right, y = top→bottom of the visible stage.
class RoomHotspots {
  RoomHotspots._();

  static const Map<String, Map<String, Offset>> _spots = {
    'kitchen': {
      'glass': Offset(0.17, 0.56),
      'plate': Offset(0.44, 0.52),
      'mug': Offset(0.56, 0.48),
      'blender': Offset(0.30, 0.40),
      'chair': Offset(0.83, 0.50),
      'table': Offset(0.47, 0.54),
    },
    'bathroom': {
      'mirror': Offset(0.50, 0.22),
      'glass': Offset(0.72, 0.38),
      'bottle': Offset(0.68, 0.42),
      'soap': Offset(0.58, 0.40),
      'toilet': Offset(0.78, 0.62),
      'towel': Offset(0.22, 0.35),
    },
    'office': {
      'monitor': Offset(0.52, 0.38),
      'keyboard': Offset(0.50, 0.48),
      'mug': Offset(0.38, 0.46),
      'chair': Offset(0.48, 0.62),
      'lamp': Offset(0.18, 0.32),
      'plant': Offset(0.82, 0.55),
    },
    'cabin': {
      'lantern': Offset(0.22, 0.35),
      'mug': Offset(0.48, 0.52),
      'chair': Offset(0.62, 0.58),
      'table': Offset(0.45, 0.55),
      'window': Offset(0.78, 0.32),
      'logs': Offset(0.28, 0.68),
    },
    'living': {
      'tv': Offset(0.70, 0.36),
      'sofa': Offset(0.30, 0.50),
      'glass': Offset(0.50, 0.56),
      'vase': Offset(0.74, 0.46),
      'lamp': Offset(0.14, 0.40),
      'remote': Offset(0.42, 0.58),
    },
    'bedroom': {
      'lamp': Offset(0.18, 0.38),
      'clock': Offset(0.72, 0.28),
      'mirror': Offset(0.82, 0.32),
      'pillow': Offset(0.38, 0.52),
      'frame': Offset(0.55, 0.30),
      'glass': Offset(0.62, 0.48),
    },
    'garage': {
      'can': Offset(0.22, 0.62),
      'toolbox': Offset(0.42, 0.58),
      'shelf': Offset(0.72, 0.35),
      'bulb': Offset(0.50, 0.22),
      'bucket': Offset(0.58, 0.65),
      'chair': Offset(0.35, 0.68),
    },
    'dining': {
      'plate': Offset(0.48, 0.52),
      'glass': Offset(0.38, 0.48),
      'chandelier': Offset(0.50, 0.18),
      'chair': Offset(0.28, 0.58),
      'table': Offset(0.50, 0.55),
      'vase': Offset(0.62, 0.46),
    },
    'hotel': {
      'minibar': Offset(0.78, 0.48),
      'glass': Offset(0.72, 0.52),
      'tv': Offset(0.22, 0.38),
      'lamp': Offset(0.15, 0.42),
      'tray': Offset(0.48, 0.50),
      'phone': Offset(0.55, 0.48),
    },
    'classroom': {
      'board': Offset(0.50, 0.28),
      'desk': Offset(0.35, 0.55),
      'chair': Offset(0.38, 0.62),
      'globe': Offset(0.72, 0.48),
      'books': Offset(0.62, 0.52),
      'apple': Offset(0.42, 0.50),
    },
    'locker': {
      'locker': Offset(0.35, 0.42),
      'bottle': Offset(0.55, 0.55),
      'bench': Offset(0.48, 0.62),
      'mirror': Offset(0.78, 0.32),
      'scale': Offset(0.22, 0.58),
      'towel': Offset(0.68, 0.48),
    },
    'cafe': {
      'cup': Offset(0.42, 0.50),
      'chair': Offset(0.28, 0.58),
      'table': Offset(0.45, 0.54),
      'pastry': Offset(0.52, 0.48),
      'sign': Offset(0.18, 0.30),
      'glass': Offset(0.48, 0.46),
    },
    'studio': {
      'fridge': Offset(0.18, 0.48),
      'bed': Offset(0.62, 0.52),
      'glass': Offset(0.48, 0.55),
      'lamp': Offset(0.38, 0.38),
      'speaker': Offset(0.72, 0.58),
      'plant': Offset(0.82, 0.45),
    },
    'gameroom': {
      'console': Offset(0.48, 0.58),
      'controller': Offset(0.42, 0.52),
      'tv': Offset(0.50, 0.32),
      'chair': Offset(0.35, 0.62),
      'snack': Offset(0.58, 0.50),
      'can': Offset(0.65, 0.55),
    },
    'laundry': {
      'washer': Offset(0.32, 0.52),
      'dryer': Offset(0.48, 0.52),
      'basket': Offset(0.22, 0.62),
      'detergent': Offset(0.58, 0.42),
      'iron': Offset(0.72, 0.48),
      'shelf': Offset(0.78, 0.32),
    },
    'balcony': {
      'plant': Offset(0.22, 0.55),
      'chair': Offset(0.42, 0.58),
      'glass': Offset(0.50, 0.52),
      'table': Offset(0.48, 0.55),
      'lantern': Offset(0.68, 0.42),
      'rail': Offset(0.50, 0.72),
    },
    'workshop': {
      'saw': Offset(0.35, 0.52),
      'bench': Offset(0.48, 0.58),
      'jar': Offset(0.62, 0.45),
      'radio': Offset(0.22, 0.42),
      'shelf': Offset(0.78, 0.35),
      'can': Offset(0.55, 0.65),
    },
    'penthouse': {
      'sculpture': Offset(0.28, 0.48),
      'glass': Offset(0.50, 0.52),
      'sofa': Offset(0.62, 0.50),
      'window': Offset(0.50, 0.28),
      'lamp': Offset(0.18, 0.42),
      'vase': Offset(0.72, 0.46),
    },
    'dorm': {
      'laptop': Offset(0.42, 0.50),
      'ramen': Offset(0.52, 0.48),
      'poster': Offset(0.22, 0.28),
      'chair': Offset(0.35, 0.58),
      'fridge': Offset(0.78, 0.48),
      'lamp': Offset(0.62, 0.38),
    },
    'server': {
      'rack': Offset(0.35, 0.42),
      'monitor': Offset(0.55, 0.48),
      'keyboard': Offset(0.52, 0.55),
      'cable': Offset(0.48, 0.62),
      'coffee': Offset(0.72, 0.52),
      'fan': Offset(0.82, 0.38),
    },
  };

  static Offset forProp({
    required String roomId,
    required String propId,
    required Alignment fallback,
  }) {
    final spot = _spots[roomId]?[propId];
    if (spot != null) return spot;
    return Offset((fallback.x + 1) / 2, (fallback.y + 1) / 2);
  }
}
