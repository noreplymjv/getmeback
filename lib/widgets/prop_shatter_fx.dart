import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Material-specific debris burst for prop smash scenes.
enum PropShatterStyle { glass, ceramic, wood, metal }

class PropShatterShard {
  PropShatterShard({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.maxLife,
    required this.style,
    this.rotation = 0,
    this.spin = 0,
    this.gravity = 820,
    this.drag = 0.988,
    this.vertices = const [],
    this.aspect = 1,
  });

  double x, y, vx, vy, size, rotation, spin, life, maxLife, gravity, drag, aspect;
  Color color;
  PropShatterStyle style;
  List<Offset> vertices;

  double get alpha => (life / maxLife).clamp(0.0, 1.0);

  void tick(double dt, {double? floorY}) {
    x += vx * dt;
    y += vy * dt;
    vy += gravity * dt;
    vx *= drag;
    vy *= drag;
    rotation += spin * dt;

    if (floorY != null && y >= floorY) {
      y = floorY;
      if (vy.abs() > 40) {
        vy = -vy * 0.38;
        vx *= 0.72;
        spin *= 0.85;
      } else {
        vy = 0;
        vx *= 0.92;
      }
    }

    life -= dt;
  }
}

class PropShatterController extends ChangeNotifier {
  PropShatterController();

  final _rng = Random();
  final List<PropShatterShard> shards = [];

  /// Stage Y coordinate for floor collision (null = no floor).
  double? floorY;

  void burst({
    required Offset at,
    Color color = const Color(0xFFECEFF1),
    PropShatterStyle style = PropShatterStyle.ceramic,
    int count = 24,
    List<Color>? palette,
  }) {
    final cfg = _cfg(style);
    final colors = (palette == null || palette.isEmpty)
        ? <Color>[color]
        : palette;
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = cfg.minSpeed + _rng.nextDouble() * cfg.speedRange;
      final life = cfg.life + _rng.nextDouble() * cfg.lifeVar;
      final shardColor = colors[_rng.nextInt(colors.length)];
      shards.add(
        PropShatterShard(
          x: at.dx + (_rng.nextDouble() - 0.5) * cfg.spread,
          y: at.dy + (_rng.nextDouble() - 0.5) * cfg.spread,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - cfg.lift,
          size: cfg.minSize + _rng.nextDouble() * cfg.sizeRange,
          color: _tint(shardColor, style),
          life: life,
          maxLife: life,
          style: style,
          rotation: _rng.nextDouble() * pi,
          spin: (_rng.nextDouble() - 0.5) * cfg.spin,
          gravity: cfg.gravity,
          drag: cfg.drag,
          vertices: _verts(style),
          aspect: style == PropShatterStyle.wood ? 0.55 + _rng.nextDouble() * 0.35 : 1,
        ),
      );
    }
    notifyListeners();
  }

  void tick(double dt) {
    if (shards.isEmpty) return;
    for (final s in shards) {
      s.tick(dt, floorY: floorY);
    }
    final before = shards.length;
    shards.removeWhere((s) => s.life <= 0);
    if (before > 0) notifyListeners();
  }

  void clear() {
    if (shards.isEmpty) return;
    shards.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    shards.clear();
    super.dispose();
  }

  static _ShardCfg _cfg(PropShatterStyle s) => switch (s) {
        PropShatterStyle.glass => const _ShardCfg(
            minSpeed: 180, speedRange: 420, lift: 140, minSize: 6, sizeRange: 14,
            life: 0.9, lifeVar: 0.5, spin: 14, gravity: 760, drag: 0.992, spread: 18,
          ),
        PropShatterStyle.ceramic => const _ShardCfg(
            minSpeed: 160, speedRange: 380, lift: 120, minSize: 7, sizeRange: 16,
            life: 1.1, lifeVar: 0.6, spin: 12, gravity: 880, drag: 0.988, spread: 22,
          ),
        PropShatterStyle.wood => const _ShardCfg(
            minSpeed: 120, speedRange: 280, lift: 80, minSize: 8, sizeRange: 18,
            life: 1.3, lifeVar: 0.7, spin: 8, gravity: 920, drag: 0.985, spread: 26,
          ),
        PropShatterStyle.metal => const _ShardCfg(
            minSpeed: 260, speedRange: 520, lift: 60, minSize: 2, sizeRange: 5,
            life: 0.35, lifeVar: 0.25, spin: 22, gravity: 420, drag: 0.975, spread: 10,
          ),
      };

  Color _tint(Color base, PropShatterStyle style) {
    final t = _rng.nextDouble();
    return switch (style) {
      PropShatterStyle.glass => Color.lerp(base, Colors.white, 0.35 + t * 0.35)!,
      PropShatterStyle.ceramic => Color.lerp(base, const Color(0xFFBCAAA4), t * 0.25)!,
      PropShatterStyle.wood => Color.lerp(
          base,
          Color.lerp(const Color(0xFF6D4C41), const Color(0xFF8D6E63), t)!,
          0.4 + t * 0.3,
        )!,
      PropShatterStyle.metal => Color.lerp(
          base,
          Color.lerp(Colors.white, const Color(0xFFFFE082), t)!,
          0.5 + t * 0.4,
        )!,
    };
  }

  List<Offset> _verts(PropShatterStyle style) {
    switch (style) {
      case PropShatterStyle.glass:
        return [
          Offset(0, -1),
          Offset(0.45 + _rng.nextDouble() * 0.15, 0.55),
          Offset(-0.45 - _rng.nextDouble() * 0.15, 0.55),
        ];
      case PropShatterStyle.ceramic:
        return [
          Offset(-0.5 - _rng.nextDouble() * 0.2, -0.4),
          Offset(0.5 + _rng.nextDouble() * 0.15, -0.35),
          Offset(0.45, 0.5),
          Offset(-0.45, 0.45),
        ];
      case PropShatterStyle.wood:
        return [
          const Offset(-0.5, -0.35),
          const Offset(0.5, -0.35),
          const Offset(0.5, 0.35),
          const Offset(-0.5, 0.35),
        ];
      case PropShatterStyle.metal:
        return const [];
    }
  }
}

class _ShardCfg {
  const _ShardCfg({
    required this.minSpeed,
    required this.speedRange,
    required this.lift,
    required this.minSize,
    required this.sizeRange,
    required this.life,
    required this.lifeVar,
    required this.spin,
    required this.gravity,
    required this.drag,
    required this.spread,
  });

  final double minSpeed, speedRange, lift, minSize, sizeRange;
  final double life, lifeVar, spin, gravity, drag, spread;
}

class PropShatterOverlay extends StatelessWidget {
  const PropShatterOverlay({super.key, required this.shards, this.child});

  final List<PropShatterShard> shards;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ?child,
        IgnorePointer(
          child: CustomPaint(painter: _PropShatterPainter(shards: shards)),
        ),
      ],
    );
  }
}

class _PropShatterPainter extends CustomPainter {
  _PropShatterPainter({required this.shards});

  final List<PropShatterShard> shards;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shards) {
      final a = s.alpha;
      if (a <= 0) continue;
      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.rotation);
      switch (s.style) {
        case PropShatterStyle.glass:
          _poly(canvas, s, a * 0.55, stroke: Colors.white.withValues(alpha: a * 0.35));
        case PropShatterStyle.ceramic:
          _poly(canvas, s, a);
        case PropShatterStyle.wood:
          final paint = Paint()..color = s.color.withValues(alpha: a);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: s.size, height: s.size * s.aspect),
              const Radius.circular(1.5),
            ),
            paint,
          );
        case PropShatterStyle.metal:
          final paint = Paint()
            ..color = s.color.withValues(alpha: a)
            ..strokeWidth = 1.5 + s.size * 0.3
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          final len = s.size * 2.2;
          canvas.drawLine(Offset(-len, 0), Offset(len, 0), paint);
          canvas.drawLine(Offset(0, -len * 0.6), Offset(0, len * 0.6), paint);
      }
      canvas.restore();
    }
  }

  void _poly(Canvas canvas, PropShatterShard s, double alpha, {Color? stroke}) {
    final path = Path();
    for (var i = 0; i < s.vertices.length; i++) {
      final v = s.vertices[i];
      final pt = Offset(v.dx * s.size, v.dy * s.size);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = s.color.withValues(alpha: alpha));
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PropShatterPainter old) => true;
}

class PropShatterTicker extends StatefulWidget {
  const PropShatterTicker({super.key, required this.controller, required this.child});

  final PropShatterController controller;
  final Widget child;

  @override
  State<PropShatterTicker> createState() => _PropShatterTickerState();
}

class _PropShatterTickerState extends State<PropShatterTicker>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero ? 0.016 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    widget.controller.tick(dt.clamp(0.0, 0.05));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Stack debris layer above scene content.
Widget propShatterLayer({
  required PropShatterController shatter,
  required Widget child,
}) {
  return PropShatterOverlay(shards: shatter.shards, child: child);
}
