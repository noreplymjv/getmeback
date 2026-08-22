import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/vent_sfx.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class BlackHoleScene extends StatefulWidget {
  const BlackHoleScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<BlackHoleScene> createState() => _BlackHoleSceneState();
}

class _BlackHoleSceneState extends BaseVentSceneState<BlackHoleScene> {
  late AnimationController _pulse;
  int _feeds = 0;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _feed(Offset center) {
    if (_gone) return;
    setState(() => _feeds++);
    VentSfx.instance.play(Sfx.suck);
    fx.swirlBurst(at: center, count: 24, color: const Color(0xFF7E57C2));
    if (_feeds >= 5) {
      setState(() => _gone = true);
      fx.megaImpact(at: center, color: const Color(0xFF7E57C2));
      Future.delayed(const Duration(milliseconds: 850), () {
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
        title: 'Black Hole',
        hint: _gone ? 'Consumed!' : 'Tap to feed the void! ($_feeds/5)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.48,
            );
            final scale = SceneScale(constraints);
            final avatarSize = scale.avatar(0.24);
            final hole = avatarSize * 0.85 + _feeds * avatarSize * 0.2;
            return GestureDetector(
              onTap: () => _feed(center),
              child: ventFxLayer(
                fx: fx,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final wobble = 1 + _pulse.value * 0.08;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: hole * wobble + avatarSize * 0.36,
                            height: hole * wobble + avatarSize * 0.36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7E57C2)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: hole * wobble,
                            height: hole * wobble,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.black,
                                  Color(0xFF311B92),
                                  Color(0xFF7E57C2),
                                ],
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _gone ? 0 : (1 - _feeds * 0.16).clamp(0.1, 1),
                            child: Opacity(
                              opacity: _gone ? 0 : 1,
                              child: TargetAvatar(
                                target: widget.target,
                                size: avatarSize,
                                showLabel: false,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
