import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
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
  late final DramaticFxController _fx = DramaticFxController();
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

  Future<void> _startSink() async {
    if (_sinking) return;
    setState(() => _sinking = true);
    _fx.rippleBurst(at: _center, color: const Color(0xFF4FC3F7));
    _fx.dripBurst(at: _center, count: 20);
    for (var i = 1; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() => _waterLevel = i / 30);
      if (i % 5 == 0) {
        _fx.dripBurst(
          at: Offset(_center.dx, _center.dy - 40),
          count: 8,
          color: const Color(0xFF4FC3F7),
        );
        _fx.rippleBurst(at: _center, color: const Color(0xFF4FC3F7), count: 2);
      }
    }
    _fx.megaImpact(at: _center, color: const Color(0xFF4FC3F7));
    _fx.comicPop(at: _center, text: 'GLUB!', color: const Color(0xFF4FC3F7));
    _fx.crackerBurst(at: _center, volleys: 3);
    _fx.glitterRain(at: _center, count: 36);
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.go('/calm/${widget.target.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Sink & Drown',
        hint: _sinking ? 'Glub glub... 💧' : 'Tap to fill the sink!',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = SceneScale(constraints);
            final sinkWidth = scale.container(0.6);
            final sinkHeight = sinkWidth * 0.77;
            _center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.55,
            );
            return GestureDetector(
              onTap: _startSink,
              child: ventFxLayer(
                fx: _fx,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: constraints.maxHeight * 0.12,
                      child: Container(
                        width: sinkWidth,
                        height: sinkHeight,
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
                                  height: sinkHeight * _waterLevel,
                                  width: double.infinity,
                                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.7),
                                ),
                              ),
                              if (_waterLevel > 0.3)
                                Center(
                                  child: Icon(
                                    Icons.water,
                                    size: scale.accent(0.09),
                                    color: Colors.white.withValues(alpha: _waterLevel),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: constraints.maxHeight * 0.12 +
                          sinkHeight * 0.35 +
                          (1 - _waterLevel) * sinkHeight * 0.35,
                      child: Transform.scale(
                        scale: 1 - _waterLevel * 0.5,
                        child: Opacity(
                          opacity: 1 - _waterLevel * 0.9,
                          child: TargetAvatar(
                            target: widget.target,
                            size: sinkWidth * 0.4,
                            showLabel: false,
                          ),
                        ),
                      ),
                    ),
                    if (_waterLevel > 0.5)
                      Positioned(
                        top: constraints.maxHeight * 0.16,
                        child: Text(
                          'Glub glub...',
                          style: TextStyle(
                            fontSize: scale.accent(0.05),
                            color: const Color(0xFF4FC3F7).withValues(alpha: _waterLevel),
                            fontStyle: FontStyle.italic,
                          ),
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
