import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class FirePoofScene extends StatefulWidget {
  const FirePoofScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<FirePoofScene> createState() => _FirePoofSceneState();
}

class _FirePoofSceneState extends State<FirePoofScene>
    with SingleTickerProviderStateMixin {
  bool _burning = false;
  double _burnProgress = 0;
  late AnimationController _flameController;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  Future<void> _ignite() async {
    if (_burning) return;
    setState(() => _burning = true);
    for (var i = 1; i <= 25; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _burnProgress = i / 25);
    }
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Fire Poof',
      hint: _burning ? 'Poof! Gone in smoke 🔥' : 'Tap to set ablaze (cartoon style!)',
      showTarget: false,
      child: GestureDetector(
        onTap: _ignite,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: 1 - _burnProgress,
                child: TargetAvatar(
                  target: widget.target,
                  size: 160,
                  showLabel: false,
                ),
              ),
              if (_burning)
                ...List.generate(5, (i) {
                  return AnimatedBuilder(
                    animation: _flameController,
                    builder: (context, _) {
                      final offset = (i - 2) * 30.0;
                      final height = 40 + _flameController.value * 30 + i * 10;
                      return Positioned(
                        bottom: 80 + _burnProgress * 20,
                        left: offset,
                        child: Icon(
                          Icons.local_fire_department,
                          size: height,
                          color: Color.lerp(
                            Colors.orange,
                            Colors.red,
                            _flameController.value,
                          ),
                        ),
                      );
                    },
                  );
                }),
              if (_burnProgress > 0.7)
                Text(
                  'POOF!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent.withValues(alpha: _burnProgress),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
