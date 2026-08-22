import 'prop_state.dart';

/// Default sprite layout + material for every smashable prop id.
class PropSpriteCatalog {
  PropSpriteCatalog._();

  static const _layout = <String, ({double sizeNorm, double aspectRatio, int zIndex})>{
    'apple': (sizeNorm: 0.07, aspectRatio: 1.0, zIndex: 3),
    'basket': (sizeNorm: 0.14, aspectRatio: 1.0, zIndex: 1),
    'bed': (sizeNorm: 0.32, aspectRatio: 0.65, zIndex: 0),
    'bench': (sizeNorm: 0.22, aspectRatio: 0.45, zIndex: 1),
    'blender': (sizeNorm: 0.11, aspectRatio: 1.25, zIndex: 2),
    'board': (sizeNorm: 0.38, aspectRatio: 0.55, zIndex: 0),
    'books': (sizeNorm: 0.12, aspectRatio: 0.8, zIndex: 2),
    'bottle': (sizeNorm: 0.08, aspectRatio: 1.4, zIndex: 3),
    'bucket': (sizeNorm: 0.12, aspectRatio: 1.1, zIndex: 2),
    'bulb': (sizeNorm: 0.07, aspectRatio: 1.0, zIndex: 3),
    'cable': (sizeNorm: 0.16, aspectRatio: 0.35, zIndex: 2),
    'can': (sizeNorm: 0.09, aspectRatio: 1.2, zIndex: 2),
    'chair': (sizeNorm: 0.16, aspectRatio: 1.15, zIndex: 1),
    'chandelier': (sizeNorm: 0.18, aspectRatio: 1.4, zIndex: 0),
    'clock': (sizeNorm: 0.08, aspectRatio: 1.0, zIndex: 3),
    'coffee': (sizeNorm: 0.08, aspectRatio: 1.05, zIndex: 3),
    'console': (sizeNorm: 0.14, aspectRatio: 0.55, zIndex: 2),
    'controller': (sizeNorm: 0.08, aspectRatio: 0.65, zIndex: 3),
    'cup': (sizeNorm: 0.09, aspectRatio: 1.05, zIndex: 3),
    'desk': (sizeNorm: 0.28, aspectRatio: 0.55, zIndex: 0),
    'detergent': (sizeNorm: 0.09, aspectRatio: 1.3, zIndex: 3),
    'dryer': (sizeNorm: 0.18, aspectRatio: 1.1, zIndex: 1),
    'fan': (sizeNorm: 0.12, aspectRatio: 1.0, zIndex: 2),
    'frame': (sizeNorm: 0.10, aspectRatio: 0.75, zIndex: 2),
    'fridge': (sizeNorm: 0.16, aspectRatio: 1.35, zIndex: 1),
    'glass': (sizeNorm: 0.08, aspectRatio: 1.35, zIndex: 3),
    'globe': (sizeNorm: 0.11, aspectRatio: 1.0, zIndex: 2),
    'iron': (sizeNorm: 0.10, aspectRatio: 1.1, zIndex: 2),
    'jar': (sizeNorm: 0.08, aspectRatio: 1.2, zIndex: 3),
    'keyboard': (sizeNorm: 0.14, aspectRatio: 0.35, zIndex: 2),
    'lamp': (sizeNorm: 0.10, aspectRatio: 1.2, zIndex: 2),
    'lantern': (sizeNorm: 0.09, aspectRatio: 1.15, zIndex: 3),
    'laptop': (sizeNorm: 0.14, aspectRatio: 0.65, zIndex: 2),
    'locker': (sizeNorm: 0.22, aspectRatio: 1.4, zIndex: 0),
    'logs': (sizeNorm: 0.16, aspectRatio: 0.45, zIndex: 1),
    'minibar': (sizeNorm: 0.14, aspectRatio: 1.2, zIndex: 1),
    'mirror': (sizeNorm: 0.16, aspectRatio: 1.25, zIndex: 1),
    'monitor': (sizeNorm: 0.18, aspectRatio: 0.85, zIndex: 2),
    'mug': (sizeNorm: 0.09, aspectRatio: 1.05, zIndex: 3),
    'phone': (sizeNorm: 0.07, aspectRatio: 1.4, zIndex: 3),
    'pillow': (sizeNorm: 0.12, aspectRatio: 0.75, zIndex: 2),
    'plant': (sizeNorm: 0.12, aspectRatio: 1.1, zIndex: 2),
    'plate': (sizeNorm: 0.14, aspectRatio: 0.35, zIndex: 2),
    'poster': (sizeNorm: 0.14, aspectRatio: 0.75, zIndex: 1),
    'pastry': (sizeNorm: 0.08, aspectRatio: 0.85, zIndex: 3),
    'rack': (sizeNorm: 0.22, aspectRatio: 1.35, zIndex: 0),
    'radio': (sizeNorm: 0.09, aspectRatio: 0.85, zIndex: 2),
    'rail': (sizeNorm: 0.34, aspectRatio: 0.25, zIndex: 0),
    'ramen': (sizeNorm: 0.09, aspectRatio: 0.95, zIndex: 3),
    'remote': (sizeNorm: 0.07, aspectRatio: 0.45, zIndex: 3),
    'saw': (sizeNorm: 0.14, aspectRatio: 0.55, zIndex: 2),
    'scale': (sizeNorm: 0.10, aspectRatio: 1.0, zIndex: 2),
    'sculpture': (sizeNorm: 0.12, aspectRatio: 1.3, zIndex: 2),
    'shelf': (sizeNorm: 0.20, aspectRatio: 0.45, zIndex: 0),
    'sign': (sizeNorm: 0.12, aspectRatio: 0.85, zIndex: 1),
    'snack': (sizeNorm: 0.08, aspectRatio: 0.9, zIndex: 3),
    'soap': (sizeNorm: 0.08, aspectRatio: 0.75, zIndex: 3),
    'sofa': (sizeNorm: 0.28, aspectRatio: 0.55, zIndex: 0),
    'speaker': (sizeNorm: 0.10, aspectRatio: 0.85, zIndex: 2),
    'table': (sizeNorm: 0.38, aspectRatio: 0.55, zIndex: 0),
    'toilet': (sizeNorm: 0.14, aspectRatio: 1.0, zIndex: 1),
    'toolbox': (sizeNorm: 0.12, aspectRatio: 0.85, zIndex: 2),
    'towel': (sizeNorm: 0.14, aspectRatio: 0.65, zIndex: 2),
    'tray': (sizeNorm: 0.12, aspectRatio: 0.45, zIndex: 2),
    'tv': (sizeNorm: 0.22, aspectRatio: 0.75, zIndex: 1),
    'vase': (sizeNorm: 0.10, aspectRatio: 1.25, zIndex: 3),
    'washer': (sizeNorm: 0.18, aspectRatio: 1.05, zIndex: 1),
    'window': (sizeNorm: 0.22, aspectRatio: 1.1, zIndex: 0),
  };

  static const _defaultLayout = (
    sizeNorm: 0.11,
    aspectRatio: 1.0,
    zIndex: 1,
  );

  static double sizeNormFor(String propId) =>
      (_layout[propId] ?? _defaultLayout).sizeNorm;

  static double aspectRatioFor(String propId) =>
      (_layout[propId] ?? _defaultLayout).aspectRatio;

  static int zIndexFor(String propId) =>
      (_layout[propId] ?? _defaultLayout).zIndex;

  static PropMaterial materialFor(String propId) {
    switch (propId) {
      case 'glass':
      case 'mirror':
      case 'window':
      case 'bulb':
      case 'bottle':
        return PropMaterial.glass;
      case 'plate':
      case 'mug':
      case 'cup':
      case 'vase':
      case 'soap':
      case 'jar':
      case 'toilet':
      case 'globe':
      case 'clock':
      case 'frame':
      case 'sculpture':
      case 'apple':
      case 'pastry':
      case 'ramen':
      case 'detergent':
        return PropMaterial.ceramic;
      case 'chair':
      case 'table':
      case 'desk':
      case 'bench':
      case 'logs':
      case 'shelf':
      case 'board':
      case 'sign':
      case 'poster':
      case 'rail':
      case 'saw':
        return PropMaterial.wood;
      case 'blender':
      case 'monitor':
      case 'keyboard':
      case 'lamp':
      case 'lantern':
      case 'tv':
      case 'phone':
      case 'iron':
      case 'toolbox':
      case 'can':
      case 'bucket':
      case 'washer':
      case 'dryer':
      case 'fridge':
      case 'minibar':
      case 'locker':
      case 'rack':
      case 'fan':
      case 'radio':
      case 'speaker':
      case 'console':
      case 'controller':
      case 'laptop':
      case 'chandelier':
      case 'scale':
        return PropMaterial.metal;
      case 'sofa':
      case 'bed':
      case 'pillow':
      case 'towel':
      case 'basket':
      case 'cable':
      case 'books':
      case 'tray':
      case 'snack':
      case 'coffee':
        return PropMaterial.fabric;
      default:
        return PropMaterial.plastic;
    }
  }
}
