import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class SledgehammerScene extends StatefulWidget {
  const SledgehammerScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<SledgehammerScene> createState() => _SledgehammerSceneState();
}

class _SledgehammerSceneState extends BaseVentSceneState<SledgehammerScene> {
  int _smashes = 0;
  bool _swinging = false;
  late AnimationController _swingController;
  Offset _center = Offset.zero;

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  Future<void> _smash() async {
    if (_swinging) return;
    setState(() => _swinging = true);
    await _swingController.forward(from: 0);
    if (!mounted) return;
    fx.megaImpact(at: _center, color: AppTheme.accent);
    fx.comicPop(at: _center, color: AppTheme.accent);
    if (_smashes >= 3) {
      fx.crackerBurst(at: _center, volleys: 2, playSound: false);
    }
    setState(() {
      _smashes++;
      _swinging = false;
    });
    _swingController.reset();
    if (_smashes >= 5) {
      fx.crackerBurst(at: _center, volleys: 5);
      fx.glitterRain(at: _center, count: 50);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) context.go('/calm/${widget.target.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Sledgehammer',
        hint: _smashes >= 5
            ? 'Pulverized! 🔨'
            : 'Tap to swing the hammer! ($_smashes/5)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            final scale = SceneScale(constraints);
            final avatarSize = scale.avatar(0.32);
            _center = Offset(area.width / 2, area.height * 0.5);
            return VentFxLayer(
              fx: fx,
              child: GestureDetector(
                onTap: _smash,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 - _smashes * 0.12,
                      child: TargetAvatar(
                        target: widget.target,
                        size: avatarSize,
                        showLabel: false,
                        cracks: _smashes.clamp(0, 6),
                      ),
                    ),
                    if (_smashes > 0)
                      ...List.generate(_smashes, (i) {
                        return Positioned(
                          top: avatarSize * 0.5 + i * 8.0,
                          left: area.width * 0.2 + (i % 3) * (avatarSize * 0.22),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppTheme.accent.withValues(alpha: 0.6),
                            size: scale.accent(0.055),
                          ),
                        );
                      }),
                    AnimatedBuilder(
                      animation: _swingController,
                      builder: (context, child) {
                        final angle = -pi / 4 + _swingController.value * pi / 2;
                        return Positioned(
                          top: area.height * 0.12,
                          right: area.width * 0.12,
                          child: Transform.rotate(
                            angle: angle,
                            alignment: Alignment.bottomCenter,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.hardware,
                        size: scale.prop(0.2),
                        color: const Color(0xFF78909C),
                      ),
                    ),
                    if (_swinging)
                      Positioned(
                        bottom: avatarSize * 0.75,
                        child: Text(
                          'WHAM!',
                          style: TextStyle(
                            fontSize: scale.accent(0.07),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent.withValues(alpha: 0.8),
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
