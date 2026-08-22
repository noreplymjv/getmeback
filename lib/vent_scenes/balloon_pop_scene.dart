import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../services/vent_sfx.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class BalloonPopScene extends StatefulWidget {
  const BalloonPopScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<BalloonPopScene> createState() => _BalloonPopSceneState();
}

class _BalloonPopSceneState extends BaseVentSceneState<BalloonPopScene> {
  bool _popped = false;

  void _pop(Offset center) {
    if (_popped) return;
    setState(() => _popped = true);
    VentSfx.instance.play(Sfx.pop);
    fx.megaImpact(at: center, color: AppTheme.accent);
    fx.confettiBurst(at: center, count: 90);
    fx.crackerBurst(at: center, volleys: 5);
    fx.glitterRain(at: center, count: 55);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/calm/${widget.target.id}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Balloon Pop',
        hint: _popped ? 'POP! 💥' : 'Tap the balloon to pop it!',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.42,
            );
            return GestureDetector(
              onTap: () => _pop(center),
              child: ventFxLayer(
                fx: fx,
                child: Center(
                  child: AnimatedScale(
                    scale: _popped ? 2.8 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: _popped ? 0 : 1,
                      duration: const Duration(milliseconds: 350),
                      child: _buildBalloon(SceneScale(constraints)),
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

  Widget _buildBalloon(SceneScale scale) {
    final balloonWidth = scale.container(0.42);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: balloonWidth,
          height: balloonWidth * 1.25,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accent, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.4),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: TargetAvatar(
              target: widget.target,
              size: balloonWidth * 0.56,
              showLabel: false,
            ),
          ),
        ),
        Container(
          width: 2,
          height: balloonWidth * 0.5,
          color: Colors.grey.shade500,
        ),
      ],
    );
  }
}
