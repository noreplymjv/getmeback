import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class SledgehammerScene extends StatefulWidget {
  const SledgehammerScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<SledgehammerScene> createState() => _SledgehammerSceneState();
}

class _SledgehammerSceneState extends State<SledgehammerScene>
    with SingleTickerProviderStateMixin {
  late final DramaticFxController _fx = DramaticFxController();
  int _smashes = 0;
  bool _swinging = false;
  late AnimationController _swingController;
  Offset _center = Offset.zero;

  @override
  void initState() {
    super.initState();
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _fx.dispose();
    _swingController.dispose();
    super.dispose();
  }

  Future<void> _smash() async {
    if (_swinging) return;
    setState(() => _swinging = true);
    await _swingController.forward(from: 0);
    if (!mounted) return;
    _fx.megaImpact(at: _center, color: AppTheme.accent);
    _fx.comicPop(at: _center, color: AppTheme.accent);
    setState(() {
      _smashes++;
      _swinging = false;
    });
    _swingController.reset();
    if (_smashes >= 5) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.go('/calm/${widget.target.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Sledgehammer',
        hint: _smashes >= 5
            ? 'Pulverized! 🔨'
            : 'Tap to swing the hammer! ($_smashes/5)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            _center = Offset(area.width / 2, area.height * 0.5);
            return ventFxLayer(
              fx: _fx,
              child: GestureDetector(
                onTap: _smash,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 - _smashes * 0.12,
                      child: TargetAvatar(
                        target: widget.target,
                        size: 160,
                        showLabel: false,
                        cracks: _smashes.clamp(0, 6),
                      ),
                    ),
                    if (_smashes > 0)
                      ...List.generate(_smashes, (i) {
                        return Positioned(
                          top: 80 + i * 8.0,
                          left: 60 + (i % 3) * 40.0,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppTheme.accent.withValues(alpha: 0.6),
                            size: 24,
                          ),
                        );
                      }),
                    AnimatedBuilder(
                      animation: _swingController,
                      builder: (context, child) {
                        final angle = -pi / 4 + _swingController.value * pi / 2;
                        return Positioned(
                          top: 40,
                          right: 40,
                          child: Transform.rotate(
                            angle: angle,
                            alignment: Alignment.bottomCenter,
                            child: child,
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.hardware,
                        size: 80,
                        color: Color(0xFF78909C),
                      ),
                    ),
                    if (_swinging)
                      Positioned(
                        bottom: 120,
                        child: Text(
                          'WHAM!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent.withValues(alpha: 0.8),
                          ),
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
