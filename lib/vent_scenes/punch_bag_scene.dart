import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class PunchBagScene extends StatefulWidget {
  const PunchBagScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<PunchBagScene> createState() => _PunchBagSceneState();
}

class _PunchBagSceneState extends State<PunchBagScene>
    with SingleTickerProviderStateMixin {
  int _punches = 0;
  late AnimationController _swingController;

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  void _punch() {
    setState(() => _punches++);
    _swingController.forward(from: 0);
    if (_punches >= 10) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Punch Bag',
      hint: 'Tap the bag to punch! ($_punches punches)',
      showTarget: false,
      child: GestureDetector(
        onTap: _punch,
        child: AnimatedBuilder(
          animation: _swingController,
          builder: (context, child) {
            final swing = sin(_swingController.value * pi) * 0.3;
            return Transform.rotate(
              angle: swing,
              alignment: Alignment.topCenter,
              child: child,
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 60,
                  color: Colors.grey.shade600,
                ),
                Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(70),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.4),
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
                const SizedBox(height: 16),
                Text(
                  _punches >= 5 ? 'Keep going! 🥊' : 'POW!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentSecondary,
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
