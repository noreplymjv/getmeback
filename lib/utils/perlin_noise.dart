import 'dart:math';

/// Lightweight 1D Perlin-style noise for organic camera shake.
class PerlinNoise1D {
  PerlinNoise1D([int? seed]) : _perm = _buildPerm(seed ?? 42);

  final List<int> _perm;

  static List<int> _buildPerm(int seed) {
    final rng = Random(seed);
    final p = List<int>.generate(256, (i) => i)..shuffle(rng);
    return [...p, ...p];
  }

  double _fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);

  double _grad(int hash, double x) {
    final h = hash & 3;
    return switch (h) {
      0 => x,
      1 => -x,
      2 => x * 0.5,
      _ => -x * 0.5,
    };
  }

  double noise(double x) {
    final xi = x.floor() & 255;
    final xf = x - x.floor();
    final u = _fade(xf);
    final a = _grad(_perm[xi], xf);
    final b = _grad(_perm[xi + 1], xf - 1);
    return a + u * (b - a);
  }
}
