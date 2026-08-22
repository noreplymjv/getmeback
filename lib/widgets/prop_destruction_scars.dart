import 'dart:math';

import 'package:flutter/material.dart';

import '../models/prop_state.dart';
import '../models/room_setup.dart';

/// Persistent visual damage left behind when a prop is smashed.
class DestructionScar {
  const DestructionScar({
    required this.center,
    required this.extent,
    required this.material,
    required this.style,
    required this.tint,
    required this.seed,
  });

  final Offset center;
  final Size extent;
  final PropMaterial material;
  final PropSmashStyle style;
  final Color tint;
  final int seed;

  static DestructionScar fromProp({
    required RoomProp prop,
    required String roomId,
    required Size stage,
    required Offset center,
    required PropSmashStyle style,
  }) {
    final w = prop.effectiveSizeNorm * stage.width * 1.2;
    return DestructionScar(
      center: center,
      extent: Size(w, w * prop.effectiveAspectRatio * 1.15),
      material: prop.effectiveMaterial,
      style: style,
      tint: prop.color,
      seed: Object.hash(roomId, prop.id, center.dx.round(), center.dy.round()),
    );
  }
}

/// Draws material-specific wreckage marks on the room surface.
class DestructionScarsLayer extends StatelessWidget {
  const DestructionScarsLayer({super.key, required this.scars});

  final List<DestructionScar> scars;

  @override
  Widget build(BuildContext context) {
    if (scars.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _DestructionScarsPainter(scars: scars),
        size: Size.infinite,
      ),
    );
  }
}

class _DestructionScarsPainter extends CustomPainter {
  _DestructionScarsPainter({required this.scars});

  final List<DestructionScar> scars;

  @override
  void paint(Canvas canvas, Size size) {
    for (final scar in scars) {
      if (scar.style == PropSmashStyle.spill || scar.style == PropSmashStyle.splash) {
        _drawSpill(canvas, scar);
        continue;
      }
      switch (scar.material) {
        case PropMaterial.glass:
          _drawGlass(canvas, scar);
        case PropMaterial.ceramic:
          _drawCeramic(canvas, scar);
        case PropMaterial.wood:
          _drawWood(canvas, scar);
        case PropMaterial.metal:
          _drawMetal(canvas, scar);
        case PropMaterial.fabric:
          _drawFabric(canvas, scar);
        case PropMaterial.plastic:
          _drawCeramic(canvas, scar);
      }
    }
  }

  Random _rng(DestructionScar s) => Random(s.seed);

  Rect _rect(DestructionScar s) => Rect.fromCenter(
        center: s.center,
        width: s.extent.width,
        height: s.extent.height,
      );

  void _drawSpill(Canvas canvas, DestructionScar s) {
    final r = _rng(s);
    final rect = _rect(s);
    final puddle = Rect.fromCenter(
      center: s.center.translate(0, rect.height * 0.12),
      width: rect.width * (1.1 + r.nextDouble() * 0.35),
      height: rect.height * (0.45 + r.nextDouble() * 0.2),
    );
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4FC3F7).withValues(alpha: 0.55),
          const Color(0xFF0288D1).withValues(alpha: 0.35),
          const Color(0xFF01579B).withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(puddle);
    canvas.drawOval(puddle, paint);
    canvas.drawOval(
      puddle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    for (var i = 0; i < 5; i++) {
      final drip = Offset(
        puddle.center.dx + (r.nextDouble() - 0.5) * puddle.width * 0.6,
        puddle.bottom + r.nextDouble() * rect.height * 0.25,
      );
      canvas.drawCircle(
        drip,
        2 + r.nextDouble() * 3,
        Paint()..color = const Color(0xFF4FC3F7).withValues(alpha: 0.4),
      );
    }
  }

  void _drawGlass(Canvas canvas, DestructionScar s) {
    final r = _rng(s);
    final rect = _rect(s);
    _drawImpactCrater(canvas, s, depth: 0.35, color: const Color(0xFF263238));

    final rays = 8 + r.nextInt(5);
    for (var i = 0; i < rays; i++) {
      final angle = (i / rays) * pi * 2 + r.nextDouble() * 0.25;
      final len = rect.shortestSide * (0.45 + r.nextDouble() * 0.55);
      final end = s.center + Offset(cos(angle), sin(angle)) * len;
      canvas.drawLine(
        s.center,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55 + r.nextDouble() * 0.25)
          ..strokeWidth = 0.8 + r.nextDouble() * 1.2
          ..strokeCap = StrokeCap.round,
      );
      if (r.nextBool()) {
        _drawShard(canvas, end, 3 + r.nextDouble() * 5, s.tint, r.nextDouble() * pi);
      }
    }
    _scatterChips(canvas, s, count: 10, light: true);
  }

  void _drawCeramic(Canvas canvas, DestructionScar s) {
    final r = _rng(s);
    final rect = _rect(s);
    _drawImpactCrater(canvas, s, depth: 0.5, color: const Color(0xFF3E2723));

    final crater = Rect.fromCenter(
      center: s.center,
      width: rect.width * 0.35,
      height: rect.height * 0.3,
    );
    canvas.drawOval(
      crater,
      Paint()..color = const Color(0xFF1A1110).withValues(alpha: 0.45),
    );

    for (var i = 0; i < 7 + r.nextInt(4); i++) {
      final angle = r.nextDouble() * pi * 2;
      final len = rect.shortestSide * (0.35 + r.nextDouble() * 0.65);
      canvas.drawLine(
        s.center,
        s.center + Offset(cos(angle), sin(angle)) * len,
        Paint()
          ..color = const Color(0xFF4E342E).withValues(alpha: 0.75)
          ..strokeWidth = 1 + r.nextDouble() * 1.5,
      );
    }
    _scatterChips(canvas, s, count: 16, light: true);
    _scatterChips(canvas, s, count: 8, light: false);
  }

  void _drawWood(Canvas canvas, DestructionScar s) {
    final r = _rng(s);
    final rect = _rect(s);
    _drawImpactCrater(canvas, s, depth: 0.4, color: const Color(0xFF2E1B0F));

    for (var i = 0; i < 4 + r.nextInt(3); i++) {
      final y = s.center.dy + (i - 2) * rect.height * 0.12;
      final start = Offset(s.center.dx - rect.width * 0.45, y + r.nextDouble() * 4);
      final end = Offset(s.center.dx + rect.width * 0.45, y + r.nextDouble() * 4);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFF1B0F08).withValues(alpha: 0.7)
          ..strokeWidth = 2 + r.nextDouble() * 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var i = 0; i < 6; i++) {
      final angle = -0.4 + r.nextDouble() * 0.8;
      final len = rect.shortestSide * (0.15 + r.nextDouble() * 0.25);
      final origin = s.center + Offset((r.nextDouble() - 0.5) * rect.width * 0.5, 0);
      _drawSplinter(canvas, origin, len, angle, s.tint);
    }
  }

  void _drawMetal(Canvas canvas, DestructionScar s) {
    final r = _rng(s);
    final rect = _rect(s);
    for (var ring = 3; ring >= 1; ring--) {
      canvas.drawOval(
        Rect.fromCenter(
          center: s.center,
          width: rect.width * (0.25 + ring * 0.12),
          height: rect.height * (0.22 + ring * 0.1),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.black.withValues(alpha: 0.25 + ring * 0.08),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: s.center, width: rect.width * 0.18, height: rect.height * 0.15),
      Paint()..color = const Color(0xFF212121).withValues(alpha: 0.55),
    );

    for (var i = 0; i < 8; i++) {
      final angle = r.nextDouble() * pi;
      final len = rect.shortestSide * 0.5;
      canvas.drawLine(
        s.center,
        s.center + Offset(cos(angle), sin(angle)) * len,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 0.8,
      );
    }
    for (var i = 0; i < 6; i++) {
      final spark = s.center + Offset((r.nextDouble() - 0.5) * rect.width, (r.nextDouble() - 0.5) * rect.height);
      canvas.drawLine(
        spark,
        spark + Offset(4 + r.nextDouble() * 8, 0),
        Paint()
          ..color = const Color(0xFFFFE082).withValues(alpha: 0.7)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawFabric(Canvas canvas, DestructionScar s) {
    final r = _rng(s);
    final rect = _rect(s);
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2;
      final radius = rect.shortestSide * (0.35 + r.nextDouble() * 0.2);
      points.add(s.center + Offset(cos(angle), sin(angle)) * radius);
    }
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF1A1410).withValues(alpha: 0.35),
    );
    for (var i = 0; i < 5; i++) {
      final start = s.center + Offset((r.nextDouble() - 0.5) * rect.width, 0);
      canvas.drawLine(
        start,
        start + Offset((r.nextDouble() - 0.5) * 20, rect.height * 0.35),
        Paint()
          ..color = s.tint.withValues(alpha: 0.45)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawImpactCrater(Canvas canvas, DestructionScar s, {required double depth, required Color color}) {
    final rect = _rect(s);
    final shadow = Rect.fromCenter(
      center: s.center,
      width: rect.width * (0.85 + depth * 0.2),
      height: rect.height * (0.75 + depth * 0.15),
    );
    canvas.drawOval(
      shadow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(shadow),
    );
  }

  void _scatterChips(Canvas canvas, DestructionScar s, {required int count, required bool light}) {
    final r = _rng(s);
    final rect = _rect(s);
    for (var i = 0; i < count; i++) {
      final pt = s.center +
          Offset(
            (r.nextDouble() - 0.5) * rect.width * 1.1,
            (r.nextDouble() - 0.5) * rect.height * 1.1,
          );
      _drawShard(
        canvas,
        pt,
        2 + r.nextDouble() * (light ? 4 : 6),
        light ? Colors.white : s.tint,
        r.nextDouble() * pi,
      );
    }
  }

  void _drawShard(Canvas canvas, Offset at, double size, Color color, double rot) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(rot);
    final path = Path()
      ..moveTo(0, -size)
      ..lineTo(size * 0.55, size * 0.45)
      ..lineTo(-size * 0.55, size * 0.45)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
    canvas.restore();
  }

  void _drawSplinter(Canvas canvas, Offset at, double len, double angle, Color tint) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(len / 2, 0), width: len, height: 3.5),
        const Radius.circular(1),
      ),
      Paint()..color = Color.lerp(tint, const Color(0xFF3E2723), 0.45)!,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DestructionScarsPainter old) => old.scars.length != scars.length;
}
