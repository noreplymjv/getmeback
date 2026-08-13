import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class TrashCanScene extends StatefulWidget {
  const TrashCanScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<TrashCanScene> createState() => _TrashCanSceneState();
}

class _TrashCanSceneState extends State<TrashCanScene> {
  late final DramaticFxController _fx = DramaticFxController();
  bool _thrown = false;
  double _throwProgress = 0;
  Offset _center = Offset.zero;

  @override
  void initState() {
    super.initState();
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    super.dispose();
  }

  Future<void> _throwIn() async {
    if (_thrown) return;
    setState(() => _thrown = true);
    _fx.impact(at: _center, color: AppTheme.accent, intensity: 0.9);
    for (var i = 1; i <= 15; i++) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      setState(() => _throwProgress = i / 15);
    }
    _fx.confettiBurst(at: _center);
    if (mounted) context.go('/calm/${widget.target.id}');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final avatarY = _thrown
        ? 120 + (screenHeight * 0.35 * _throwProgress)
        : 120.0;
    final avatarScale = _thrown ? 1 - _throwProgress * 0.6 : 1.0;
    final avatarRotation = _throwProgress * 6.28;

    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Trash Can',
        hint: _thrown ? 'Outta here! 🗑️' : 'Flick the target into the trash!',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            _center = Offset(area.width / 2, area.height * 0.5);
            return ventFxLayer(
              fx: _fx,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 100,
                    child: Column(
                      children: [
                        Container(
                          width: 160,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 140,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                          ),
                          child: const Icon(
                            Icons.delete_forever,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: avatarY,
                    child: Transform.rotate(
                      angle: avatarRotation,
                      child: Transform.scale(
                        scale: avatarScale,
                        child: _thrown
                            ? TargetAvatar(
                                target: widget.target,
                                size: 90,
                                showLabel: false,
                                opacity: 1 - _throwProgress * 0.5,
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
                                  if (details.offset.dy > screenHeight * 0.3) {
                                    _throwIn();
                                  }
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
          },
        ),
      ),
    );
  }
}
