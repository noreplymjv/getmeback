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
        PropMaterial.glass => 40,
        PropMaterial.ceramic => 28,
        PropMaterial.wood => 18,
        PropMaterial.metal => 24,
        PropMaterial.plastic => 22,
        PropMaterial.fabric => 14,
      };

  /// Micro freeze-frame length tuned per material (fighting-game style hit-stop).
  Duration get hitStop => switch (this) {
        PropMaterial.glass => const Duration(milliseconds: 28),
        PropMaterial.ceramic => const Duration(milliseconds: 36),
        PropMaterial.wood => const Duration(milliseconds: 32),
        PropMaterial.metal => const Duration(milliseconds: 42),
        PropMaterial.plastic => const Duration(milliseconds: 30),
        PropMaterial.fabric => const Duration(milliseconds: 22),
      };
}
