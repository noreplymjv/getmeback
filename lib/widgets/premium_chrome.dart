import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated luxury backdrop: shifting aurora + floating sparkles.
class PremiumBackdrop extends StatefulWidget {
  const PremiumBackdrop({
    super.key,
    required this.child,
    this.intensity = 1,
    this.calm = false,
  });

  final Widget child;
  final double intensity;
  final bool calm;

  @override
  State<PremiumBackdrop> createState() => _PremiumBackdropState();
}

class _PremiumBackdropState extends State<PremiumBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value * pi * 2;
        final dx = 0.12 * sin(t);
        final dy = 0.1 * cos(t * 0.8);
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppTheme.background),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.55 + dx, -0.85 + dy),
                  radius: 1.15,
                  colors: [
                    (widget.calm ? AppTheme.calm : AppTheme.accent)
                        .withValues(alpha: 0.28 * widget.intensity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.85 - dx, 0.7 + dy),
                  radius: 1.05,
                  colors: [
                    AppTheme.gold.withValues(alpha: 0.14 * widget.intensity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.2 + dy, 0.95),
                  radius: 0.9,
                  colors: [
                    AppTheme.accentSecondary
                        .withValues(alpha: 0.1 * widget.intensity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: _SparklePainter(
                t: _ctrl.value,
                calm: widget.calm,
                intensity: widget.intensity,
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.t,
    required this.calm,
    required this.intensity,
  });

  final double t;
  final bool calm;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    final count = (28 * intensity).round().clamp(12, 40);
    for (var i = 0; i < count; i++) {
      final baseX = rng.nextDouble();
      final baseY = rng.nextDouble();
      final speed = 0.08 + rng.nextDouble() * 0.18;
      final y = ((baseY + t * speed) % 1.0) * size.height;
      final x = (baseX + sin((t + i) * pi * 2) * 0.03) * size.width;
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * sin((t * 8 + i) * pi));
      final paint = Paint()
        ..color = (calm
                ? AppTheme.calm
                : (i.isEven ? AppTheme.gold : Colors.white))
            .withValues(alpha: 0.18 * twinkle * intensity);
      canvas.drawCircle(Offset(x, y), 1.2 + rng.nextDouble() * 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.t != t;
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.goldEdge = false,
    this.blur = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool goldEdge;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: goldEdge
              ? AppTheme.gold.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          if (goldEdge)
            BoxShadow(
              color: AppTheme.gold.withValues(alpha: 0.12),
              blurRadius: 28,
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: panel,
            )
          : panel,
    );
  }
}

class ShineButton extends StatefulWidget {
  const ShineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  State<ShineButton> createState() => _ShineButtonState();
}

class _ShineButtonState extends State<ShineButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return AnimatedBuilder(
      animation: _shine,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: (widget.color ?? AppTheme.accent)
                          .withValues(alpha: 0.38),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            ElevatedButton.icon(
              onPressed: widget.onPressed,
              icon: Icon(widget.icon ?? Icons.auto_awesome),
              label: Text(widget.label),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color ?? AppTheme.accent,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            if (enabled)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shine,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset((_shine.value * 2 - 0.5) * 280, 0),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(
                          width: 40,
                          height: 80,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class GradientTitle extends StatelessWidget {
  const GradientTitle(this.text, {super.key, this.size = 38});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppTheme.heroGradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.05,
          color: Colors.white,
        ),
      ),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.08),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final delayMs = delay.inMilliseconds.toDouble();
    final total = 560 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total.round()),
      curve: Curves.linear,
      builder: (context, value, child) {
        final start = delayMs / total;
        final t = start >= 1
            ? 1.0
            : ((value - start) / (1 - start)).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(
              offset.dx * 24 * (1 - eased),
              offset.dy * 28 * (1 - eased),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
