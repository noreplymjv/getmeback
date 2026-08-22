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

class CatapultScene extends StatefulWidget {
  const CatapultScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<CatapultScene> createState() => _CatapultSceneState();
}

class _CatapultSceneState extends BaseVentSceneState<CatapultScene> {
  bool _launched = false;
  bool _apexConfettiFired = false;
  late AnimationController _launchController;
  Offset _center = Offset.zero;

  @override
  void initState() {
    super.initState();
    _launchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _launchController.addListener(_onLaunchTick);
  }

  void _onLaunchTick() {
    if (!_launched || _apexConfettiFired) return;
    if (_launchController.value >= 0.45 && _launchController.value <= 0.55) {
      _apexConfettiFired = true;
      fx.confettiBurst(at: _center);
    }
  }

  @override
  void dispose() {
    _launchController.removeListener(_onLaunchTick);
    _launchController.dispose();
    super.dispose();
  }

  Future<void> _launch() async {
    if (_launched) return;
    setState(() => _launched = true);
    fx.megaImpact(at: _center, color: AppTheme.accentSecondary);
    fx.comicPop(at: _center, text: 'YEET!', color: AppTheme.accentSecondary);
    fx.smokeBurst(at: Offset(_center.dx, _center.dy + 60), count: 14);
    await _launchController.forward();
    fx.confettiBurst(at: _center.translate(180, -100), count: 50);
    fx.crackerBurst(at: _center.translate(180, -100), volleys: 4);
    fx.glitterRain(at: _center.translate(180, -100), count: 40);
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Catapult',
        hint: _launched ? 'YEET! 🚀' : 'Drag back and release to launch!',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            final scale = SceneScale(constraints);
            final rigWidth = scale.container(0.5);
            _center = Offset(area.width / 2, area.height * 0.5);
            return ventFxLayer(
              fx: fx,
              child: GestureDetector(
                onPanEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dy < -200) _launch();
                },
                onTap: _launch,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: area.height * 0.18,
                      child: CustomPaint(
                        size: Size(rigWidth, rigWidth * 0.5),
                        painter: _CatapultPainter(),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _launchController,
                      builder: (context, child) {
                        final t = Curves.easeOut.transform(_launchController.value);
                        final x = sin(t * pi) * area.width * 0.4;
                        final y = -sin(t * pi) * area.height * 0.55 +
                            t * area.height * 0.2;
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
                        size: scale.avatar(0.24),
                        showLabel: false,
                      ),
                    ),
                    if (!_launched)
                      Positioned(
                        bottom: area.height * 0.45,
                        child: Icon(
                          Icons.arrow_upward,
                          color: AppTheme.accentSecondary.withValues(alpha: 0.6),
                          size: scale.accent(0.07),
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
