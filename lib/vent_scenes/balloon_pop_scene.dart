import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class BalloonPopScene extends StatefulWidget {
  const BalloonPopScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<BalloonPopScene> createState() => _BalloonPopSceneState();
}

class _BalloonPopSceneState extends State<BalloonPopScene> {
  bool _popped = false;
  final _random = Random();

  void _pop() {
    if (_popped) return;
    setState(() => _popped = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/calm/${widget.target.id}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Balloon Pop',
      hint: _popped ? 'POP! 💥' : 'Tap the balloon to pop it!',
      showTarget: false,
      child: GestureDetector(
        onTap: _pop,
        child: Center(
          child: AnimatedScale(
            scale: _popped ? 2.5 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _popped ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: _popped
                  ? _buildPopParticles()
                  : _buildBalloon(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalloon() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 160,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accent, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: TargetAvatar(
              target: widget.target,
              size: 90,
              showLabel: false,
            ),
          ),
        ),
        Container(
          width: 2,
          height: 80,
          color: Colors.grey.shade500,
        ),
      ],
    );
  }

  Widget _buildPopParticles() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(12, (i) {
          final angle = i * pi / 6;
          final dist = 60 + _random.nextDouble() * 40;
          return Transform.translate(
            offset: Offset(cos(angle) * dist, sin(angle) * dist),
            child: Icon(
              Icons.star,
              color: [
                AppTheme.accent,
                AppTheme.accentSecondary,
                AppTheme.calm,
              ][i % 3],
              size: 20 + _random.nextDouble() * 16,
            ),
          );
        }),
      ),
    );
  }
}
