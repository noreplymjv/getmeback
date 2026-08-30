import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Interactive weapons for room demolition.
enum SmashWeapon {
  hammer(
    label: 'Hammer',
    icon: Icons.gavel,
    color: Color(0xFFFFB74D),
    sound: 'heavy',
  ),
  baseballBat(
    label: 'Baseball Bat',
    icon: Icons.sports_baseball,
    color: Color(0xFFFF8A65),
    sound: 'wood',
  ),
  laser(
    label: 'Laser Zap',
    icon: Icons.bolt,
    color: Color(0xFF00E5FF),
    sound: 'zap',
  ),
  punch(
    label: 'Power Fist',
    icon: Icons.front_hand,
    color: Color(0xFFFF4081),
    sound: 'hit',
  ),
  wreckingBall(
    label: 'Wrecking Ball',
    icon: Icons.circle,
    color: Color(0xFFB0BEC5),
    sound: 'crush',
  );

  const SmashWeapon({
    required this.label,
    required this.icon,
    required this.color,
    required this.sound,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String sound;
}

/// Active strike animation occurrence.
class WeaponStrikeInstance {
  WeaponStrikeInstance({
    required this.id,
    required this.weapon,
    required this.position,
    required this.createdAt,
    this.durationMs = 280,
  });

  final int id;
  final SmashWeapon weapon;
  final Offset position;
  final DateTime createdAt;
  final int durationMs;

  double get progress {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds;
    return (elapsed / durationMs).clamp(0.0, 1.0);
  }

  bool get isFinished => progress >= 1.0;
}

/// Weapon selector HUD and strike animator overlay.
class SmashWeaponOverlay extends StatelessWidget {
  const SmashWeaponOverlay({
    super.key,
    required this.selectedWeapon,
    required this.onSelectWeapon,
    required this.strikes,
  });

  final SmashWeapon selectedWeapon;
  final ValueChanged<SmashWeapon> onSelectWeapon;
  final List<WeaponStrikeInstance> strikes;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (strikes.isNotEmpty)
          IgnorePointer(
            child: CustomPaint(
              painter: _WeaponStrikePainter(strikes: strikes),
              size: Size.infinite,
            ),
          ),
      ],
    );
  }
}

/// Floating weapon bar for quickly swapping demolition tools.
class SmashWeaponSelectorBar extends StatelessWidget {
  const SmashWeaponSelectorBar({
    super.key,
    required this.selectedWeapon,
    required this.onSelectWeapon,
    this.compact = false,
  });

  final SmashWeapon selectedWeapon;
  final ValueChanged<SmashWeapon> onSelectWeapon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedWeapon.color.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: selectedWeapon.color.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SmashWeapon.values.map((w) {
          final isSelected = w == selectedWeapon;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelectWeapon(w),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 10 : 7,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? w.color.withValues(alpha: 0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? w.color
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        w.icon,
                        size: 16,
                        color: isSelected ? w.color : Colors.white70,
                      ),
                      if (isSelected && !compact) ...[
                        const SizedBox(width: 5),
                        Text(
                          w.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: w.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeaponStrikePainter extends CustomPainter {
  _WeaponStrikePainter({required this.strikes});

  final List<WeaponStrikeInstance> strikes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final strike in strikes) {
      final p = strike.progress;
      if (p >= 1.0) continue;

      canvas.save();
      final pos = strike.position;

      switch (strike.weapon) {
        case SmashWeapon.hammer:
          _drawHammerStrike(canvas, pos, p);
          break;
        case SmashWeapon.baseballBat:
          _drawBatStrike(canvas, pos, p);
          break;
        case SmashWeapon.laser:
          _drawLaserStrike(canvas, pos, p, size, strike.id);
          break;
        case SmashWeapon.punch:
          _drawPunchStrike(canvas, pos, p);
          break;
        case SmashWeapon.wreckingBall:
          _drawWreckingStrike(canvas, pos, p);
          break;
      }
      canvas.restore();
    }
  }

  void _drawHammerStrike(Canvas canvas, Offset target, double t) {
    // Sledgehammer swing: Starts top-right angled, slams down with impact starburst
    final angle = (1 - t) * (-math.pi / 2.2);
    final distance = (1 - t) * 70.0;
    final hammerPos = target + Offset(math.cos(angle) * distance + 20, math.sin(angle) * distance - 20);

    canvas.save();
    canvas.translate(hammerPos.dx, hammerPos.dy);
    canvas.rotate((1 - t) * -0.8 + 0.2);

    // Handle
    final handlePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 0), const Offset(45, -55), handlePaint);

    // Hammer Head
    final headPaint = Paint()..color = const Color(0xFF455A64);
    final headRect = Rect.fromCenter(center: const Offset(-8, 5), width: 36, height: 24);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(4)), headPaint);

    // Metallic highlight
    canvas.drawLine(
      const Offset(-22, -3),
      const Offset(6, -3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2,
    );
    canvas.restore();

    // Impact Starburst flash
    if (t > 0.15 && t < 0.85) {
      final flashT = ((t - 0.15) / 0.7).clamp(0.0, 1.0);
      final alpha = (1 - flashT);
      final radius = 20.0 + flashT * 40.0;
      _drawStarburst(canvas, target, radius, const Color(0xFFFFB74D), alpha);
    }
  }

  void _drawBatStrike(Canvas canvas, Offset target, double t) {
    // Baseball bat horizontal swing
    final swingAngle = -1.2 + t * 2.4;
    final batLength = 75.0;
    final pivot = target + Offset(math.cos(swingAngle + math.pi) * 35, math.sin(swingAngle + math.pi) * 20);

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(swingAngle);

    // Wood bat body
    final batPath = Path()
      ..moveTo(0, -3)
      ..lineTo(batLength * 0.4, -4)
      ..lineTo(batLength, -9)
      ..arcToPoint(Offset(batLength, 9), radius: const Radius.circular(9))
      ..lineTo(batLength * 0.4, 4)
      ..lineTo(0, 3)
      ..close();

    canvas.drawPath(batPath, Paint()..color = const Color(0xFFD7CCC8));
    canvas.drawPath(
      batPath,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Grip wrap
    canvas.drawRect(
      const Rect.fromLTWH(4, -3.5, 18, 7),
      Paint()..color = const Color(0xFFD32F2F),
    );
    canvas.restore();

    // Swoosh speed line
    final swooshPaint = Paint()
      ..color = Colors.white.withValues(alpha: (1 - t) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: target, radius: 45),
      -0.8,
      1.6 * t,
      false,
      swooshPaint,
    );

    if (t > 0.2 && t < 0.9) {
      final burstT = (t - 0.2) / 0.7;
      _drawStarburst(canvas, target, 25.0 + burstT * 35.0, const Color(0xFFFF7043), 1 - burstT);
    }
  }

  void _drawLaserStrike(Canvas canvas, Offset target, double t, Size stageSize, int strikeId) {
    // High-tech laser beam zapping from stage corner to target
    final start = Offset(target.dx < stageSize.width / 2 ? 0 : stageSize.width, target.dy * 0.3);
    final alpha = (1 - t).clamp(0.0, 1.0);

    // Outer glow
    canvas.drawLine(
      start,
      target,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: alpha * 0.7)
        ..strokeWidth = 14 * (1 - t * 0.5)
        ..strokeCap = StrokeCap.round,
    );

    // Core laser beam
    canvas.drawLine(
      start,
      target,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 5 * (1 - t * 0.5)
        ..strokeCap = StrokeCap.round,
    );

    // Electrical arcs at impact point
    final rng = math.Random(strikeId);
    for (var i = 0; i < 6; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final len = 20.0 + rng.nextDouble() * 30.0 * (1 - t);
      final p1 = target + Offset(math.cos(angle) * (len * 0.4), math.sin(angle) * (len * 0.4));
      final p2 = target + Offset(math.cos(angle + 0.3) * len, math.sin(angle + 0.3) * len);

      canvas.drawLine(
        target,
        p1,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: alpha)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawPunchStrike(Canvas canvas, Offset target, double t) {
    // Comic Power Fist punching target
    final travel = (1 - t) * 60.0;
    final fistCenter = target + Offset(0, travel + 10);

    canvas.save();
    canvas.translate(fistCenter.dx, fistCenter.dy);

    // Fist graphic
    final fistPaint = Paint()..color = const Color(0xFFFFB300);
    canvas.drawCircle(Offset.zero, 24, fistPaint);

    // Glove knuckles
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(i * 12.0, -14),
        8,
        Paint()..color = const Color(0xFFFFA000),
      );
    }
    // Wrist band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, 12, 32, 12),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFD32F2F),
    );
    canvas.restore();

    // Shockwave ring
    if (t > 0.1) {
      final ringP = (t - 0.1) / 0.9;
      canvas.drawCircle(
        target,
        15 + ringP * 45,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * (1 - ringP)
          ..color = const Color(0xFFFFD54F).withValues(alpha: 1 - ringP),
      );
    }
  }

  void _drawWreckingStrike(Canvas canvas, Offset target, double t) {
    // Wrecking ball swinging down on heavy chain
    final ballY = target.dy - (1 - t) * 120.0;
    final ballX = target.dx + (1 - t) * 50.0;

    // Chain links
    final chainPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(target.dx, 0), Offset(ballX, ballY), chainPaint);

    // Heavy iron ball
    final ballPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawCircle(Offset(ballX, ballY), 26, ballPaint);
    // Specular 3D shine
    canvas.drawCircle(
      Offset(ballX - 7, ballY - 7),
      7,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // Giant impact shockwave
    if (t > 0.3) {
      final impactT = (t - 0.3) / 0.7;
      _drawStarburst(canvas, target, 35 + impactT * 50, const Color(0xFFECEFF1), 1 - impactT);
    }
  }

  void _drawStarburst(Canvas canvas, Offset center, double radius, Color color, double alpha) {
    const points = 10;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? radius : radius * 0.45;
      final a = (i / (points * 2)) * math.pi * 2;
      final pt = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha * 0.85));
  }

  @override
  bool shouldRepaint(covariant _WeaponStrikePainter oldDelegate) => true;
}
