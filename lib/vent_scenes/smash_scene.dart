import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class SmashScene extends StatefulWidget {
  const SmashScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<SmashScene> createState() => _SmashSceneState();
}

class _SmashSceneState extends State<SmashScene>
    with SingleTickerProviderStateMixin {
  int _hits = 0;
  int _cracks = 0;
  double _wobble = 0;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onHit(TapDownDetails details) {
    setState(() {
      _hits++;
      _cracks = (_hits / 3).floor().clamp(0, 6);
      _wobble = sin(_hits * 0.5) * 0.08;
    });
    _shakeController.forward(from: 0);
    if (_hits >= 12) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Smash Face',
      hint: 'Tap or swipe the face to smash! ($_hits hits)',
      showTarget: false,
      child: GestureDetector(
        onTapDown: _onHit,
        onPanUpdate: (_) => _onHit(TapDownDetails(globalPosition: Offset.zero)),
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final shake = sin(_shakeController.value * pi * 8) * 8;
            return Transform.translate(
              offset: Offset(shake, 0),
              child: Transform.rotate(
                angle: _wobble,
                child: child,
              ),
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TargetAvatar(
                  target: widget.target,
                  size: 200,
                  cracks: _cracks,
                ),
                const SizedBox(height: 24),
                if (_cracks >= 3)
                  Text(
                    'Cracking up! 💥',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
