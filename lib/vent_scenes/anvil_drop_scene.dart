import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/vent_sfx.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class AnvilDropScene extends StatefulWidget {
  const AnvilDropScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<AnvilDropScene> createState() => _AnvilDropSceneState();
}

class _AnvilDropSceneState extends BaseVentSceneState<AnvilDropScene> {
  late AnimationController _drop;
  int _drops = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _drop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  Future<void> _dropAnvil(Offset center) async {
    if (_done) return;
    VentSfx.instance.play(Sfx.whoosh);
    await _drop.forward(from: 0);
    setState(() => _drops++);
    VentSfx.instance.play(Sfx.boom);
    if (_drops >= 3) {
      fx.megaImpact(at: center);
      fx.debrisRain(at: center, count: 40);
      fx.comicPop(at: center, text: 'SPLAT!');
      setState(() => _done = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go('/calm/${widget.target.id}');
    } else {
      fx.impact(at: center, count: 40, intensity: 1.3);
    }
    _drop.reset();
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Anvil Drop',
        hint: _done ? 'Flattened!' : 'Tap to drop the anvil! ($_drops/3)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = SceneScale(constraints);
            final anvilSize = scale.prop(0.2);
            final dropFrom = scale.travel(0.42);
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.55,
            );
            return GestureDetector(
              onTap: () => _dropAnvil(center),
              child: VentFxLayer(
                fx: fx,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scaleY: (1 - _drops * 0.22).clamp(0.28, 1.0),
                      child: TargetAvatar(
                        target: widget.target,
                        size: scale.avatar(0.3),
                        showLabel: false,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _drop,
                      builder: (context, child) {
                        final y = -dropFrom +
                            Curves.easeIn.transform(_drop.value) *
                                (dropFrom + anvilSize * 0.6);
                        return Transform.translate(
                          offset: Offset(0, y),
                          child: Opacity(
                            opacity: _drop.value == 0 ? 0.35 : 1,
                            child: child,
                          ),
                        );
                      },
                      child: CustomPaint(
                        size: Size(anvilSize * 1.25, anvilSize),
                        painter: _AnvilPainter(),
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

class _AnvilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9AA7B1), Color(0xFF4A5560)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path()
      ..moveTo(w * 0.06, h * 0.16)
      ..lineTo(w * 0.94, h * 0.16)
      ..lineTo(w * 0.8, h * 0.42)
      ..lineTo(w * 0.62, h * 0.42)
      ..lineTo(w * 0.62, h * 0.72)
      ..lineTo(w * 0.82, h)
      ..lineTo(w * 0.18, h)
      ..lineTo(w * 0.38, h * 0.72)
      ..lineTo(w * 0.38, h * 0.42)
      ..lineTo(w * 0.2, h * 0.42)
      ..close();
    canvas.drawShadow(path, const Color(0xAA000000), 6, false);
    canvas.drawPath(path, body);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.1, w * 0.88, h * 0.12),
        Radius.circular(h * 0.06),
      ),
      Paint()..color = const Color(0xFFC3CDD6),
    );
  }

  @override
  bool shouldRepaint(covariant _AnvilPainter oldDelegate) => false;
}
