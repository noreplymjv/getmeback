import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class PinataScene extends StatefulWidget {
  const PinataScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<PinataScene> createState() => _PinataSceneState();
}

class _PinataSceneState extends State<PinataScene>
    with SingleTickerProviderStateMixin {
  int _hits = 0;
  bool _broken = false;
  late AnimationController _swingController;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  void _hit() {
    setState(() => _hits++);
    if (_hits >= 6) {
      setState(() => _broken = true);
      _swingController.stop();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Piñata',
      hint: _broken
          ? 'Candy explosion! 🎉'
          : 'Tap to whack the piñata! ($_hits/6)',
      showTarget: false,
      child: GestureDetector(
        onTap: _hit,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!_broken)
              AnimatedBuilder(
                animation: _swingController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: sin(_swingController.value * pi) * 0.15,
                    alignment: Alignment.topCenter,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 60,
                      color: Colors.brown.shade400,
                    ),
                    Container(
                      width: 140,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accent,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: TargetAvatar(
                          target: widget.target,
                          size: 80,
                          showLabel: false,
                          cracks: (_hits / 2).floor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_broken)
              SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(16, (i) {
                    final angle = i * pi / 8;
                    final dist = 40 + _random.nextDouble() * 80;
                    return Transform.translate(
                      offset: Offset(
                        cos(angle) * dist,
                        sin(angle) * dist,
                      ),
                      child: Icon(
                        [
                          Icons.star,
                          Icons.celebration,
                          Icons.cake,
                        ][i % 3],
                        color: [
                          AppTheme.accent,
                          AppTheme.accentSecondary,
                          AppTheme.calm,
                          Colors.yellow,
                        ][i % 4],
                        size: 20 + _random.nextDouble() * 20,
                      ),
                    );
                  }),
                ),
              ),
            if (!_broken)
              Positioned(
                top: 40,
                child: Icon(
                  Icons.sports_cricket,
                  size: 48,
                  color: Colors.brown.shade300,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
