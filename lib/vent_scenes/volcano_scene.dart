import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/vent_sfx.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class VolcanoScene extends StatefulWidget {
  const VolcanoScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<VolcanoScene> createState() => _VolcanoSceneState();
}

class _VolcanoSceneState extends State<VolcanoScene>
    with SingleTickerProviderStateMixin {
  late final DramaticFxController _fx = DramaticFxController();
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
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    _rumble.dispose();
    super.dispose();
  }

  void _stoke(Offset center) {
    if (_erupted) return;
    setState(() => _stokes++);
    _fx.fireBurst(at: Offset(center.dx, center.dy + 40), count: 16 + _stokes * 4);
    if (_stokes >= 5) {
      setState(() => _erupted = true);
      VentSfx.instance.play(Sfx.boom);
      _fx.megaImpact(at: center, color: const Color(0xFFFF6E40));
      _fx.fireBurst(at: center, count: 50);
      _fx.smokeBurst(at: center, count: 16);
      Future.delayed(const Duration(milliseconds: 1000), () {
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
        title: 'Volcano Erupt',
        hint: _erupted ? 'ERUPTION!' : 'Tap to stoke the volcano! ($_stokes/5)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.42,
            );
            return GestureDetector(
              onTap: () => _stoke(center),
              child: ventFxLayer(
                fx: _fx,
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
                        bottom: 70,
                        child: CustomPaint(
                          size: const Size(260, 160),
                          painter: _VolcanoPainter(heat: _stokes / 5),
                        ),
                      ),
                      Positioned(
                        bottom: 180 + (_erupted ? 220.0 : 0),
                        child: Opacity(
                          opacity: _erupted ? 0.2 : 1,
                          child: TargetAvatar(
                            target: widget.target,
                            size: 100,
                            showLabel: false,
                          ),
                        ),
                      ),
                      if (_erupted)
                        const Positioned(
                          top: 40,
                          child: Text(
                            'KABOOM!',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD54F),
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
