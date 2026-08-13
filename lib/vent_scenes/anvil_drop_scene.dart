import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/vent_sfx.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class AnvilDropScene extends StatefulWidget {
  const AnvilDropScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<AnvilDropScene> createState() => _AnvilDropSceneState();
}

class _AnvilDropSceneState extends State<AnvilDropScene>
    with SingleTickerProviderStateMixin {
  late final DramaticFxController _fx = DramaticFxController();
  late AnimationController _drop;
  int _drops = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _drop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fx.dispose();
    _drop.dispose();
    super.dispose();
  }

  Future<void> _dropAnvil(Offset center) async {
    if (_done) return;
    VentSfx.instance.play(Sfx.whoosh);
    await _drop.forward(from: 0);
    setState(() => _drops++);
    VentSfx.instance.play(Sfx.boom);
    if (_drops >= 3) {
      _fx.megaImpact(at: center);
      _fx.debrisRain(at: center, count: 40);
      _fx.comicPop(at: center, text: 'SPLAT!');
      setState(() => _done = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go('/calm/${widget.target.id}');
    } else {
      _fx.impact(at: center, count: 40, intensity: 1.3);
    }
    _drop.reset();
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Anvil Drop',
        hint: _done ? 'Flattened!' : 'Tap to drop the anvil! ($_drops/3)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.55,
            );
            return GestureDetector(
              onTap: () => _dropAnvil(center),
              child: ventFxLayer(
                fx: _fx,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scaleY: (1 - _drops * 0.22).clamp(0.28, 1.0),
                      child: TargetAvatar(
                        target: widget.target,
                        size: 150,
                        showLabel: false,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _drop,
                      builder: (context, child) {
                        final y = -220 + Curves.easeIn.transform(_drop.value) * 280;
                        return Transform.translate(
                          offset: Offset(0, y),
                          child: Opacity(
                            opacity: _drop.value == 0 ? 0.35 : 1,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.square,
                        size: 88,
                        color: Colors.blueGrey.shade300,
                        shadows: const [
                          Shadow(blurRadius: 12, color: Colors.black54),
                        ],
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
