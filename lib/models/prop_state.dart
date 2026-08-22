import '../widgets/prop_shatter_fx.dart';

/// Physical material for prop-specific debris and audio.
enum PropMaterial {
  glass,
  ceramic,
  wood,
  metal,
  plastic,
  fabric,
}

extension PropMaterialShatter on PropMaterial {
  PropShatterStyle get shatterStyle => switch (this) {
        PropMaterial.glass => PropShatterStyle.glass,
        PropMaterial.ceramic => PropShatterStyle.ceramic,
        PropMaterial.wood => PropShatterStyle.wood,
        PropMaterial.metal => PropShatterStyle.metal,
        PropMaterial.plastic => PropShatterStyle.ceramic,
        PropMaterial.fabric => PropShatterStyle.ceramic,
      };

  int get shardCount => switch (this) {
        PropMaterial.glass => 32,
        PropMaterial.ceramic => 24,
        PropMaterial.wood => 18,
        PropMaterial.metal => 22,
        PropMaterial.plastic => 20,
        PropMaterial.fabric => 14,
      };
}
