import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/vent_sfx.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class BoxingKoScene extends StatefulWidget {
  const BoxingKoScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<BoxingKoScene> createState() => _BoxingKoSceneState();
}

class _BoxingKoSceneState extends State<BoxingKoScene>
    with SingleTickerProviderStateMixin {
  late final DramaticFxController _fx = DramaticFxController();
  late AnimationController _glove;
  int _hits = 0;
  bool _ko = false;

  @override
  void initState() {
    super.initState();
    _glove = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    _glove.dispose();
    super.dispose();
  }

  void _punch(Offset center) {
    if (_ko) return;
    setState(() => _hits++);
    _glove.forward(from: 0);
    if (_hits >= 8) {
      setState(() => _ko = true);
      VentSfx.instance.play(Sfx.ko);
      _fx.megaImpact(at: center);
      _fx.confettiBurst(at: center, count: 50);
      _fx.comicPop(at: center, text: 'K.O.!');
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    } else {
      _fx.impact(
        at: center,
        count: 24 + _hits * 4,
        intensity: 0.9 + _hits * 0.1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Boxing KO',
        hint: _ko ? 'K.O.!' : 'Tap to punch! ($_hits/8)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.45,
            );
            return GestureDetector(
              onTap: () => _punch(center),
              child: ventFxLayer(
                fx: _fx,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: _ko ? 1.2 : _hits * 0.04,
                      child: Opacity(
                        opacity: _ko ? 0.35 : 1,
                        child: TargetAvatar(
                          target: widget.target,
                          size: 160,
                          showLabel: false,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _glove,
                      builder: (context, child) {
                        final t = Curves.easeOut.transform(_glove.value);
                        return Transform.translate(
                          offset: Offset(-90 + t * 110, 40 - t * 20),
                          child: Opacity(
                            opacity: t < 0.15 ? 0 : 1 - (t - 0.5).clamp(0, 0.5) * 2,
                            child: child,
                          ),
                        );
                      },
                      child: const Text('🥊', style: TextStyle(fontSize: 64)),
                    ),
                    if (_ko)
                      const Text(
                        '★ K.O. ★',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD54F),
                        ),
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
