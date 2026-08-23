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

class PunchBagScene extends StatefulWidget {
  const PunchBagScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<PunchBagScene> createState() => _PunchBagSceneState();
}

class _PunchBagSceneState extends BaseVentSceneState<PunchBagScene> {
  int _punches = 0;
  late AnimationController _swingController;

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  void _punch(Size area) {
    setState(() => _punches++);
    _swingController.forward(from: 0);

    final bagCenter = Offset(area.width / 2, area.height * 0.55);
    final intensity = (0.85 + (_punches / 10) * 0.75).clamp(0.85, 1.5);
    fx.impact(
      at: bagCenter,
      count: 22 + _punches * 3,
      intensity: intensity,
      color: AppTheme.accent,
    );

    if (_punches >= 10) {
      fx.confettiBurst(at: bagCenter, count: 60);
      fx.crackerBurst(at: bagCenter, volleys: 4);
      fx.glitterRain(at: bagCenter, count: 40);
      Future.delayed(const Duration(milliseconds: 800), () {
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
        title: 'Punch Bag',
        hint: 'Tap the bag to punch! ($_punches punches)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            final scale = SceneScale(constraints);
            final bagWidth = scale.container(0.4);
            return GestureDetector(
              onTap: () => _punch(area),
              child: VentFxLayer(
                fx: fx,
                child: AnimatedBuilder(
                  animation: _swingController,
                  builder: (context, child) {
                    final swing = sin(_swingController.value * pi) * 0.3;
                    return Transform.rotate(
                      angle: swing,
                      alignment: Alignment.topCenter,
                      child: child,
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: bagWidth * 0.42,
                          color: Colors.grey.shade600,
                        ),
                        Container(
                          width: bagWidth,
                          height: bagWidth * 1.28,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(bagWidth / 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Center(
                            child: TargetAvatar(
                              target: widget.target,
                              size: bagWidth * 0.6,
                              showLabel: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _punches >= 5 ? 'Keep going! 🥊' : 'POW!',
                          style: TextStyle(
                            fontSize: scale.accent(0.05),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentSecondary,
                          ),
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
