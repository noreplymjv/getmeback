import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/scream_meter_service.dart';
import '../../services/vent_sfx.dart';
import '../../theme/app_theme.dart';
import '../../widgets/base_vent_scene.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/scene_scale.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class TornadoScene extends StatefulWidget {
  const TornadoScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<TornadoScene> createState() => _TornadoSceneState();
}

class _TornadoSceneState extends BaseVentSceneState<TornadoScene> {
  late AnimationController _spin;
  int _gusts = 0;
  bool _sucked = false;
  final _meter = ScreamMeterService();
  StreamSubscription<double>? _meterSub;
  double _screamLevel = 0;
  bool _micAvailable = false;
  Offset _lastCenter = Offset.zero;

  static const _gustGoal = 6.0;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _initMeter();
  }

  Future<void> _initMeter() async {
    _micAvailable = await _meter.start();
    _meterSub = _meter.intensity.listen((level) {
      if (!mounted || _sucked) return;
      setState(() => _screamLevel = level);
      if (level > 0.72) {
        _chargeGust(fromScream: true, center: _lastCenter);
      }
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _meterSub?.cancel();
    _meter.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _chargeGust({bool fromScream = false, Offset? center}) {
    if (_sucked) return;
    setState(() {
      _gusts++;
      if (fromScream) _screamLevel = (_screamLevel - 0.25).clamp(0.0, 1.0);
    });
    _spin.duration = Duration(milliseconds: (900 - _gusts * 110).clamp(180, 900));
    _spin.repeat();
    final c = center ?? Offset.zero;
    fx.swirlBurst(
      at: c,
      count: 28 + _gusts * 6,
      color: AppTheme.accentSecondary,
    );
    if (_gusts >= _gustGoal) {
      _finishSuck(c);
    }
  }

  void _finishSuck(Offset center) {
    setState(() => _sucked = true);
    VentSfx.instance.play(Sfx.suck);
    fx.megaImpact(at: center, color: AppTheme.accentSecondary);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) context.go('/calm/${widget.target.id}');
    });
  }

  void _gust(Offset center) {
    if (_sucked) return;
    _meter.boostFromTap();
    _chargeGust(center: center);
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: 'Tornado Spin',
        hint: _sucked
            ? 'Gone with the wind!'
            : _micAvailable
                ? 'Scream or tap to spin! ($_gusts/${_gustGoal.toInt()})'
                : 'Tap to spin the tornado! ($_gusts/${_gustGoal.toInt()})',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.48,
            );
            final sceneScale = SceneScale(constraints);
            final avatarSize = sceneScale.avatar(0.26);
            _lastCenter = center;
            return GestureDetector(
              onTap: () => _gust(center),
              child: VentFxLayer(
                fx: fx,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_micAvailable && !_sucked) ...[
                        _ScreamMeter(level: _screamLevel),
                        const SizedBox(height: 16),
                      ],
                      AnimatedBuilder(
                        animation: _spin,
                        builder: (context, child) {
                          final t = _spin.value * pi * 2;
                          final lift =
                              _sucked ? -sceneScale.travel(0.4) : _gusts * -8.0;
                          final scale = _sucked ? 0.05 : 1 - _gusts * 0.08;
                          return Transform.translate(
                            offset: Offset(sin(t) * (18 + _gusts * 4.0), lift),
                            child: Transform.rotate(
                              angle: t * (1 + _gusts * 0.4),
                              child: Transform.scale(
                                scale: scale.clamp(0.05, 1.0),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cyclone,
                              size: avatarSize * 0.62 + _gusts * 5,
                              color: AppTheme.accentSecondary.withValues(alpha: 0.7),
                            ),
                            TargetAvatar(
                              target: widget.target,
                              size: avatarSize,
                              showLabel: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScreamMeter extends StatelessWidget {
  const _ScreamMeter({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: level.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              color: Color.lerp(
                AppTheme.accentSecondary,
                const Color(0xFFFF7043),
                level,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level > 0.72 ? 'SCREAM!' : 'Scream into the mic…',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: level > 0.72 ? const Color(0xFFFF7043) : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
