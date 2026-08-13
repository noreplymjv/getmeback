import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class StompScene extends StatefulWidget {
  const StompScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<StompScene> createState() => _StompSceneState();
}

class _StompSceneState extends State<StompScene>
    with SingleTickerProviderStateMixin {
  int _stomps = 0;
  double _flatness = 1.0;
  late AnimationController _footController;

  @override
  void initState() {
    super.initState();
    _footController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _footController.dispose();
    super.dispose();
  }

  void _stomp() {
    setState(() {
      _stomps++;
      _flatness = (1.0 - _stomps * 0.12).clamp(0.2, 1.0);
    });
    _footController.forward(from: 0);
    if (_stomps >= 6) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Stomp',
      hint: 'Tap to stomp flat! ($_stomps stomps)',
      showTarget: false,
      child: GestureDetector(
        onTap: _stomp,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scaleY: _flatness,
              child: TargetAvatar(
                target: widget.target,
                size: 160,
                showLabel: false,
              ),
            ),
            AnimatedBuilder(
              animation: _footController,
              builder: (context, child) {
                final y = -80 + _footController.value * 160;
                return Transform.translate(
                  offset: Offset(0, y),
                  child: Opacity(
                    opacity: _footController.value < 0.5
                        ? 1
                        : 1 - (_footController.value - 0.5) * 2,
                    child: const Text(
                      '👟',
                      style: TextStyle(fontSize: 64),
                    ),
                  ),
                );
              },
            ),
            if (_stomps >= 3)
              Positioned(
                bottom: 80,
                child: Text(
                  'Squish! 👟',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
