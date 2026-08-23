import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/vent_sfx.dart';
import '../utils/perlin_noise.dart';

/// Shared dramatic VFX: particles, shockwaves, comic pops, shake, flash.
class DramaticFxOverlay extends StatelessWidget {
  const DramaticFxOverlay({
    super.key,
    required this.particles,
    this.rings = const [],
    this.popTexts = const [],
    this.smokes = const [],
    this.cracks = const [],
    this.flash = 0,
    this.vignette = 0,
    this.shake = Offset.zero,
    this.child,
  });

  final List<FxParticle> particles;
  final List<FxRing> rings;
  final List<FxPopText> popTexts;
  final List<FxSmoke> smokes;
  final List<FxCrack> cracks;
  final double flash;
  final double vignette;
  final Offset shake;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: shake,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ...(child == null ? const <Widget>[] : <Widget>[child!]),
          IgnorePointer(
            child: CustomPaint(
              painter: _FxPainter(
                particles: particles,
                rings: rings,
                smokes: smokes,
                cracks: cracks,
              ),
            ),
          ),
          ...popTexts.map(
            (p) => Positioned(
              left: p.x - 40,
              top: p.y - 30,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: p.scale,
                  child: Opacity(
                    opacity: p.life.clamp(0.0, 1.0),
                    child: Text(
                      p.text,
                      style: TextStyle(
                        fontSize: 28 + p.life * 12,
                        fontWeight: FontWeight.w900,
                        color: p.color,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                          Shadow(
                            color: p.color.withValues(alpha: 0.9),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (flash > 0)
            IgnorePointer(
              child: ColoredBox(
                color: Color.lerp(
                  const Color(0xFFFFD166),
                  Colors.white,
                  0.45,
                )!.withValues(alpha: flash * 0.55),
              ),
            ),
          if (vignette > 0)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: vignette * 0.45),
                    ],
                    radius: 0.85,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FxParticle {
  FxParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    this.rotation = 0,
    this.spin = 0,
    this.shape = FxShape.shard,
    this.gravity = 900,
  });

  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;
  double rotation;
  double spin;
  FxShape shape;
  double gravity;

  void tick(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += gravity * dt;
    vx *= 0.985;
    life -= dt * 0.75;
    rotation += spin * dt;
  }
}

class FxRing {
  FxRing({
    required this.x,
    required this.y,
    required this.radius,
    required this.life,
    required this.color,
    this.maxLife = 0.5,
  });

  double x;
  double y;
  double radius;
  double life;
  double maxLife;
  Color color;

  void tick(double dt) {
    radius += 420 * dt;
    life -= dt / maxLife;
  }
}

class FxPopText {
  FxPopText({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    this.life = 1.0,
    this.scale = 0.6,
  });

  String text;
  double x;
  double y;
  Color color;
  double life;
  double scale;

  void tick(double dt) {
    life -= dt * 1.1;
    scale += dt * 1.4;
    y -= 80 * dt;
  }
}

enum FxShape { shard, circle, spark, chunk, star, droplet, smoke, flame }

class FxSmoke {
  FxSmoke({
    required this.x,
    required this.y,
    required this.radius,
    required this.life,
    required this.color,
    this.vy = -60,
  });

  double x;
  double y;
  double radius;
  double life;
  Color color;
  double vy;

  void tick(double dt) {
    y += vy * dt;
    radius += 40 * dt;
    life -= dt * 0.55;
    vy *= 0.98;
  }
}

class FxCrack {
  FxCrack({
    required this.x,
    required this.y,
    required this.angle,
    required this.length,
    required this.life,
    required this.color,
  });

  double x;
  double y;
  double angle;
  double length;
  double life;
  Color color;

  void tick(double dt) {
    life -= dt * 1.2;
    length += 80 * dt;
  }
}

class DramaticFxController extends ChangeNotifier {
  DramaticFxController();

  final _rng = Random();
  final List<FxParticle> particles = [];
  final List<FxRing> rings = [];
  final List<FxPopText> popTexts = [];
  final List<FxSmoke> smokes = [];
  final List<FxCrack> cracks = [];
  double flash = 0;
  double vignette = 0;
  Offset shake = Offset.zero;
  double _shakeT = 0;
  double _shakeAmp = 0;
  double _shakeDuration = 0.28;
  double _hitStopRemaining = 0;
  final _shakeNoise = PerlinNoise1D(7);
  double _shakeNoiseT = 0;

  bool get isHitStopped => _hitStopRemaining > 0;

  /// Brief frame freeze on heavy impacts (30–50 ms).
  void triggerHitStop([Duration duration = const Duration(milliseconds: 40)]) {
    _hitStopRemaining = max(_hitStopRemaining, duration.inMicroseconds / 1e6);
  }

  /// Camera shake without spawning particles/SFX (earthquake, tests).
  void shakeBurst({double amp = 18, double duration = 0.28}) {
    _shakeAmp = max(_shakeAmp, amp);
    _shakeDuration = max(_shakeDuration, duration);
    _shakeT = max(_shakeT, duration);
    notifyListeners();
  }

  static const _comicWords = [
    'POW!',
    'BAM!',
    'WHAM!',
    'BOOM!',
    'SMASH!',
    'CRACK!',
    'SPLAT!',
    'YEET!',
    'KAPOW!',
    'WHACK!',
    'OOF!',
    'BRUTAL!',
    'SPLAT!',
    'CRUNCH!',
    'YEET!',
    'ZAP!',
    'SIZZLE!',
  ];

  void impact({
    required Offset at,
    int count = 36,
    Color? color,
    double intensity = 1,
    bool haptic = true,
    bool comic = true,
    bool shockwave = true,
  }) {
    if (haptic) VentSfx.medium();
    VentSfx.instance.play(intensity > 1.3 ? Sfx.smash : Sfx.hit);
    flash = (0.65 * intensity).clamp(0.0, 1.0);
    vignette = (0.35 * intensity).clamp(0.0, 0.6);
    _shakeAmp = 18 * intensity;
    _shakeDuration = 0.28;
    _shakeT = _shakeDuration;
    if (intensity >= 1.2) triggerHitStop();

    _spawnParticles(at, count, color, intensity);
    if (intensity > 0.7) _crackBurst(at, color, (count / 36).clamp(0.5, 2.0));
    if (shockwave) _addRing(at, color, intensity * 0.9);
    if (comic && intensity > 0.5) {
      comicPop(at: at, color: color);
    }
    notifyListeners();
  }

  void megaImpact({
    required Offset at,
    Color? color,
    bool haptic = true,
  }) {
    if (haptic) {
      VentSfx.heavy();
      VentSfx.rumble();
    }
    VentSfx.instance.play(Sfx.smash);
    flash = 1.0;
    vignette = 0.55;
    _shakeAmp = 28;
    _shakeDuration = 0.4;
    _shakeT = _shakeDuration;
    triggerHitStop(const Duration(milliseconds: 45));
    _spawnParticles(at, 80, color, 1.9);
    _spawnParticles(at, 48, Colors.white, 1.3);
    _crackBurst(at, color, 2.2);
    smokeBurst(at: at, count: 12, color: Colors.grey.shade700);
    _addRing(at, color, 1.4);
    _addRing(at, color?.withValues(alpha: 0.6) ?? Colors.orange, 1.0);
    _addRing(at, const Color(0xFFFFD166), 1.6);
    comicPop(at: at, text: _comicWords[_rng.nextInt(_comicWords.length)], color: color);
    comicPop(
      at: at.translate(_rng.nextDouble() * 60 - 30, _rng.nextDouble() * 40 - 20),
      text: _comicWords[_rng.nextInt(_comicWords.length)],
    );
    crackerBurst(at: at, volleys: 3, playSound: false);
    notifyListeners();
  }

  void comicPop({
    required Offset at,
    String? text,
    Color? color,
  }) {
    popTexts.add(
      FxPopText(
        text: text ?? _comicWords[_rng.nextInt(_comicWords.length)],
        x: at.dx + (_rng.nextDouble() - 0.5) * 30,
        y: at.dy + (_rng.nextDouble() - 0.5) * 20,
        color: color ?? const Color(0xFFFFEB3B),
        life: 1.0,
        scale: 0.5 + _rng.nextDouble() * 0.3,
      ),
    );
    notifyListeners();
  }

  void confettiBurst({required Offset at, int count = 55}) {
    VentSfx.heavy();
    VentSfx.instance.play(Sfx.confetti);
    flash = 0.55;
    _shakeAmp = 16;
    _shakeDuration = 0.26;
    _shakeT = _shakeDuration;
    _addRing(at, const Color(0xFFFFD54F), 1.0);
    final colors = [
      const Color(0xFFFF4D6D),
      const Color(0xFFFFD166),
      const Color(0xFF7AEFFF),
      const Color(0xFF5EE6A0),
      const Color(0xFFFF8A5C),
      Colors.white,
      const Color(0xFFFFE8A3),
    ];
    for (var i = 0; i < count; i++) {
      final angle = -pi + _rng.nextDouble() * pi * 2;
      final speed = 240 + _rng.nextDouble() * 620;
      particles.add(
        FxParticle(
          x: at.dx,
          y: at.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 360,
          size: 5 + _rng.nextDouble() * 12,
          color: colors[_rng.nextInt(colors.length)],
          life: 1.2 + _rng.nextDouble(),
          spin: (_rng.nextDouble() - 0.5) * 18,
          shape: i % 3 == 0 ? FxShape.star : FxShape.chunk,
        ),
      );
    }
    crackerBurst(at: at, volleys: 4, playSound: false);
    glitterRain(at: at, count: 36);
    notifyListeners();
  }

  /// Firework crackers — gold/coral bursts with trailing sparks.
  void crackerBurst({
    required Offset at,
    int volleys = 4,
    bool playSound = true,
  }) {
    if (playSound) {
      VentSfx.heavy();
      VentSfx.instance.play(Sfx.confetti);
    }
    flash = max(flash, 0.6);
    _shakeAmp = max(_shakeAmp, 18);
    _shakeDuration = max(_shakeDuration, 0.28);
    _shakeT = max(_shakeT, _shakeDuration);
    final palette = [
      const Color(0xFFFFD166),
      const Color(0xFFFF4D6D),
      const Color(0xFFFF8A5C),
      const Color(0xFFFFFFFF),
      const Color(0xFF7AEFFF),
      const Color(0xFFFFE8A3),
    ];
    for (var v = 0; v < volleys; v++) {
      final origin = at.translate(
        (_rng.nextDouble() - 0.5) * 140,
        (_rng.nextDouble() - 0.5) * 110 - 20,
      );
      _addRing(origin, palette[v % palette.length], 1.1 + v * 0.15);
      final rays = 16 + _rng.nextInt(10);
      for (var i = 0; i < rays; i++) {
        final angle = (i / rays) * pi * 2 + _rng.nextDouble() * 0.2;
        final speed = 180 + _rng.nextDouble() * 420 + v * 40;
        particles.add(
          FxParticle(
            x: origin.dx,
            y: origin.dy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 80,
            size: 3 + _rng.nextDouble() * 7,
            color: palette[_rng.nextInt(palette.length)],
            life: 0.7 + _rng.nextDouble() * 0.7,
            spin: (_rng.nextDouble() - 0.5) * 14,
            shape: i.isEven ? FxShape.star : FxShape.spark,
            gravity: 280,
          ),
        );
      }
    }
    notifyListeners();
  }

  void glitterRain({required Offset at, int count = 40}) {
    for (var i = 0; i < count; i++) {
      particles.add(
        FxParticle(
          x: at.dx + (_rng.nextDouble() - 0.5) * 220,
          y: at.dy - 40 - _rng.nextDouble() * 160,
          vx: (_rng.nextDouble() - 0.5) * 60,
          vy: 40 + _rng.nextDouble() * 140,
          size: 2.5 + _rng.nextDouble() * 5,
          color: [
            const Color(0xFFFFD166),
            const Color(0xFFFFE8A3),
            Colors.white,
          ][_rng.nextInt(3)],
          life: 1.2 + _rng.nextDouble(),
          spin: (_rng.nextDouble() - 0.5) * 10,
          shape: FxShape.star,
          gravity: 180,
        ),
      );
    }
    notifyListeners();
  }

  void swirlBurst({required Offset at, int count = 44, Color? color}) {
    VentSfx.medium();
    VentSfx.instance.play(Sfx.swirl);
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * pi * 2 + _rng.nextDouble() * 0.5;
      final speed = 200 + _rng.nextDouble() * 460;
      particles.add(
        FxParticle(
          x: at.dx,
          y: at.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 5 + _rng.nextDouble() * 10,
          color: color ??
              Color.lerp(
                const Color(0xFFFF8A65),
                const Color(0xFFFFD54F),
                _rng.nextDouble(),
              )!,
          life: 0.9 + _rng.nextDouble() * 0.6,
          spin: 10 + _rng.nextDouble() * 14,
          shape: FxShape.spark,
        ),
      );
    }
    notifyListeners();
  }

  void dripBurst({required Offset at, int count = 30, Color? color}) {
    VentSfx.light();
    VentSfx.instance.play(Sfx.splash);
    final c = color ?? const Color(0xFF4FC3F7);
    for (var i = 0; i < count; i++) {
      particles.add(
        FxParticle(
          x: at.dx + (_rng.nextDouble() - 0.5) * 80,
          y: at.dy,
          vx: (_rng.nextDouble() - 0.5) * 120,
          vy: -80 - _rng.nextDouble() * 200,
          size: 4 + _rng.nextDouble() * 8,
          color: c.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3),
          life: 0.8 + _rng.nextDouble() * 0.5,
          shape: FxShape.droplet,
          gravity: 600,
        ),
      );
    }
    notifyListeners();
  }

  void smokeBurst({
    required Offset at,
    int count = 10,
    Color? color,
  }) {
    final c = color ?? Colors.grey.shade600;
    for (var i = 0; i < count; i++) {
      smokes.add(
        FxSmoke(
          x: at.dx + (_rng.nextDouble() - 0.5) * 60,
          y: at.dy + (_rng.nextDouble() - 0.5) * 40,
          radius: 12 + _rng.nextDouble() * 24,
          life: 0.8 + _rng.nextDouble() * 0.6,
          color: c.withValues(alpha: 0.35 + _rng.nextDouble() * 0.25),
          vy: -40 - _rng.nextDouble() * 80,
        ),
      );
    }
    notifyListeners();
  }

  void fireBurst({required Offset at, int count = 35}) {
    VentSfx.medium();
    VentSfx.instance.play(Sfx.fire);
    flash = 0.7;
    vignette = 0.35;
    _shakeAmp = 16;
    _shakeDuration = 0.2;
    _shakeT = _shakeDuration;
    comicPop(at: at, text: 'WHOOSH!', color: const Color(0xFFFF7043));
    _addRing(at, const Color(0xFFFF7043), 1.1);
    smokeBurst(at: at, count: 8, color: Colors.grey.shade800);
    for (var i = 0; i < count; i++) {
      final angle = -pi * 0.8 + _rng.nextDouble() * pi * 1.6;
      final speed = 180 + _rng.nextDouble() * 420;
      particles.add(
        FxParticle(
          x: at.dx,
          y: at.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 180,
          size: 6 + _rng.nextDouble() * 14,
          color: [
            const Color(0xFFFF5722),
            const Color(0xFFFF9800),
            const Color(0xFFFFEB3B),
          ][_rng.nextInt(3)],
          life: 0.6 + _rng.nextDouble() * 0.7,
          spin: (_rng.nextDouble() - 0.5) * 12,
          shape: FxShape.flame,
          gravity: 350,
        ),
      );
    }
    notifyListeners();
  }

  void debrisRain({required Offset at, int count = 25, Color? color}) {
    VentSfx.instance.play(Sfx.shred);
    final c = color ?? const Color(0xFF8D6E63);
    for (var i = 0; i < count; i++) {
      particles.add(
        FxParticle(
          x: at.dx + (_rng.nextDouble() - 0.5) * 120,
          y: at.dy - 20 - _rng.nextDouble() * 80,
          vx: (_rng.nextDouble() - 0.5) * 180,
          vy: 80 + _rng.nextDouble() * 200,
          size: 4 + _rng.nextDouble() * 10,
          color: c,
          life: 1.0 + _rng.nextDouble() * 0.8,
          spin: (_rng.nextDouble() - 0.5) * 10,
          shape: FxShape.chunk,
          gravity: 700,
        ),
      );
    }
    notifyListeners();
  }

  void rippleBurst({required Offset at, Color? color, int count = 3}) {
    VentSfx.instance.play(Sfx.splash);
    final c = color ?? const Color(0xFF4FC3F7);
    for (var i = 0; i < count; i++) {
      rings.add(
        FxRing(
          x: at.dx,
          y: at.dy,
          radius: 12 + i * 18.0,
          life: 1 - i * 0.15,
          maxLife: 0.55 + i * 0.08,
          color: c.withValues(alpha: 0.7 - i * 0.15),
        ),
      );
    }
    notifyListeners();
  }

  void _crackBurst(Offset at, Color? color, double intensity) {
    final c = color ?? const Color(0xFFFF6B4A);
    final lines = (6 + _rng.nextInt(5) * intensity).round();
    for (var i = 0; i < lines; i++) {
      cracks.add(
        FxCrack(
          x: at.dx,
          y: at.dy,
          angle: (i / lines) * pi * 2 + _rng.nextDouble() * 0.4,
          length: 20 + _rng.nextDouble() * 40 * intensity,
          life: 0.6 + _rng.nextDouble() * 0.3,
          color: c.withValues(alpha: 0.85),
        ),
      );
    }
  }

  void electricBurst({required Offset at, int count = 40}) {
    VentSfx.heavy();
    VentSfx.instance.play(Sfx.zap);
    flash = 0.85;
    vignette = 0.4;
    _shakeAmp = 22;
    _shakeDuration = 0.25;
    _shakeT = _shakeDuration;
    comicPop(at: at, text: 'ZAP!', color: Colors.yellowAccent);
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 300 + _rng.nextDouble() * 500;
      particles.add(
        FxParticle(
          x: at.dx,
          y: at.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 3 + _rng.nextDouble() * 7,
          color: [
            Colors.yellowAccent,
            Colors.white,
            const Color(0xFF81D4FA),
          ][_rng.nextInt(3)],
          life: 0.5 + _rng.nextDouble() * 0.4,
          spin: (_rng.nextDouble() - 0.5) * 20,
          shape: FxShape.spark,
          gravity: 200,
        ),
      );
    }
    _addRing(at, Colors.yellowAccent, 1.2);
    notifyListeners();
  }

  void _spawnParticles(Offset at, int count, Color? color, double intensity) {
    final base = color ?? const Color(0xFFFF6B4A);
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 260 + _rng.nextDouble() * 620 * intensity;
      particles.add(
        FxParticle(
          x: at.dx,
          y: at.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 220 * intensity,
          size: 4 + _rng.nextDouble() * 14 * intensity,
          color: Color.lerp(
                base,
                [
                  Colors.white,
                  const Color(0xFFFFD54F),
                  const Color(0xFFFF7043),
                  const Color(0xFFE53935),
                ][_rng.nextInt(4)],
                _rng.nextDouble(),
              ) ??
              base,
          life: 0.8 + _rng.nextDouble() * 0.8,
          spin: (_rng.nextDouble() - 0.5) * 16,
          shape: FxShape.values[_rng.nextInt(FxShape.values.length)],
        ),
      );
    }
  }

  void _addRing(Offset at, Color? color, double intensity) {
    rings.add(
      FxRing(
        x: at.dx,
        y: at.dy,
        radius: 8,
        life: 1,
        maxLife: 0.45 / intensity.clamp(0.5, 2.0),
        color: (color ?? const Color(0xFFFF6B4A)).withValues(alpha: 0.85),
      ),
    );
  }

  void tick(double dt) {
    if (_hitStopRemaining > 0) {
      _hitStopRemaining -= dt;
      if (_hitStopRemaining < 0) _hitStopRemaining = 0;
      return;
    }

    var changed = false;
    if (flash > 0) {
      flash = (flash - dt * 4.0).clamp(0.0, 1.0);
      changed = true;
    }
    if (vignette > 0) {
      vignette = (vignette - dt * 2.5).clamp(0.0, 1.0);
      changed = true;
    }
    if (_shakeT > 0) {
      _shakeT -= dt;
      _shakeNoiseT += dt * 42;
      final t = (_shakeT / _shakeDuration).clamp(0.0, 1.0);
      final falloff = t * t;
      shake = Offset(
        _shakeNoise.noise(_shakeNoiseT) * _shakeAmp * falloff,
        _shakeNoise.noise(_shakeNoiseT + 17.3) * _shakeAmp * 0.72 * falloff,
      );
      changed = true;
    } else if (shake != Offset.zero) {
      shake = Offset.zero;
      changed = true;
    }

    for (final p in particles) {
      p.tick(dt);
      changed = true;
    }
    particles.removeWhere((p) => p.life <= 0);

    for (final r in rings) {
      r.tick(dt);
      changed = true;
    }
    rings.removeWhere((r) => r.life <= 0);

    for (final t in popTexts) {
      t.tick(dt);
      changed = true;
    }
    popTexts.removeWhere((t) => t.life <= 0);

    for (final s in smokes) {
      s.tick(dt);
      changed = true;
    }
    smokes.removeWhere((s) => s.life <= 0);

    for (final c in cracks) {
      c.tick(dt);
      changed = true;
    }
    cracks.removeWhere((c) => c.life <= 0);

    if (changed) notifyListeners();
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter({
    required this.particles,
    required this.rings,
    required this.smokes,
    required this.cracks,
  });

  final List<FxParticle> particles;
  final List<FxRing> rings;
  final List<FxSmoke> smokes;
  final List<FxCrack> cracks;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in smokes) {
      final paint = Paint()
        ..color = s.color.withValues(alpha: (s.life * 0.5).clamp(0.0, 0.5))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.radius * 0.4);
      canvas.drawCircle(Offset(s.x, s.y), s.radius, paint);
    }

    for (final c in cracks) {
      final paint = Paint()
        ..color = c.color.withValues(alpha: c.life.clamp(0.0, 1.0))
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(c.x, c.y),
        Offset(
          c.x + cos(c.angle) * c.length,
          c.y + sin(c.angle) * c.length,
        ),
        paint,
      );
    }

    for (final r in rings) {
      final paint = Paint()
        ..color = r.color.withValues(alpha: (r.life * 0.7).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + (1 - r.life) * 8;
      canvas.drawCircle(Offset(r.x, r.y), r.radius, paint);
    }

    for (final p in particles) {
      final alpha = p.life.clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      switch (p.shape) {
        case FxShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
        case FxShape.spark:
          paint.strokeWidth = 3;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(Offset(-p.size * 1.2, 0), Offset(p.size * 1.2, 0), paint);
          canvas.drawLine(Offset(0, -p.size * 1.2), Offset(0, p.size * 1.2), paint);
        case FxShape.chunk:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size * 0.7,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
        case FxShape.star:
          _drawStar(canvas, paint, p.size);
        case FxShape.droplet:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 0.7,
              height: p.size,
            ),
            paint,
          );
        case FxShape.flame:
          final path = Path()
            ..moveTo(0, -p.size * 0.9)
            ..quadraticBezierTo(p.size * 0.5, -p.size * 0.2, p.size * 0.35, p.size * 0.5)
            ..quadraticBezierTo(0, p.size * 0.3, -p.size * 0.35, p.size * 0.5)
            ..quadraticBezierTo(-p.size * 0.5, -p.size * 0.2, 0, -p.size * 0.9)
            ..close();
          canvas.drawPath(path, paint);
        case FxShape.smoke:
          paint.maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.5);
          canvas.drawCircle(Offset.zero, p.size, paint);
        case FxShape.shard:
          final path = Path()
            ..moveTo(0, -p.size)
            ..lineTo(p.size * 0.4, p.size * 0.55)
            ..lineTo(-p.size * 0.4, p.size * 0.55)
            ..close();
          canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = cos(angle) * size * 0.5;
      final y = sin(angle) * size * 0.5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FxPainter oldDelegate) => true;
}

class DramaticFxTicker extends StatefulWidget {
  const DramaticFxTicker({
    super.key,
    required this.controller,
    required this.child,
  });

  final DramaticFxController controller;
  final Widget child;

  @override
  State<DramaticFxTicker> createState() => _DramaticFxTickerState();
}

class _DramaticFxTickerState extends State<DramaticFxTicker>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
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

/// Respects [MediaQuery.disableAnimations] for shake and flash.
class VentFxLayer extends StatelessWidget {
  const VentFxLayer({
    super.key,
    required this.fx,
    required this.child,
  });

  final DramaticFxController fx;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return DramaticFxOverlay(
      particles: fx.particles,
      rings: fx.rings,
      popTexts: fx.popTexts,
      smokes: fx.smokes,
      cracks: fx.cracks,
      flash: reduceMotion ? 0 : fx.flash,
      vignette: fx.vignette,
      shake: reduceMotion ? Offset.zero : fx.shake,
      child: child,
    );
  }
}
