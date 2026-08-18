import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class DartThrowScene extends StatefulWidget {
  const DartThrowScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<DartThrowScene> createState() => _DartThrowSceneState();
}

class _DartThrowSceneState extends State<DartThrowScene> {
  final List<Offset> _darts = [];
  int _hits = 0;
  late final DramaticFxController _fx = DramaticFxController();
  Offset _center = Offset.zero;

  @override
  void initState() {
    super.initState();
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    super.dispose();
  }

  void _throwDart(TapDownDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _darts.add(local);
      _hits++;
    });
    final dist = (local - _center).distance;
    final isBullseye = dist < 55;
    if (isBullseye) {
      _fx.megaImpact(at: local, color: AppTheme.accent);
    } else {
      _fx.impact(
        at: local,
        count: 18,
        color: AppTheme.accent,
        intensity: 0.8,
      );
    }
    if (_hits >= 8) {
      _fx.confettiBurst(at: _center, count: 70);
      _fx.crackerBurst(at: _center, volleys: 4);
      _fx.glitterRain(at: _center, count: 45);
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
        title: 'Dart Throw',
        hint: 'Tap anywhere to throw darts! ($_hits darts)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = SceneScale(constraints);
            final boardSize = scale.container(0.55);
            _center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            );
            return GestureDetector(
              onTapDown: _throwDart,
              child: ventFxLayer(
                fx: _fx,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: boardSize,
                      height: boardSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.calm, width: 4),
                        color: AppTheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Center(
                        child: TargetAvatar(
                          target: widget.target,
                          size: boardSize * 0.46,
                          showLabel: false,
                        ),
                      ),
                    ),
                    ..._darts.map(
                      (pos) => Positioned(
                        left: pos.dx - 12,
                        top: pos.dy - 12,
                        child: Transform.rotate(
                          angle: -pi / 4,
                          child: Icon(
                            Icons.push_pin,
                            size: scale.accent(0.055),
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
