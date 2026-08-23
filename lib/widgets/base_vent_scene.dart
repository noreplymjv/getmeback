import 'package:flutter/material.dart';

import 'dramatic_fx.dart';

/// Shared FX lifecycle for all vent scenes — cuts repeated init/dispose boilerplate.
abstract class BaseVentSceneState<T extends StatefulWidget> extends State<T>
    with TickerProviderStateMixin {
  late final DramaticFxController fx = DramaticFxController();

  /// Heavy smash with automatic hit-stop.
  void heavySmash({required Offset at, Color? color}) {
    fx.megaImpact(at: at, color: color);
    fx.triggerHitStop(const Duration(milliseconds: 45));
  }

  @override
  void initState() {
    super.initState();
    fx.addListener(_onFxTick);
  }

  void _onFxTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    fx.removeListener(_onFxTick);
    fx.dispose();
    super.dispose();
  }
}
