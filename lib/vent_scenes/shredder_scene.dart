import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class ShredderScene extends StatefulWidget {
  const ShredderScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<ShredderScene> createState() => _ShredderSceneState();
}

class _ShredderSceneState extends BaseVentSceneState<ShredderScene> {
  bool _shredding = false;
  double _shredProgress = 0;
  late AnimationController _bladeController;
  Offset _center = Offset.zero;

  @override
  void initState() {
    super.initState();
    _bladeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _bladeController.dispose();
    super.dispose();
  }

  Future<void> _shred() async {
    if (_shredding) return;
    setState(() => _shredding = true);
    fx.impact(at: _center, intensity: 1.2);
    fx.comicPop(at: _center, text: 'RRRRIP!');
    _bladeController.repeat();
    for (var i = 1; i <= 25; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() => _shredProgress = i / 25);
      if (i % 4 == 0) {
        fx.debrisRain(
          at: Offset(_center.dx, _center.dy + 60),
          count: 12,
          color: AppTheme.accent.withValues(alpha: 0.8),
        );
        fx.impact(
          at: Offset(_center.dx, _center.dy + 40),
          count: 15,
          intensity: 0.7,
          comic: false,
        );
      }
    }
    _bladeController.stop();
    fx.megaImpact(at: Offset(_center.dx, _center.dy + 80));
    fx.debrisRain(at: Offset(_center.dx, _center.dy + 80), count: 35);
    fx.crackerBurst(at: Offset(_center.dx, _center.dy + 80), volleys: 4);
    fx.glitterRain(at: Offset(_center.dx, _center.dy + 80), count: 40);
    if (mounted) {
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
        title: 'Paper Shredder',
        hint: _shredding ? 'Shredded! 📄' : 'Drop the target into the shredder!',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = SceneScale(constraints);
            final trayWidth = scale.container(0.5);
            final avatarSize = scale.avatar(0.24);
            _center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.35,
            );
            return VentFxLayer(
              fx: fx,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: constraints.maxHeight * 0.16,
                    child: Column(
                      children: [
                        Container(
                          width: trayWidth,
                          height: trayWidth * 0.15,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AnimatedBuilder(
                            animation: _bladeController,
                            builder: (context, _) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(8, (i) {
                                  return Transform.rotate(
                                    angle: _bladeController.value * 6.28 + i,
                                    child: const Icon(
                                      Icons.content_cut,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: trayWidth * 0.9,
                          height: trayWidth * 0.6,
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                          ),
                          child: _shredProgress > 0.5
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: List.generate(6, (i) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 2,
                                      ),
                                      height: 4,
                                      color: AppTheme.accent.withValues(alpha: 0.4),
                                    );
                                  }),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.12 +
                        _shredProgress * constraints.maxHeight * 0.35,
                    child: Transform.scale(
                      scale: 1 - _shredProgress * 0.8,
                      child: Opacity(
                        opacity: 1 - _shredProgress,
                        child: _shredding
                            ? TargetAvatar(
                                target: widget.target,
                                size: avatarSize * 0.9,
                                showLabel: false,
                              )
                            : Draggable(
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: TargetAvatar(
                                    target: widget.target,
                                    size: avatarSize * 0.8,
                                    showLabel: false,
                                  ),
                                ),
                                onDragEnd: (details) {
                                  if (details.offset.dy > 100) _shred();
                                },
                                child: TargetAvatar(
                                  target: widget.target,
                                  size: avatarSize,
                                  showLabel: false,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
