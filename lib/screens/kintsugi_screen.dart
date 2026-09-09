import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/vent_target.dart';
import '../services/storage_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_chrome.dart';

/// Japanese Kintsugi (金継ぎ) Restoration Mode:
/// An interactive mindfulness ritual where users mend a broken ceramic bowl
/// by painting molten gold along fracture seams, reinforcing emotional resilience.
class KintsugiScreen extends StatefulWidget {
  const KintsugiScreen({
    super.key,
    required this.target,
    this.itemName = 'Porcelain Tea Bowl',
  });

  final VentTarget target;
  final String itemName;

  @override
  State<KintsugiScreen> createState() => _KintsugiScreenState();
}

class _KintsugiScreenState extends State<KintsugiScreen>
    with SingleTickerProviderStateMixin {
  final List<Offset> _goldStrokes = [];
  double _repairProgress = 0.0;
  bool _isCompleted = false;
  late final AnimationController _glowCtrl;

  static const List<Offset> _crackSeams = [
    Offset(0.25, 0.35),
    Offset(0.38, 0.45),
    Offset(0.50, 0.50),
    Offset(0.62, 0.55),
    Offset(0.75, 0.65),
    Offset(0.50, 0.28),
    Offset(0.50, 0.72),
    Offset(0.32, 0.60),
    Offset(0.68, 0.40),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onPaintGold(Offset localPos, Size canvasSize) {
    if (_isCompleted) return;

    final norm = Offset(localPos.dx / canvasSize.width, localPos.dy / canvasSize.height);
    _goldStrokes.add(norm);

    // Check proximity to crack seams
    int hitCount = 0;
    for (final seam in _crackSeams) {
      for (final stroke in _goldStrokes) {
        if ((stroke - seam).distance < 0.08) {
          hitCount++;
          break;
        }
      }
    }

    final newProgress = (hitCount / _crackSeams.length).clamp(0.0, 1.0);
    if (newProgress != _repairProgress) {
      setState(() => _repairProgress = newProgress);
      VentSfx.light();

      if (_repairProgress >= 1.0 && !_isCompleted) {
        _completeKintsugi();
      }
    }
  }

  void _completeKintsugi() {
    setState(() => _isCompleted = true);
    VentSfx.heavy();
    VentSfx.instance.play(Sfx.confetti);
    StorageService.instance.recordCalmCompletion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0912),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 18),
            const SizedBox(width: 8),
            Text(
              'Kintsugi Restoration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.gold.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions / Philosophical Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                _isCompleted
                    ? '✨ Restored with Gold'
                    : 'Trace along the fractures with your finger to mend with molten gold.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _isCompleted ? 18 : 14,
                  fontWeight: _isCompleted ? FontWeight.bold : FontWeight.w500,
                  color: _isCompleted ? AppTheme.gold : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _repairProgress,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                ),
              ),
            ),

            // Interactive Ceramic Bowl Canvas
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (d) => _onPaintGold(d.localPosition, size),
                          onTapDown: (d) => _onPaintGold(d.localPosition, size),
                          child: AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (context, _) {
                              return CustomPaint(
                                size: size,
                                painter: _KintsugiBowlPainter(
                                  goldStrokes: _goldStrokes,
                                  crackSeams: _crackSeams,
                                  isCompleted: _isCompleted,
                                  glowT: _glowCtrl.value,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Affirmation & Action Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: _isCompleted
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
                          ),
                          child: const Text(
                            '“You are not broken. You survived the storm, and your scars are filled with gold.”',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ShineButton(
                          label: 'Carry This Peace Forward',
                          icon: Icons.check_circle_rounded,
                          color: AppTheme.gold,
                          onPressed: () => context.go('/'),
                        ),
                      ],
                    )
                  : Text(
                      '${(_repairProgress * 100).toInt()}% Repaired',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.0,
                        color: AppTheme.gold.withValues(alpha: 0.8),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KintsugiBowlPainter extends CustomPainter {
  _KintsugiBowlPainter({
    required this.goldStrokes,
    required this.crackSeams,
    required this.isCompleted,
    required this.glowT,
  });

  final List<Offset> goldStrokes;
  final List<Offset> crackSeams;
  final bool isCompleted;
  final double glowT;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // 1. Ceramic Bowl Base (Deep Celadon Charcoal)
    final bowlPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF263238),
          const Color(0xFF1E272C),
          const Color(0xFF101416),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bowlPaint);

    // Rim highlight
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(center, radius, rimPaint);

    // 2. Black hairline fracture seams
    final crackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: 0.85);

    final path = Path();
    for (int i = 0; i < crackSeams.length; i++) {
      final pt = Offset(crackSeams[i].dx * size.width, crackSeams[i].dy * size.height);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, crackPaint);

    // 3. User Molten Gold Fill Layer
    final goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.gold.withValues(alpha: isCompleted ? 0.95 : 0.85);

    if (goldStrokes.length > 1) {
      final goldPath = Path();
      final first = Offset(goldStrokes.first.dx * size.width, goldStrokes.first.dy * size.height);
      goldPath.moveTo(first.dx, first.dy);
      for (int i = 1; i < goldStrokes.length; i++) {
        final pt = Offset(goldStrokes[i].dx * size.width, goldStrokes[i].dy * size.height);
        goldPath.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(goldPath, goldPaint);

      // Gold shimmer highlight
      final shimmerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white.withValues(alpha: 0.75 + glowT * 0.25);
      canvas.drawPath(goldPath, shimmerPaint);
    }

    // 4. Full Completed Gold Radiance
    if (isCompleted) {
      final completedGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0 + glowT * 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = AppTheme.gold.withValues(alpha: 0.45);
      canvas.drawPath(path, completedGlow);
    }
  }

  @override
  bool shouldRepaint(covariant _KintsugiBowlPainter oldDelegate) => true;
}
