import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../services/vent_sfx.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dramatic_fx.dart';
import '../../widgets/target_avatar.dart';
import '../../widgets/vent_scene_shell.dart';

class IceShatterScene extends StatefulWidget {
  const IceShatterScene({super.key, required this.target});

  final VentTarget target;

  @override
  State<IceShatterScene> createState() => _IceShatterSceneState();
}

class _IceShatterSceneState extends State<IceShatterScene> {
  bool _frozen = false;
  bool _shattered = false;
  int _taps = 0;
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

  void _freeze(Offset center) {
    if (_frozen) return;
    setState(() => _frozen = true);
    _fx.swirlBurst(at: center, count: 50, color: AppTheme.accentSecondary);
    _fx.comicPop(at: center, text: 'FREEZE!', color: AppTheme.accentSecondary);
  }

  void _tapIce(Offset center) {
    if (!_frozen || _shattered) return;
    setState(() => _taps++);
    _fx.impact(
      at: center,
      count: 20 + _taps * 8,
      color: AppTheme.accentSecondary,
      intensity: 0.9 + _taps * 0.15,
    );
    VentSfx.instance.play(Sfx.crack);
    if (_taps >= 5) {
      setState(() => _shattered = true);
      _fx.megaImpact(at: center, color: AppTheme.accentSecondary);
      _fx.confettiBurst(at: center, count: 60);
      Future.delayed(const Duration(milliseconds: 1000), () {
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
        title: 'Ice Shatter',
        hint: !_frozen
            ? 'Tap to freeze them solid!'
            : _shattered
                ? 'Shattered! ❄️💥'
                : 'Tap the ice to shatter! (${5 - _taps} taps left)',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.45,
            );
            return GestureDetector(
              onTap: () => !_frozen ? _freeze(center) : _tapIce(center),
              child: ventFxLayer(
                fx: _fx,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _shattered
                        ? Icon(
                            Icons.ac_unit,
                            key: const ValueKey('done'),
                            size: 80,
                            color: AppTheme.accentSecondary
                                .withValues(alpha: 0.5),
                          )
                        : _buildIceBlock(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIceBlock() {
    return Container(
      key: const ValueKey('ice'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _frozen
            ? AppTheme.accentSecondary.withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: _frozen
            ? Border.all(color: AppTheme.accentSecondary, width: 4)
            : null,
        boxShadow: _frozen
            ? [
                BoxShadow(
                  color: AppTheme.accentSecondary.withValues(alpha: 0.4),
                  blurRadius: 24,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_frozen)
            const Icon(Icons.ac_unit, size: 32, color: AppTheme.accentSecondary),
          TargetAvatar(
            target: widget.target,
            size: 140,
            showLabel: false,
            opacity: _frozen ? 0.7 : 1.0,
          ),
        ],
      ),
    );
  }
}
