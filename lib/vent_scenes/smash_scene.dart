import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class SmashScene extends StatefulWidget {
  const SmashScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<SmashScene> createState() => _SmashSceneState();
}

class _SmashSceneState extends State<SmashScene>
    with TickerProviderStateMixin {
  int _hits = 0;
  int _cracks = 0;
  double _scale = 1;
  late final DramaticFxController _fx = DramaticFxController();
  late AnimationController _punchController;
  Offset? _lastHit;

  @override
  void initState() {
    super.initState();
    _punchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    _punchController.dispose();
    super.dispose();
  }

  void _onHit(Offset localPos, Size area) {
    final center = Offset(area.width / 2, area.height / 2 - 20);
    setState(() {
      _hits++;
      _cracks = (_hits / 2).floor().clamp(0, 8);
      _scale = 0.88;
      _lastHit = localPos == Offset.zero ? center : localPos;
    });
    _punchController.forward(from: 0).then((_) {
      if (mounted) setState(() => _scale = 1);
    });

    final intensity = (0.9 + (_hits / 10) * 1.0).clamp(0.9, 2.0);
    if (_hits % 4 == 0) {
      _fx.megaImpact(at: _lastHit!, color: AppTheme.accent);
    } else {
      _fx.impact(
        at: _lastHit!,
        count: 32 + _hits * 3,
        intensity: intensity,
        color: AppTheme.accent,
      );
    }

    if (_hits >= 10) {
      _fx.megaImpact(at: center, color: AppTheme.accent);
      _fx.confettiBurst(at: center, count: 80);
      _fx.crackerBurst(at: center, volleys: 5);
      _fx.glitterRain(at: center, count: 55);
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
        title: 'Smash Face',
        hint: _hits == 0
            ? 'Pound the face — make it shatter!'
            : 'BOOM ×$_hits — keep smashing!',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            final scale = SceneScale(constraints);
            final avatarSize = scale.avatar(0.4);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _onHit(d.localPosition, area),
              onPanUpdate: (d) {
                if (d.delta.distance > 6) {
                  _onHit(d.localPosition, area);
                }
              },
              child: ventFxLayer(
                fx: _fx,
                child: Center(
                  child: AnimatedScale(
                    scale: _scale,
                    duration: const Duration(milliseconds: 90),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_hits > 0)
                              ...List.generate(
                                min(_hits, 6),
                                (i) => Transform.translate(
                                  offset: Offset(
                                    sin(i * 1.7) * avatarSize * (0.14 + i * 0.05),
                                    cos(i * 1.3) * avatarSize * (0.1 + i * 0.03),
                                  ),
                                  child: Opacity(
                                    opacity: 0.35,
                                    child: TargetAvatar(
                                      target: widget.target,
                                      size: avatarSize * 0.55,
                                      showLabel: false,
                                      cracks: _cracks,
                                    ),
                                  ),
                                ),
                              ),
                            TargetAvatar(
                              target: widget.target,
                              size: avatarSize,
                              cracks: _cracks,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_cracks >= 2)
                          Text(
                            _cracks >= 6
                                ? 'TOTAL DESTRUCTION 💥💥💥'
                                : 'Cracking apart!!!',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: scale.accent(0.05),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: AppTheme.accent.withValues(alpha: 0.8),
                                  blurRadius: 12,
                                ),
                              ],
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
