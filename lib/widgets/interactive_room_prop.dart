import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/prop_state.dart';
import '../models/room_setup.dart';
import '../theme/app_theme.dart';

/// Renders a real prop sprite with multi-stage dynamic destruction and smash juice animation.
class InteractiveRoomProp extends StatefulWidget {
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
  final bool smashing;
  final bool holding;
  final bool throwTarget;
  final bool spriteMode;
  final ValueChanged<Offset> onTap;
  final int damageStage;
  final int maxDamageStage;

  @override
  State<InteractiveRoomProp> createState() => _InteractiveRoomPropState();
}

class _InteractiveRoomPropState extends State<InteractiveRoomProp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _smash;
  double _hitWobble = 0.0;

  Offset get _anchor => widget.prop.anchorFor(widget.roomId);
  Offset get _center =>
      Offset(_anchor.dx * widget.stage.width, _anchor.dy * widget.stage.height);

  Size get _pixelSize {
    final w = widget.prop.effectiveSizeNorm * widget.stage.width;
    return Size(w, w * widget.prop.effectiveAspectRatio);
  }

  @override
  void initState() {
    super.initState();
    _smash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    if (widget.smashing) {
      _smash.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveRoomProp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.smashing && !oldWidget.smashing) {
      _smash.forward(from: 0);
    }
    if (!widget.smashing && !widget.smashed) {
      _smash.value = 0;
    }
    if (widget.damageStage > oldWidget.damageStage) {
      _triggerWobble();
    }
  }

  void _triggerWobble() {
    setState(() => _hitWobble = (math.Random().nextBool() ? 1.0 : -1.0) * 0.12);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _hitWobble = 0.0);
    });
  }

  @override
  void dispose() {
    _smash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.smashed && !widget.smashing) {
      return const SizedBox.shrink();
    }

    final center = _center;
    final size = _pixelSize;
    const pad = 16.0;
    final hitW = widget.spriteMode ? size.width + pad : 72.0;
    final hitH = widget.spriteMode ? size.height + pad : 72.0;

    final accent = widget.holding
        ? AppTheme.gold
        : widget.throwTarget
            ? const Color(0xFFFFEB3B)
            : Colors.white;

    return Positioned(
      left: center.dx - hitW / 2,
      top: center.dy - hitH / 2,
      width: hitW,
      height: hitH + (widget.spriteMode ? 0 : 18),
      child: Semantics(
        button: true,
        enabled: !widget.smashed && !widget.smashing,
        label: widget.smashed
            ? null
            : '${widget.prop.label}, ${widget.damageStage > 0 ? "Damaged " : ""}smashable object in room',
        hint: widget.holding
            ? 'Selected — tap another object to throw'
            : widget.throwTarget
                ? 'Throw target'
                : 'Tap to smash (${widget.damageStage}/${widget.maxDamageStage} hits)',
        onTap: (widget.smashed || widget.smashing)
            ? null
            : () => widget.onTap(center),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!widget.smashed && !widget.smashing) {
              widget.onTap(center);
            }
          },
          child: widget.spriteMode
              ? _SpriteProp(
                  prop: widget.prop,
                  roomId: widget.roomId,
                  size: size,
                  pulse: widget.pulse,
                  holding: widget.holding,
                  throwTarget: widget.throwTarget,
                  accent: accent,
                  smash: _smash,
                  smashStyle: widget.prop.style,
                  damageStage: widget.damageStage,
                  maxDamageStage: widget.maxDamageStage,
                  hitWobble: _hitWobble,
                )
              : _LegacyPin(
                  prop: widget.prop,
                  pulse: widget.pulse,
                  holding: widget.holding,
                  throwTarget: widget.throwTarget,
                  accent: accent,
                  damageStage: widget.damageStage,
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
    required this.smash,
    required this.smashStyle,
    required this.damageStage,
    required this.maxDamageStage,
    required this.hitWobble,
  });

  final RoomProp prop;
  final String roomId;
  final Size size;
  final Animation<double> pulse;
  final bool holding;
  final bool throwTarget;
  final Color accent;
  final AnimationController smash;
  final PropSmashStyle smashStyle;
  final int damageStage;
  final int maxDamageStage;
  final double hitWobble;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulse, smash]),
      builder: (context, _) {
        final glow = 0.12 + pulse.value * 0.28;
        final t = Curves.easeIn.transform(smash.value);
        late final double scaleX;
        late final double scaleY;
        late final double angle;
        late final double opacity;
        late final Offset slide;

        switch (smashStyle) {
          case PropSmashStyle.tipOver:
            scaleX = 1 - t * 0.15;
            scaleY = 1 - t * 0.35;
            angle = t * (math.pi / 2.4) + hitWobble + (damageStage > 0 ? (damageStage * 0.05) : 0);
            opacity = 1 - t;
            slide = Offset(t * size.width * 0.25, t * size.height * 0.35);
            break;
          case PropSmashStyle.smashFlat:
            scaleX = 1 + t * 0.35 + (damageStage > 0 ? (damageStage * 0.04) : 0);
            scaleY = 1 - t * 0.85 - (damageStage > 0 ? (damageStage * 0.04) : 0);
            angle = t * 0.08 + hitWobble;
            opacity = 1 - t;
            slide = Offset(0, t * size.height * 0.2);
            break;
          case PropSmashStyle.shatter:
          case PropSmashStyle.crack:
          case PropSmashStyle.explode:
            scaleX = 1 + t * 0.25;
            scaleY = 1 + t * 0.25;
            angle = t * 0.4 + hitWobble;
            opacity = 1 - Curves.easeIn.transform(t);
            slide = Offset.zero;
            break;
          case PropSmashStyle.spill:
          case PropSmashStyle.splash:
            scaleX = 1 + t * 0.5;
            scaleY = 1 - t * 0.55;
            angle = hitWobble;
            opacity = 1 - t;
            slide = Offset(0, t * size.height * 0.15);
            break;
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: slide,
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scaleX: (holding ? 1.06 : 1) * scaleX,
                scaleY: (holding ? 1.06 : 1) * scaleY,
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: glow * (1 - t)),
                        blurRadius: 14 + pulse.value * 10,
                        spreadRadius: throwTarget ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Base Prop Sprite
                      Image.asset(
                        prop.resolvedSprite(roomId),
                        width: size.width,
                        height: size.height,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => Container(
                          width: size.width,
                          height: size.height,
                          decoration: BoxDecoration(
                            color: prop.color.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent, width: 2),
                          ),
                          child: Icon(
                            prop.icon,
                            color: Colors.white,
                            size: size.width * 0.4,
                          ),
                        ),
                      ),
                      // Multi-stage Fracture Crack Decals Overlay
                      if (damageStage > 0)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PropCrackPainter(
                              stage: damageStage,
                              maxStage: maxDamageStage,
                              material: prop.effectiveMaterial,
                              seed: Object.hash(roomId, prop.id),
                            ),
                          ),
                        ),
                      // Hit damage indicator bar (when partially damaged)
                      if (damageStage > 0 && damageStage < maxDamageStage && !holding)
                        Positioned(
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.8),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(maxDamageStage, (index) {
                                final isHit = index < damageStage;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isHit ? Colors.amberAccent : Colors.white24,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for rendering procedural crack lines and fractures directly on the prop sprite.
class _PropCrackPainter extends CustomPainter {
  _PropCrackPainter({
    required this.stage,
    required this.maxStage,
    required this.material,
    required this.seed,
  });

  final int stage;
  final int maxStage;
  final PropMaterial material;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final intensity = (stage / maxStage).clamp(0.2, 1.0);
    final center = Offset(size.width * 0.5, size.height * 0.5);

    final crackPaint = Paint()
      ..color = (material == PropMaterial.glass ? Colors.white : const Color(0xFF263238)).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 + intensity * 1.0
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final branchCount = (3 + stage * 2).clamp(3, 8);
    for (var i = 0; i < branchCount; i++) {
      final angle = (i / branchCount) * math.pi * 2 + (rng.nextDouble() - 0.5) * 0.5;
      final maxLen = (size.width * 0.45) * (0.5 + rng.nextDouble() * 0.5 * intensity);

      var curr = center + Offset((rng.nextDouble() - 0.5) * 6, (rng.nextDouble() - 0.5) * 6);
      final steps = 3 + rng.nextInt(3);

      for (var s = 0; s < steps; s++) {
        final stepLen = maxLen / steps;
        final stepAngle = angle + (rng.nextDouble() - 0.5) * 0.6;
        final next = curr + Offset(math.cos(stepAngle) * stepLen, math.sin(stepAngle) * stepLen);

        canvas.drawLine(curr, next, crackPaint);
        if (material == PropMaterial.glass) {
          canvas.drawLine(curr + const Offset(0.8, -0.8), next + const Offset(0.8, -0.8), highlightPaint);
        }

        // Sub-branches on heavier damage
        if (stage >= 2 && rng.nextBool()) {
          final subAngle = stepAngle + (rng.nextBool() ? 0.7 : -0.7);
          final subEnd = next + Offset(math.cos(subAngle) * stepLen * 0.6, math.sin(subAngle) * stepLen * 0.6);
          canvas.drawLine(next, subEnd, crackPaint);
        }

        curr = next;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PropCrackPainter old) =>
      old.stage != stage || old.maxStage != maxStage;
}

class _LegacyPin extends StatelessWidget {
  const _LegacyPin({
    required this.prop,
    required this.pulse,
    required this.holding,
    required this.throwTarget,
    required this.accent,
    this.damageStage = 0,
  });

  final RoomProp prop;
  final Animation<double> pulse;
  final bool holding;
  final bool throwTarget;
  final Color accent;
  final int damageStage;

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
