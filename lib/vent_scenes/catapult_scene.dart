import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class CatapultScene extends StatefulWidget {
  const CatapultScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<CatapultScene> createState() => _CatapultSceneState();
}

class _CatapultSceneState extends State<CatapultScene>
    with SingleTickerProviderStateMixin {
  bool _launched = false;
  late AnimationController _launchController;

  @override
  void initState() {
    super.initState();
    _launchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _launchController.dispose();
    super.dispose();
  }

  Future<void> _launch() async {
    if (_launched) return;
    setState(() => _launched = true);
    await _launchController.forward();
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Catapult',
      hint: _launched ? 'YEET! 🚀' : 'Drag back and release to launch!',
      showTarget: false,
      child: GestureDetector(
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy < -200) _launch();
        },
        onTap: _launch,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 80,
              child: CustomPaint(
                size: const Size(200, 100),
                painter: _CatapultPainter(),
              ),
            ),
            AnimatedBuilder(
              animation: _launchController,
              builder: (context, child) {
                final t = Curves.easeOut.transform(_launchController.value);
                final x = sin(t * pi) * 180;
                final y = -sin(t * pi) * 280 + t * 100;
                final rotation = t * pi * 2;
                final opacity = 1 - t * 0.8;
                return Transform.translate(
                  offset: Offset(x, y),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Opacity(opacity: opacity, child: child),
                  ),
                );
              },
              child: TargetAvatar(
                target: widget.target,
                size: 90,
                showLabel: false,
              ),
            ),
            if (!_launched)
              Positioned(
                bottom: 200,
                child: Icon(
                  Icons.arrow_upward,
                  color: AppTheme.accentSecondary.withValues(alpha: 0.6),
                  size: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatapultPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height);
    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.55),
      Offset(size.width * 0.65, size.height * 0.55),
      paint..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
