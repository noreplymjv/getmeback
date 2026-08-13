import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class BlenderScene extends StatefulWidget {
  const BlenderScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<BlenderScene> createState() => _BlenderSceneState();
}

class _BlenderSceneState extends State<BlenderScene>
    with SingleTickerProviderStateMixin {
  bool _blending = false;
  double _blendProgress = 0;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _startBlend() {
    if (_blending) return;
    setState(() => _blending = true);
    _animateBlend();
  }

  Future<void> _animateBlend() async {
    for (var i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _blendProgress = i / 20);
    }
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Juice Blender',
      hint: _blending
          ? 'Blending away the stress... 🌀'
          : 'Drag the target into the blender!',
      showTarget: false,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 80,
            child: _buildBlender(),
          ),
          if (!_blending)
            Positioned(
              top: 120,
              child: Draggable(
                feedback: TargetAvatar(
                  target: widget.target,
                  size: 80,
                  showLabel: false,
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: TargetAvatar(
                    target: widget.target,
                    size: 80,
                    showLabel: false,
                  ),
                ),
                onDragEnd: (details) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  if (details.offset.dy > screenHeight * 0.35) {
                    _startBlend();
                  }
                },
                child: TargetAvatar(
                  target: widget.target,
                  size: 100,
                  showLabel: false,
                ),
              ),
            ),
          if (_blending)
            Positioned(
              bottom: 160,
              child: AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _spinController.value * 2 * pi,
                    child: Opacity(
                      opacity: 1 - _blendProgress,
                      child: TargetAvatar(
                        target: widget.target,
                        size: 80 * (1 - _blendProgress * 0.8),
                        showLabel: false,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlender() {
    return Column(
      children: [
        Container(
          width: 140,
          height: 160,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentSecondary, width: 3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_blending)
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(100, 100),
                      painter: _SwirlPainter(_spinController.value),
                    );
                  },
                ),
              Icon(Icons.blender, size: 48, color: AppTheme.accentSecondary),
            ],
          ),
        ),
        Container(
          width: 100,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

class _SwirlPainter extends CustomPainter {
  _SwirlPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 20 + i * 15.0),
        progress * 2 * pi + i,
        pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SwirlPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
