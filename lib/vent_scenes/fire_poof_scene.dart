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

class FirePoofScene extends StatefulWidget {
  const FirePoofScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<FirePoofScene> createState() => _FirePoofSceneState();
}

class _FirePoofSceneState extends BaseVentSceneState<FirePoofScene> {
  bool _burning = false;
  double _burnProgress = 0;
  late AnimationController _flameController;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  Future<void> _ignite(Size area) async {
    if (_burning) return;
    setState(() => _burning = true);
    final center = Offset(area.width / 2, area.height * 0.48);
    fx.fireBurst(at: center, count: 45);
    fx.comicPop(at: center, text: 'FWOOSH!', color: const Color(0xFFFF7043));

    for (var i = 1; i <= 25; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _burnProgress = i / 25);

      final emberAt = center.translate(
        (_rng.nextDouble() - 0.5) * 80,
        (_rng.nextDouble() - 0.5) * 60 - _burnProgress * 20,
      );
      fx.impact(
        at: emberAt,
        count: 10 + (i % 3) * 4,
        intensity: 0.55 + _burnProgress * 0.5,
        haptic: i.isEven,
        color: Color.lerp(
          const Color(0xFFFFD54F),
          const Color(0xFFE53935),
          _burnProgress,
        ),
      );
      if (i % 4 == 0) {
        fx.fireBurst(at: emberAt, count: 12);
        fx.smokeBurst(at: emberAt, count: 4);
      }
    }

    fx.megaImpact(at: center, color: const Color(0xFFFF7043));
    fx.smokeBurst(at: center, count: 18, color: Colors.grey.shade700);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Fire Poof',
        hint: _burning
            ? 'Poof! Gone in smoke 🔥'
            : 'Tap to set ablaze (cartoon style!)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            final scale = SceneScale(constraints);
            final avatarSize = scale.avatar(0.32);
            final flameBase = scale.prop(0.12);
            return GestureDetector(
              onTap: () => _ignite(area),
              child: VentFxLayer(
                fx: fx,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Opacity(
                        opacity: 1 - _burnProgress,
                        child: TargetAvatar(
                          target: widget.target,
                          size: avatarSize,
                          showLabel: false,
                        ),
                      ),
                      if (_burning)
                        ...List.generate(5, (i) {
                          return AnimatedBuilder(
                            animation: _flameController,
                            builder: (context, _) {
                              final offset = (i - 2) * (avatarSize * 0.2);
                              final height = flameBase +
                                  _flameController.value * flameBase * 0.7 +
                                  i * flameBase * 0.18;
                              return Positioned(
                                bottom: avatarSize * 0.5 + _burnProgress * 20,
                                left: offset,
                                child: Icon(
                                  Icons.local_fire_department,
                                  size: height,
                                  color: Color.lerp(
                                    Colors.orange,
                                    Colors.red,
                                    _flameController.value,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      if (_burnProgress > 0.7)
                        Text(
                          'POOF!',
                          style: TextStyle(
                            fontSize: scale.accent(0.085),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent.withValues(alpha: _burnProgress),
                          ),
                        ),
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
