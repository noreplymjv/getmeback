import 'dart:math';

import 'package:flutter/widgets.dart';

/// Sizes vent-scene art relative to the space the scene actually gets,
/// so props never dwarf the stage on small screens.
class SceneScale {
  SceneScale(BoxConstraints constraints)
      : _short = min(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 360,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 480,
        );

  factory SceneScale.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SceneScale(BoxConstraints.tight(size));
  }

  final double _short;

  /// The target/victim art.
  double avatar([double factor = 0.26]) =>
      (_short * factor).clamp(52.0, 88.0);

  /// Tools and props that hit the target (hammer, anvil, glove, dart).
  double prop([double factor = 0.14]) => (_short * factor).clamp(28.0, 52.0);

  /// Containers the target sits in (bin, sink, board, shredder tray).
  double container([double factor = 0.42]) =>
      (_short * factor).clamp(96.0, 168.0);

  /// Small accents (sparkles, icons, badges).
  double accent([double factor = 0.07]) => (_short * factor).clamp(16.0, 32.0);

  /// Vertical travel distance for drops and throws.
  double travel([double factor = 0.5]) => (_short * factor).clamp(80.0, 240.0);
}
