import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class PinataScene extends StatefulWidget {
  const PinataScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<PinataScene> createState() => _PinataSceneState();
}

class _PinataSceneState extends State<PinataScene>
    with SingleTickerProviderStateMixin {
  int _hits = 0;
  bool _broken = false;
  late AnimationController _swingController;
  late final DramaticFxController _fx = DramaticFxController();
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    _swingController.dispose();
    super.dispose();
  }

  void _hit(Size area) {
    final pinataCenter = Offset(area.width / 2, area.height * 0.52);
    setState(() => _hits++);

    final intensity = (0.75 + (_hits / 6) * 0.9).clamp(0.75, 1.5);
    _fx.impact(
      at: pinataCenter,
      count: 18 + _hits * 4,
      intensity: intensity,
      color: AppTheme.accent,
    );

    if (_hits >= 6) {
      setState(() => _broken = true);
      _swingController.stop();
      _fx.confettiBurst(at: pinataCenter, count: 80);
      _fx.crackerBurst(at: pinataCenter, volleys: 5);
      _fx.glitterRain(at: pinataCenter, count: 55);
      Future.delayed(const Duration(milliseconds: 1200), () {
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
        title: 'Piñata',
        hint: _broken
            ? 'Candy explosion! 🎉'
            : 'Tap to whack the piñata! ($_hits/6)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            final scale = SceneScale(constraints);
            final potWidth = scale.container(0.4);
            return GestureDetector(
              onTap: () => _hit(area),
              child: ventFxLayer(
                fx: _fx,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_broken)
                      AnimatedBuilder(
                        animation: _swingController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: sin(_swingController.value * pi) * 0.15,
                            alignment: Alignment.topCenter,
                            child: child,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: potWidth * 0.42,
                              color: Colors.brown.shade400,
                            ),
                            Container(
                              width: potWidth,
                              height: potWidth * 1.28,
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.accent,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: TargetAvatar(
                                  target: widget.target,
                                  size: potWidth * 0.56,
                                  showLabel: false,
                                  cracks: (_hits / 2).floor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_broken)
                      SizedBox(
                        width: potWidth * 1.8,
                        height: potWidth * 1.8,
                        child: Stack(
                          alignment: Alignment.center,
                          children: List.generate(16, (i) {
                            final angle = i * pi / 8;
                            final dist = potWidth *
                                (0.28 + _random.nextDouble() * 0.56);
                            return Transform.translate(
                              offset: Offset(
                                cos(angle) * dist,
                                sin(angle) * dist,
                              ),
                              child: Icon(
                                [
                                  Icons.star,
                                  Icons.celebration,
                                  Icons.cake,
                                ][i % 3],
                                color: [
                                  AppTheme.accent,
                                  AppTheme.accentSecondary,
                                  AppTheme.calm,
                                  Colors.yellow,
                                ][i % 4],
                                size: scale.accent(0.045) +
                                    _random.nextDouble() * 16,
                              ),
                            );
                          }),
                        ),
                      ),
                    if (!_broken)
                      Positioned(
                        top: area.height * 0.1,
                        child: Icon(
                          Icons.sports_cricket,
                          size: scale.prop(0.12),
                          color: Colors.brown.shade300,
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
