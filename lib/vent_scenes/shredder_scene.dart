import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class ShredderScene extends StatefulWidget {
  const ShredderScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<ShredderScene> createState() => _ShredderSceneState();
}

class _ShredderSceneState extends State<ShredderScene>
    with SingleTickerProviderStateMixin {
  bool _shredding = false;
  double _shredProgress = 0;
  late AnimationController _bladeController;

  @override
  void initState() {
    super.initState();
    _bladeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _bladeController.dispose();
    super.dispose();
  }

  Future<void> _shred() async {
    if (_shredding) return;
    setState(() => _shredding = true);
    _bladeController.repeat();
    for (var i = 1; i <= 25; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() => _shredProgress = i / 25);
    }
    _bladeController.stop();
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Paper Shredder',
      hint: _shredding ? 'Shredded! 📄' : 'Drop the target into the shredder!',
      showTarget: false,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 80,
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AnimatedBuilder(
                    animation: _bladeController,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(8, (i) {
                          return Transform.rotate(
                            angle: _bladeController.value * 6.28 + i,
                            child: const Icon(
                              Icons.content_cut,
                              color: Colors.grey,
                              size: 16,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                Container(
                  width: 180,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                    border: Border.all(color: Colors.grey.shade600, width: 2),
                  ),
                  child: _shredProgress > 0.5
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: List.generate(6, (i) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 2,
                              ),
                              height: 4,
                              color: AppTheme.accent.withValues(alpha: 0.4),
                            );
                          }),
                        )
                      : null,
                ),
              ],
            ),
          ),
          Positioned(
            top: 80 + _shredProgress * 200,
            child: Transform.scale(
              scale: 1 - _shredProgress * 0.8,
              child: Opacity(
                opacity: 1 - _shredProgress,
                child: _shredding
                    ? TargetAvatar(
                        target: widget.target,
                        size: 90,
                        showLabel: false,
                      )
                    : Draggable(
                        feedback: Material(
                          color: Colors.transparent,
                          child: TargetAvatar(
                            target: widget.target,
                            size: 80,
                            showLabel: false,
                          ),
                        ),
                        onDragEnd: (details) {
                          if (details.offset.dy > 100) _shred();
                        },
                        child: TargetAvatar(
                          target: widget.target,
                          size: 100,
                          showLabel: false,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
