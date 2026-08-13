import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class BlenderScene extends StatefulWidget {
  const BlenderScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<BlenderScene> createState() => _BlenderSceneState();
}

class _BlenderSceneState extends State<BlenderScene>
    with TickerProviderStateMixin {
  bool _blending = false;
  double _blendProgress = 0;
  late AnimationController _spinController;
  late final DramaticFxController _fx = DramaticFxController();

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..repeat();
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _startBlend(Size area) {
    if (_blending) return;
    setState(() => _blending = true);
    final center = Offset(area.width / 2, area.height * 0.62);
    _fx.impact(at: center, count: 40, intensity: 1.4, color: AppTheme.accentSecondary);
    _animateBlend(center);
  }

  Future<void> _animateBlend(Offset center) async {
    for (var i = 1; i <= 28; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() => _blendProgress = i / 28);
      if (i % 2 == 0) {
        _fx.swirlBurst(
          at: center.translate(
            (Random().nextDouble() - 0.5) * 40,
            (Random().nextDouble() - 0.5) * 30,
          ),
          count: 14,
          color: Color.lerp(
            AppTheme.accent,
            const Color(0xFFFFD54F),
            i / 28,
          ),
        );
      }
    }
    _fx.confettiBurst(at: center, count: 50);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Juice Blender',
        hint: _blending
            ? 'WHIRRR — blending the stress into juice!!!'
            : 'Drag the target into the blender — or tap the blender!',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            return ventFxLayer(
              fx: _fx,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 60,
                    child: GestureDetector(
                      onTap: () => _startBlend(area),
                      child: _buildBlender(),
                    ),
                  ),
                  if (!_blending)
                    Positioned(
                      top: 80,
                      child: Draggable(
                        feedback: TargetAvatar(
                          target: widget.target,
                          size: 90,
                          showLabel: false,
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.25,
                          child: TargetAvatar(
                            target: widget.target,
                            size: 90,
                            showLabel: false,
                          ),
                        ),
                        onDragEnd: (details) {
                          final screenHeight =
                              MediaQuery.of(context).size.height;
                          if (details.offset.dy > screenHeight * 0.3) {
                            _startBlend(area);
                          }
                        },
                        child: TargetAvatar(
                          target: widget.target,
                          size: 110,
                          showLabel: false,
                        ),
                      ),
                    ),
                  if (_blending)
                    Positioned(
                      bottom: 150,
                      child: AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) {
                          final spin = _spinController.value * 2 * pi * 3;
                          return Transform.rotate(
                            angle: spin,
                            child: Transform.scale(
                              scale: 1 - _blendProgress * 0.85,
                              child: Opacity(
                                opacity: (1 - _blendProgress).clamp(0.0, 1.0),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: TargetAvatar(
                          target: widget.target,
                          size: 90,
                          showLabel: false,
                        ),
                      ),
                    ),
                  if (_blending)
                    Positioned(
                      bottom: 40,
                      child: Text(
                        'JUICE LEVEL ${(100 * _blendProgress).round()}%',
                        style: TextStyle(
                          color: AppTheme.accentSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          shadows: [
                            Shadow(
                              color: AppTheme.accentSecondary
                                  .withValues(alpha: 0.7),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlender() {
    final glow = _blending ? AppTheme.accent : AppTheme.accentSecondary;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glow, width: 4),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: _blending ? 0.55 : 0.2),
                blurRadius: _blending ? 28 : 8,
                spreadRadius: _blending ? 4 : 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_blending)
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(120, 120),
                      painter: _SwirlPainter(
                        _spinController.value,
                        _blendProgress,
                      ),
                    );
                  },
                ),
              Icon(
                Icons.blender,
                size: 56,
                color: glow,
              ),
            ],
          ),
        ),
        Container(
          width: 110,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: glow.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            _blending ? 'ON' : 'DROP IN',
            style: TextStyle(
              color: glow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwirlPainter extends CustomPainter {
  _SwirlPainter(this.progress, this.blend);

  final double progress;
  final double blend;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 6; i++) {
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFF8A65),
          const Color(0xFFFFD54F),
          (i / 6 + blend) % 1,
        )!
            .withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 14.0 + i * 10),
        progress * 2 * pi * (1 + i * 0.15) + i,
        pi * 1.2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SwirlPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.blend != blend;
}
