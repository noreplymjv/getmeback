import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class PaintBombScene extends StatefulWidget {
  const PaintBombScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<PaintBombScene> createState() => _PaintBombSceneState();
}

class _PaintBombSceneState extends BaseVentSceneState<PaintBombScene> {
  int _splats = 0;
  final _rng = Random();
  static const _paints = [
    Color(0xFFFF6B4A),
    Color(0xFFFFD54F),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFCE93D8),
    Color(0xFFFF4081),
  ];

  void _splash(Offset at, Offset center) {
    if (_splats >= 8) return;
    setState(() => _splats++);
    final color = _paints[_rng.nextInt(_paints.length)];
    fx.dripBurst(at: at, count: 28, color: color);
    fx.impact(at: at, count: 18, color: color, intensity: 0.85, comic: false);
    fx.comicPop(at: at, text: 'SPLAT!', color: color);
    if (_splats >= 8) {
      fx.confettiBurst(at: center, count: 80);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Paint Bomb',
        hint: _splats >= 8 ? 'Covered!' : 'Tap to throw paint bombs! ($_splats/8)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = SceneScale(constraints);
            final avatarSize = scale.avatar(0.32);
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.45,
            );
            return GestureDetector(
              onTapDown: (d) => _splash(d.localPosition, center),
              child: ventFxLayer(
                fx: fx,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TargetAvatar(
                        target: widget.target,
                        size: avatarSize,
                        showLabel: false,
                        opacity: 1 - _splats * 0.08,
                      ),
                      ...List.generate(_splats, (i) {
                        final color = _paints[i % _paints.length];
                        return Transform.translate(
                          offset: Offset(
                            sin(i * 1.7) * avatarSize * 0.3,
                            cos(i * 2.1) * avatarSize * 0.27,
                          ),
                          child: Container(
                            width: avatarSize * (0.26 + (i % 3) * 0.07),
                            height: avatarSize * (0.2 + (i % 2) * 0.08),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }),
                    ],
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
