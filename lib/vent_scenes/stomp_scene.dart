import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../widgets/dramatic_fx.dart';
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
  late final DramaticFxController _fx = DramaticFxController();

  @override
  void initState() {
    super.initState();
    _footController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    _footController.dispose();
    super.dispose();
  }

  void _stomp(Offset center) {
    setState(() {
      _stomps++;
      _flatness = (1.0 - _stomps * 0.12).clamp(0.15, 1.0);
    });
    _footController.forward(from: 0);
    if (_stomps >= 4) {
      _fx.megaImpact(at: center);
      _fx.comicPop(at: center, text: 'SQUISH!');
    } else {
      _fx.impact(at: center, count: 30 + _stomps * 5, intensity: 1.1);
    }
    if (_stomps >= 6) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Stomp',
        hint: 'Tap to stomp flat! ($_stomps stomps)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.5,
            );
            return GestureDetector(
              onTap: () => _stomp(center),
              child: ventFxLayer(
                fx: _fx,
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
                              style: TextStyle(fontSize: 72),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
