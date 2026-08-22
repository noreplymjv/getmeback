import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class LightningScene extends StatefulWidget {
  const LightningScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<LightningScene> createState() => _LightningSceneState();
}

class _LightningSceneState extends BaseVentSceneState<LightningScene> {
  int _zaps = 0;
  bool _zapping = false;
  final _random = Random();
  Offset _center = Offset.zero;

  Future<void> _zap() async {
    if (_zapping || _zaps >= 4) return;
    setState(() => _zapping = true);
    fx.electricBurst(at: _center);
    for (var i = 0; i < 6; i++) {
      await Future.delayed(Duration(milliseconds: 60 + _random.nextInt(80)));
      if (!mounted) return;
      setState(() {});
    }
    if (!mounted) return;
    setState(() {
      _zaps++;
      _zapping = false;
    });
    if (_zaps >= 4) {
      fx.megaImpact(at: _center, color: Colors.yellowAccent);
      fx.crackerBurst(at: _center, volleys: 5);
      fx.glitterRain(at: _center, count: 48);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go('/calm/${widget.target.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Lightning Zap',
        hint: _zaps >= 4
            ? 'Zapped to ashes! ⚡'
            : 'Tap to call down lightning! ($_zaps/4)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            final scale = SceneScale(constraints);
            final avatarSize = scale.avatar(0.32);
            _center = Offset(area.width / 2, area.height * 0.5);
            return ventFxLayer(
              fx: fx,
              child: GestureDetector(
                onTap: _zap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_zapping)
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    Opacity(
                      opacity: 1 - _zaps * 0.2,
                      child: TargetAvatar(
                        target: widget.target,
                        size: avatarSize,
                        showLabel: false,
                      ),
                    ),
                    if (_zapping)
                      CustomPaint(
                        size: Size(avatarSize * 1.2, area.height * 0.6),
                        painter: _LightningBoltPainter(
                          seed: _random.nextInt(1000),
                        ),
                      ),
                    ...List.generate(_zaps, (i) {
                      return Positioned(
                        top: area.height * 0.16 + i * (avatarSize * 0.12),
                        child: Icon(
                          Icons.flash_on,
                          color: Colors.yellow.shade300,
                          size: scale.accent(0.08) + i * 5.0,
                        ),
                      );
                    }),
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

class _LightningBoltPainter extends CustomPainter {
  _LightningBoltPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()
      ..color = Colors.yellow.shade400
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(size.width / 2, 0);
    var x = size.width / 2;
    var y = 0.0;
    while (y < size.height * 0.7) {
      x += (random.nextDouble() - 0.5) * 40;
      y += 20 + random.nextDouble() * 30;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    final glow = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.3)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glow);
  }

  @override
  bool shouldRepaint(covariant _LightningBoltPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
