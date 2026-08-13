import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vent_target.dart';
import '../../theme/app_theme.dart';
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

  Future<void> _freeze() async {
    if (_frozen) return;
    setState(() => _frozen = true);
  }

  void _tapIce() {
    if (!_frozen || _shattered) return;
    setState(() => _taps++);
    if (_taps >= 5) {
      setState(() => _shattered = true);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) context.go('/calm/${widget.target.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VentSceneShell(
      target: widget.target,
      title: 'Ice Shatter',
      hint: !_frozen
          ? 'Tap to freeze them solid!'
          : _shattered
              ? 'Shattered! ❄️💥'
              : 'Tap the ice to shatter! (${5 - _taps} taps left)',
      showTarget: false,
      child: GestureDetector(
        onTap: !_frozen ? _freeze : _tapIce,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _shattered
                ? _buildShards()
                : _buildIceBlock(),
          ),
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
            ? AppTheme.accentSecondary.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: _frozen
            ? Border.all(color: AppTheme.accentSecondary, width: 4)
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

  Widget _buildShards() {
    return SizedBox(
      key: const ValueKey('shards'),
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(8, (i) {
          final angle = i * pi / 4;
          return Transform.translate(
            offset: Offset(cos(angle) * 70, sin(angle) * 70),
            child: Transform.rotate(
              angle: angle,
              child: Icon(
                Icons.crop_square,
                size: 30,
                color: AppTheme.accentSecondary.withValues(alpha: 0.8),
              ),
            ),
          );
        }),
      ),
    );
  }
}
