import 'package:flutter/material.dart';
import '../models/room_setup.dart';
import '../theme/app_theme.dart';

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
    this.smashing = false,
    this.damageStage = 0,
    this.maxDamageStage = 3,
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
  final bool smashing;
  final int damageStage;
  final int maxDamageStage;

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
    final hitW = size.width + pad;
    final hitH = size.height + pad;

    final accent = holding ? AppTheme.gold : throwTarget ? const Color(0xFFFFEB3B) : Colors.white;

    return Positioned(
      left: center.dx - hitW / 2,
      top: center.dy - hitH / 2,
      width: hitW,
      height: hitH,
      child: Semantics(
        button: true,
        enabled: !smashed,
        label: smashed ? null : '${prop.label}, smashable object in room',
        hint: holding ? 'Selected — tap another object to throw' : throwTarget ? 'Throw target' : 'Tap to smash',
        onTap: smashed ? null : () => onTap(center),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(center),
          child: _SubtleReticle(prop: prop, size: size, pulse: pulse, holding: holding, throwTarget: throwTarget, accent: accent),
        ),
      ),
    );
  }
}

class _SubtleReticle extends StatelessWidget {
  const _SubtleReticle({required this.prop, required this.size, required this.pulse, required this.holding, required this.throwTarget, required this.accent});
  final RoomProp prop;
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
        final scale = 1.0 + pulse.value * 0.15;
        final glow = 0.2 + pulse.value * 0.4;
        return Center(
          child: Transform.scale(
            scale: holding ? 1.15 : scale,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  _buildCorner(Alignment.topLeft, glow),
                  _buildCorner(Alignment.topRight, glow),
                  _buildCorner(Alignment.bottomLeft, glow),
                  _buildCorner(Alignment.bottomRight, glow),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (holding || throwTarget) Icon(holding ? Icons.back_hand : Icons.crisis_alert, color: accent, size: 16),
                        const SizedBox(height: 2),
                        Text(
                          prop.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.9),
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4)],
                          ),
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
    );
  }

  Widget _buildCorner(Alignment alignment, double glow) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? BorderSide(color: accent.withValues(alpha: glow), width: 2) : BorderSide.none,
            bottom: alignment.y > 0 ? BorderSide(color: accent.withValues(alpha: glow), width: 2) : BorderSide.none,
            left: alignment.x < 0 ? BorderSide(color: accent.withValues(alpha: glow), width: 2) : BorderSide.none,
            right: alignment.x > 0 ? BorderSide(color: accent.withValues(alpha: glow), width: 2) : BorderSide.none,
          ),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: glow * 0.5), blurRadius: 8, spreadRadius: 2)],
        ),
      ),
    );
  }
}
