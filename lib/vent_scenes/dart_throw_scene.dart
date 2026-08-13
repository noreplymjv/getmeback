import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class DartThrowScene extends StatefulWidget {
  const DartThrowScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<DartThrowScene> createState() => _DartThrowSceneState();
}

class _DartThrowSceneState extends State<DartThrowScene> {
  final List<Offset> _darts = [];
  int _hits = 0;

  void _throwDart(TapDownDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _darts.add(local);
      _hits++;
    });
    if (_hits >= 8) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Dart Throw',
      hint: 'Tap anywhere to throw darts! ($_hits darts)',
      showTarget: false,
      child: GestureDetector(
        onTapDown: _throwDart,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.calm, width: 4),
                color: AppTheme.surface,
              ),
              child: Center(
                child: TargetAvatar(
                  target: widget.target,
                  size: 100,
                  showLabel: false,
                ),
              ),
            ),
            ..._darts.map(
              (pos) => Positioned(
                left: pos.dx - 12,
                top: pos.dy - 12,
                child: Transform.rotate(
                  angle: -pi / 4,
                  child: const Icon(
                    Icons.push_pin,
                    size: 24,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
