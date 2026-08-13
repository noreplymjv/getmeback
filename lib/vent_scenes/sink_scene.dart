import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class SinkScene extends StatefulWidget {
  const SinkScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<SinkScene> createState() => _SinkSceneState();
}

class _SinkSceneState extends State<SinkScene> {
  bool _sinking = false;
  double _waterLevel = 0;

  Future<void> _startSink() async {
    if (_sinking) return;
    setState(() => _sinking = true);
    for (var i = 1; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() => _waterLevel = i / 30);
    }
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Sink & Drown',
      hint: _sinking ? 'Glub glub... 💧' : 'Tap to fill the sink!',
      showTarget: false,
      child: GestureDetector(
        onTap: _startSink,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 60,
              child: Container(
                width: 260,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade600, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          height: 200 * _waterLevel,
                          width: double.infinity,
                          color: const Color(0xFF4FC3F7).withValues(alpha: 0.7),
                        ),
                      ),
                      if (_waterLevel > 0.3)
                        Center(
                          child: Icon(
                            Icons.water,
                            size: 40,
                            color: Colors.white.withValues(alpha: _waterLevel),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120 + (1 - _waterLevel) * 80,
              child: Transform.scale(
                scale: 1 - _waterLevel * 0.5,
                child: Opacity(
                  opacity: 1 - _waterLevel * 0.9,
                  child: TargetAvatar(
                    target: widget.target,
                    size: 100,
                    showLabel: false,
                  ),
                ),
              ),
            ),
            if (_waterLevel > 0.5)
              Positioned(
                top: 100,
                child: Text(
                  'Glub glub...',
                  style: TextStyle(
                    fontSize: 20,
                    color: const Color(0xFF4FC3F7).withValues(alpha: _waterLevel),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
