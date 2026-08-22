import 'package:flutter/material.dart';

import 'dramatic_fx.dart';

/// Shared FX lifecycle for all vent scenes — cuts repeated init/dispose boilerplate.
abstract class BaseVentSceneState<T extends StatefulWidget> extends State<T>
    with TickerProviderStateMixin {
  late final DramaticFxController fx = DramaticFxController();

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
