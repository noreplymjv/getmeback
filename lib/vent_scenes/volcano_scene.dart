import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/vent_sfx.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class VolcanoScene extends StatefulWidget {
  const VolcanoScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<VolcanoScene> createState() => _VolcanoSceneState();
}

class _VolcanoSceneState extends BaseVentSceneState<VolcanoScene> {
  late AnimationController _rumble;
  int _stokes = 0;
  bool _erupted = false;

  @override
  void initState() {
    super.initState();
    _rumble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rumble.dispose();
    super.dispose();
  }

  void _stoke(Offset center) {
    if (_erupted) return;
    setState(() => _stokes++);
    fx.fireBurst(at: Offset(center.dx, center.dy + 40), count: 16 + _stokes * 4);
    if (_stokes >= 5) {
      setState(() => _erupted = true);
      VentSfx.instance.play(Sfx.boom);
      fx.megaImpact(at: center, color: const Color(0xFFFF6E40));
      fx.fireBurst(at: center, count: 50);
      fx.smokeBurst(at: center, count: 16);
      Future.delayed(const Duration(milliseconds: 1000), () {
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
        title: 'Volcano Erupt',
        hint: _erupted ? 'ERUPTION!' : 'Tap to stoke the volcano! ($_stokes/5)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = SceneScale(constraints);
            final mountainWidth = scale.container(0.62);
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.42,
            );
            return GestureDetector(
              onTap: () => _stoke(center),
              child: ventFxLayer(
                fx: fx,
                child: AnimatedBuilder(
                  animation: _rumble,
                  builder: (context, child) {
                    final shake = _stokes * 2.5 * (_rumble.value - 0.5);
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: constraints.maxHeight * 0.14,
                        child: CustomPaint(
                          size: Size(mountainWidth, mountainWidth * 0.62),
                          painter: _VolcanoPainter(heat: _stokes / 5),
                        ),
                      ),
                      Positioned(
                        bottom: constraints.maxHeight * 0.14 +
                            mountainWidth * 0.55 +
                            (_erupted ? scale.travel(0.5) : 0),
                        child: Opacity(
                          opacity: _erupted ? 0.2 : 1,
                          child: TargetAvatar(
                            target: widget.target,
                            size: scale.avatar(0.22),
                            showLabel: false,
                          ),
                        ),
                      ),
                      if (_erupted)
                        Positioned(
                          top: constraints.maxHeight * 0.08,
                          child: Text(
                            'KABOOM!',
                            style: TextStyle(
                              fontSize: scale.accent(0.085),
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFFD54F),
                            ),
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

class _VolcanoPainter extends CustomPainter {
  _VolcanoPainter({required this.heat});

  final double heat;

  @override
  void paint(Canvas canvas, Size size) {
    final mountain = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.38, size.height * 0.18)
      ..lineTo(size.width * 0.62, size.height * 0.18)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()..color = Color.lerp(const Color(0xFF5D4037), const Color(0xFFBF360C), heat)!,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.2),
        width: 48,
        height: 18,
      ),
      Paint()..color = Color.lerp(const Color(0xFF3E2723), const Color(0xFFFF6E40), heat)!,
    );
  }

  @override
  bool shouldRepaint(covariant _VolcanoPainter oldDelegate) =>
      oldDelegate.heat != heat;
}
