import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../services/vent_sfx.dart';
import '../../widgets/dramatic_fx.dart';
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
  late final DramaticFxController _fx = DramaticFxController();

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

  void _pop(Offset center) {
    if (_popped) return;
    setState(() => _popped = true);
    VentSfx.instance.play(Sfx.pop);
    _fx.megaImpact(at: center, color: AppTheme.accent);
    _fx.confettiBurst(at: center, count: 90);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/calm/${widget.target.id}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Balloon Pop',
        hint: _popped ? 'POP! 💥' : 'Tap the balloon to pop it!',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.42,
            );
            return GestureDetector(
              onTap: () => _pop(center),
              child: ventFxLayer(
                fx: _fx,
                child: Center(
                  child: AnimatedScale(
                    scale: _popped ? 2.8 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: _popped ? 0 : 1,
                      duration: const Duration(milliseconds: 350),
                      child: _buildBalloon(),
                    ),
                  ),
                ),
              ),
            );
          },
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
                color: AppTheme.accent.withValues(alpha: 0.4),
                blurRadius: 28,
                spreadRadius: 4,
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
        Container(width: 2, height: 80, color: Colors.grey.shade500),
      ],
    );
  }
}
