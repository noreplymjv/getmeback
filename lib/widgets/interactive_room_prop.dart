import 'package:flutter/material.dart';

import '../models/room_setup.dart';
import '../theme/app_theme.dart';

/// Renders a real prop sprite (or legacy pin fallback) at a tuned anchor.
class InteractiveRoomProp extends StatelessWidget {
  const InteractiveRoomProp({
    super.key,
    required this.roomId,
    required this.prop,
    required this.stage,
    required this.pulse,
    required this.smashed,
    required this.holding,
    required this.throwTarget,
    required this.spriteMode,
    required this.onTap,
  });

  final String roomId;
  final RoomProp prop;
  final Size stage;
  final Animation<double> pulse;
  final bool smashed;
  final bool holding;
  final bool throwTarget;
  final bool spriteMode;
  final ValueChanged<Offset> onTap;

  Offset get _anchor => prop.anchorFor(roomId);
  Offset get _center => Offset(_anchor.dx * stage.width, _anchor.dy * stage.height);

  Size get _pixelSize {
    final w = prop.effectiveSizeNorm * stage.width;
    return Size(w, w * prop.effectiveAspectRatio);
  }

  @override
  Widget build(BuildContext context) {
    if (smashed) return const SizedBox.shrink();

    final center = _center;
    final size = _pixelSize;
    const pad = 12.0;
    final hitW = spriteMode ? size.width + pad : 72.0;
    final hitH = spriteMode ? size.height + pad : 72.0;

    final accent = holding
        ? AppTheme.gold
        : throwTarget
            ? const Color(0xFFFFEB3B)
            : Colors.white;

    return Positioned(
      left: center.dx - hitW / 2,
      top: center.dy - hitH / 2,
      width: hitW,
      height: hitH + (spriteMode ? 0 : 18),
      child: Semantics(
        button: true,
        enabled: !smashed,
        label: smashed ? null : '${prop.label}, smashable object in room',
        hint: holding
            ? 'Selected — tap another object to throw'
            : throwTarget
                ? 'Throw target'
                : 'Tap to smash',
        onTap: smashed ? null : () => onTap(center),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(center),
          child: spriteMode
            ? _SpriteProp(
                prop: prop,
                roomId: roomId,
                size: size,
                pulse: pulse,
                holding: holding,
                throwTarget: throwTarget,
                accent: accent,
              )
            : _LegacyPin(
                prop: prop,
                pulse: pulse,
                holding: holding,
                throwTarget: throwTarget,
                accent: accent,
              ),
        ),
      ),
    );
  }
}

class _SpriteProp extends StatelessWidget {
  const _SpriteProp({
    required this.prop,
    required this.roomId,
    required this.size,
    required this.pulse,
    required this.holding,
    required this.throwTarget,
    required this.accent,
  });

  final RoomProp prop;
  final String roomId;
  final Size size;
  final Animation<double> pulse;
  final bool holding;
  final bool throwTarget;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = 0.12 + pulse.value * 0.28;
        return Transform.scale(
          scale: holding ? 1.06 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: glow),
                  blurRadius: 14 + pulse.value * 10,
                  spreadRadius: throwTarget ? 2 : 0,
                ),
              ],
            ),
            child: Image.asset(
              prop.resolvedSprite(roomId),
              width: size.width,
              height: size.height,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  color: prop.color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent, width: 2),
                ),
                child: Icon(prop.icon, color: Colors.white, size: size.width * 0.4),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LegacyPin extends StatelessWidget {
  const _LegacyPin({
    required this.prop,
    required this.pulse,
    required this.holding,
    required this.throwTarget,
    required this.accent,
  });

  final RoomProp prop;
  final Animation<double> pulse;
  final bool holding;
  final bool throwTarget;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final ringScale = 1 + pulse.value * 0.22;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: holding ? 1.1 : 1,
              child: _pin(accent, ringScale: ringScale),
            ),
            const SizedBox(height: 4),
            Text(
              prop.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.92),
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.95),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pin(Color accent, {required double ringScale}) {
    const core = 12.0;
    const ring = 36.0;
    return SizedBox(
      width: ring * ringScale * 1.4,
      height: ring * ringScale * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: ring * ringScale,
            height: ring * ringScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.55), width: 2),
            ),
          ),
          Container(
            width: core,
            height: core,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
