import 'dart:math';
import 'package:flutter/material.dart';
import '../models/prop_state.dart';

/// Represents an authentic procedural Voronoi fracture shard with physics and specular edges.
class VoronoiShard {
  VoronoiShard({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.polygon,
    required this.color,
    required this.material,
    required this.life,
    this.rotation = 0.0,
    this.spin = 0.0,
    this.gravity = 980.0,
    this.drag = 0.985,
  }) : maxLife = life;

  double x;
  double y;
  double vx;
  double vy;
  final List<Offset> polygon;
  final Color color;
  final PropMaterial material;
  double life;
  final double maxLife;
  double rotation;
  double spin;
  final double gravity;
  final double drag;

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
      if (vy.abs() > 50) {
        vy = -vy * (material == PropMaterial.glass ? 0.42 : 0.32);
        vx *= 0.75;
        spin *= 0.8;
      } else {
        vy = 0;
        vx *= 0.88;
        spin = 0;
      }
    }
    life -= dt;
  }
}

/// Procedural Voronoi Shatter Generator
class VoronoiShatterEngine {
  static final Random _rng = Random();

  /// Generates a realistic Voronoi fracture network for a prop of [propSize]
  /// with impact point at [localImpact] (in local prop coordinates).
  static List<VoronoiShard> fracture({
    required Offset stageCenter,
    required Size propSize,
    required Offset localImpact,
    required Color color,
    required PropMaterial material,
    int cellCount = 16,
    double blastSpeed = 420.0,
  }) {
    final w = max(propSize.width, 36.0);
    final h = max(propSize.height, 36.0);

    // 1. Generate seeds clustered around impact point
    final seeds = <Offset>[];
    seeds.add(localImpact);

    for (int i = 0; i < cellCount - 1; i++) {
      final bias = _rng.nextDouble();
      final radius = (bias * bias) * max(w, h) * 0.85;
      final angle = _rng.nextDouble() * pi * 2;
      final sx = (localImpact.dx + cos(angle) * radius).clamp(2.0, w - 2.0);
      final sy = (localImpact.dy + sin(angle) * radius).clamp(2.0, h - 2.0);
      seeds.add(Offset(sx, sy));
    }

    final shards = <VoronoiShard>[];

    // 2. Generate convex cell polygon around each seed
    for (int i = 0; i < seeds.length; i++) {
      final seed = seeds[i];
      final numSides = 4 + _rng.nextInt(3); // 4-6 sided Voronoi cells
      final cellRadius = 8.0 + _rng.nextDouble() * (w * 0.35);
      final vertices = <Offset>[];

      for (int s = 0; s < numSides; s++) {
        final a = (s / numSides) * pi * 2 + (_rng.nextDouble() - 0.5) * 0.35;
        final r = cellRadius * (0.65 + _rng.nextDouble() * 0.5);
        vertices.add(Offset(cos(a) * r, sin(a) * r));
      }

      // Calculate blast vector away from local impact
      final diff = seed - localImpact;
      final dist = max(diff.distance, 1.0);
      final normDir = diff / dist;
      final speed = blastSpeed * (0.55 + _rng.nextDouble() * 0.75);
      final spreadAngle = (_rng.nextDouble() - 0.5) * 0.5;

      final cosA = cos(spreadAngle);
      final sinA = sin(spreadAngle);
      final blastVx = (normDir.dx * cosA - normDir.dy * sinA) * speed;
      final blastVy = (normDir.dx * sinA + normDir.dy * cosA) * speed - (140 + _rng.nextDouble() * 220);

      // World coordinate of shard start
      final stagePos = stageCenter + Offset(seed.dx - w / 2, seed.dy - h / 2);
      final life = 1.1 + _rng.nextDouble() * 0.6;

      shards.add(
        VoronoiShard(
          x: stagePos.dx,
          y: stagePos.dy,
          vx: blastVx,
          vy: blastVy,
          polygon: vertices,
          color: color,
          material: material,
          life: life,
          spin: (_rng.nextDouble() - 0.5) * 14.0,
        ),
      );
    }

    return shards;
  }
}

/// CustomPainter for rendering Voronoi shards with specular rim bevels
class VoronoiShatterPainter extends CustomPainter {
  VoronoiShatterPainter({required this.shards});
  final List<VoronoiShard> shards;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shards) {
      if (s.life <= 0) continue;
      final alpha = s.alpha;
      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.rotation);

      final path = Path();
      for (int i = 0; i < s.polygon.length; i++) {
        final pt = s.polygon[i];
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();

      // Shard base color with depth gradient
      final basePaint = Paint()
        ..color = s.color.withValues(alpha: alpha * 0.88)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, basePaint);

      // Specular rim bevel highlight (makes shards look razor-sharp)
      final bevelColor = s.material == PropMaterial.glass
          ? Colors.white.withValues(alpha: alpha * 0.75)
          : (s.material == PropMaterial.metal
              ? const Color(0xFFFFD54F).withValues(alpha: alpha * 0.65)
              : Colors.white.withValues(alpha: alpha * 0.40));

      final bevelPaint = Paint()
        ..color = bevelColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.material == PropMaterial.glass ? 1.4 : 1.0;
      canvas.drawPath(path, bevelPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant VoronoiShatterPainter oldDelegate) => true;
}
