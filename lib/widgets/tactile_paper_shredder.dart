import 'dart:math';
import 'package:flutter/material.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';

/// Tactile Mechanical Paper Shredder for Zen 3.0:
/// Allows users to write a painful or furious thought, pull the lever,
/// and watch the paper physically slice into falling ribbons with crunching audio.
class TactilePaperShredderDialog extends StatefulWidget {
  const TactilePaperShredderDialog({super.key});

  @override
  State<TactilePaperShredderDialog> createState() =>
      _TactilePaperShredderDialogState();
}

class _TactilePaperShredderDialogState
    extends State<TactilePaperShredderDialog>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _shredCtrl;
  bool _isShredding = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _shredCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shredCtrl.dispose();
    super.dispose();
  }

  void _shredNote() {
    if (_controller.text.trim().isEmpty || _isShredding) return;

    setState(() => _isShredding = true);
    VentSfx.heavy();
    VentSfx.instance.play(Sfx.shred);
    VentSfx.rumble();

    _shredCtrl.forward().then((_) {
      if (mounted) {
        setState(() => _isFinished = true);
        VentSfx.instance.play(Sfx.pop);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161520),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Rage Shredder',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type whatever made your blood boil, then feed it to the shredder.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),

              // Notepad / Shredding Paper Area
              SizedBox(
                height: 180,
                child: ClipRect(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Paper Sheet moving down into shredder
                      AnimatedBuilder(
                        animation: _shredCtrl,
                        builder: (context, child) {
                          final offset = _shredCtrl.value * 120.0;
                          return Transform.translate(
                            offset: Offset(0, offset),
                            child: Opacity(
                              opacity: (1.0 - _shredCtrl.value * 0.9).clamp(0.0, 1.0),
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFDE7), // Lined notepad cream
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _controller,
                                  enabled: !_isShredding,
                                  maxLines: 5,
                                  maxLength: 160,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF263238),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Write your fury here...',
                                    hintStyle: TextStyle(color: Colors.black38),
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Mechanical Shredder Slot Frame
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2838),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 140,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Shredded Falling Paper Strips
                      if (_isShredding)
                        Positioned(
                          bottom: -20,
                          left: 0,
                          right: 0,
                          child: AnimatedBuilder(
                            animation: _shredCtrl,
                            builder: (context, _) {
                              return CustomPaint(
                                size: const Size(double.infinity, 60),
                                painter: _PaperRibbonPainter(
                                  progress: _shredCtrl.value,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action button
              if (_isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.calm, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Obliterated. Breathe easy.',
                        style: TextStyle(
                          color: AppTheme.calm,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isShredding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.flash_on_rounded),
                    label: Text(
                      _isShredding ? 'SHREDDING...' : 'FEED TO SHREDDER',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    onPressed: _isShredding ? null : _shredNote,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperRibbonPainter extends CustomPainter {
  _PaperRibbonPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.05) return;
    final w = size.width;
    const count = 14;
    final step = w / count;

    for (int i = 0; i < count; i++) {
      final x = i * step + step * 0.2;
      final stripHeight = min(progress * 70.0, 48.0) * (0.8 + (i % 3) * 0.2);
      final alpha = (1.0 - progress * 0.4).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = const Color(0xFFFFFDE7).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, step * 0.6, stripHeight),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperRibbonPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
