import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/vent_sfx.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class TornadoScene extends StatefulWidget {
  const TornadoScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<TornadoScene> createState() => _TornadoSceneState();
}

class _TornadoSceneState extends State<TornadoScene>
    with SingleTickerProviderStateMixin {
  late final DramaticFxController _fx = DramaticFxController();
  late AnimationController _spin;
  int _gusts = 0;
  bool _sucked = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _gust(Offset center) {
    if (_sucked) return;
    setState(() => _gusts++);
    _spin.duration = Duration(milliseconds: (900 - _gusts * 110).clamp(180, 900));
    _spin.repeat();
    _fx.swirlBurst(at: center, count: 28 + _gusts * 6, color: AppTheme.accentSecondary);
    if (_gusts >= 6) {
      setState(() => _sucked = true);
      VentSfx.instance.play(Sfx.suck);
      _fx.megaImpact(at: center, color: AppTheme.accentSecondary);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Tornado Spin',
        hint: _sucked ? 'Gone with the wind!' : 'Tap to spin the tornado! ($_gusts/6)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.48,
            );
            return GestureDetector(
              onTap: () => _gust(center),
              child: ventFxLayer(
                fx: _fx,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, child) {
                      final t = _spin.value * pi * 2;
                      final lift = _sucked ? -180.0 : _gusts * -8.0;
                      final scale = _sucked ? 0.05 : 1 - _gusts * 0.08;
                      return Transform.translate(
                        offset: Offset(sin(t) * (18 + _gusts * 4.0), lift),
                        child: Transform.rotate(
                          angle: t * (1 + _gusts * 0.4),
                          child: Transform.scale(
                            scale: scale.clamp(0.05, 1.0),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cyclone,
                          size: 72 + _gusts * 6,
                          color: AppTheme.accentSecondary.withValues(alpha: 0.7),
                        ),
                        TargetAvatar(
                          target: widget.target,
                          size: 120,
                          showLabel: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
