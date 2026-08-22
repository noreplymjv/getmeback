import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/vent_target.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_chrome.dart';
import '../widgets/target_avatar.dart';

class VentSceneShell extends StatelessWidget {
  const VentSceneShell({
    super.key,
    required this.target,
    required this.title,
    required this.hint,
    required this.child,
    this.onFinish,
    this.showTarget = true,
    this.roomAsset,
  });

  final VentTarget target;
  final String title;
  final String hint;
  final Widget child;
  final VoidCallback? onFinish;
  final bool showTarget;
  final String? roomAsset;

  void _goToCalm(BuildContext context) {
    if (onFinish != null) {
      onFinish!();
    } else {
      context.go('/calm/${target.id}');
    }
  }

  static String resolveRoomAsset(String title, [String? explicit]) {
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final lower = title.toLowerCase();
    if (lower.contains('blender') || lower.contains('juice')) {
      return 'assets/rooms/kitchen.png';
    }
    if (lower.contains('punch') || lower.contains('bag')) {
      return 'assets/rooms/gameroom.png';
    }
    if (lower.contains('boxing') || lower.contains('ko')) {
      return 'assets/rooms/locker.png';
    }
    if (lower.contains('dart')) {
      return 'assets/rooms/cafe.png';
    }
    if (lower.contains('shred') || lower.contains('trash')) {
      return 'assets/rooms/office.png';
    }
    if (lower.contains('balloon')) {
      return 'assets/rooms/bedroom.png';
    }
    if (lower.contains('fire') || lower.contains('poof')) {
      return 'assets/rooms/cabin.png';
    }
    if (lower.contains('stomp')) {
      return 'assets/rooms/dining.png';
    }
    if (lower.contains('ice') || lower.contains('freeze')) {
      return 'assets/rooms/server.png';
    }
    if (lower.contains('sledge') || lower.contains('hammer')) {
      return 'assets/rooms/workshop.png';
    }
    if (lower.contains('anvil')) {
      return 'assets/rooms/garage.png';
    }
    if (lower.contains('catapult') || lower.contains('launch')) {
      return 'assets/rooms/balcony.png';
    }
    if (lower.contains('lightning') || lower.contains('zap')) {
      return 'assets/rooms/penthouse.png';
    }
    if (lower.contains('sink') || lower.contains('drown')) {
      return 'assets/rooms/bathroom.png';
    }
    if (lower.contains('piñata') || lower.contains('pinata')) {
      return 'assets/rooms/dorm.png';
    }
    if (lower.contains('paint')) {
      return 'assets/rooms/studio.png';
    }
    if (lower.contains('black hole') || lower.contains('hotel')) {
      return 'assets/rooms/hotel.png';
    }
    if (lower.contains('volcano')) {
      return 'assets/rooms/balcony.png';
    }
    if (lower.contains('smash') || lower.contains('tornado')) {
      return 'assets/rooms/living.png';
    }
    return 'assets/rooms/workshop.png';
  }

  @override
  Widget build(BuildContext context) {
    final asset = resolveRoomAsset(title, roomAsset);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.gold.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 14,
              ),
            ],
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface.withValues(alpha: 0.75),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 18),
              color: AppTheme.textPrimary,
              onPressed: () => context.pop(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.surface.withValues(alpha: 0.75),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.35),
                ),
              ),
              child: TextButton(
                onPressed: () => _goToCalm(context),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RoomStageBackdrop(
        roomAsset: asset,
        child: SafeArea(
          child: Column(
            children: [
              if (showTarget)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: TargetAvatar(
                    target: target,
                    size: 52,
                    showLabel: false,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      radius: 20,
                      goldEdge: true,
                      child: Text(
                        hint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.goldSoft,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: child),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ShineButton(
                      label: 'I feel better',
                      icon: Icons.spa_rounded,
                      color: AppTheme.calm,
                      onPressed: () => _goToCalm(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photorealistic / 2.5D Room Stage with dynamic lighting, perspective floor shadows, and ambient motes.
class RoomStageBackdrop extends StatefulWidget {
  const RoomStageBackdrop({
    super.key,
    required this.child,
    required this.roomAsset,
  });

  final Widget child;
  final String roomAsset;

  @override
  State<RoomStageBackdrop> createState() => _RoomStageBackdropState();
}

class _RoomStageBackdropState extends State<RoomStageBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Solid background fallback
        const ColoredBox(color: AppTheme.background),

        // Layer 2: High-res Room Scene Image
        Positioned.fill(
          child: Image.asset(
            widget.roomAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AppTheme.surface,
            ),
          ),
        ),

        // Layer 3: Atmospheric Lighting Gradient (Volumetric top-to-bottom depth)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Layer 4: Cinematic Radial Center Spotlight + Luxury Corner Vignette
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.0),
                radius: 1.05,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.28),
                  Colors.black.withValues(alpha: 0.82),
                ],
                stops: const [0.30, 0.72, 1.0],
              ),
            ),
          ),
        ),

        // Layer 5: Ground Perspective Stage Shadow (Gives 3D physical anchoring)
        Align(
          alignment: const Alignment(0, 0.52),
          child: Container(
            width: 320,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.elliptical(160, 27)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  blurRadius: 42,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),

        // Layer 6: Ambient floating motes / light particles
        AnimatedBuilder(
          animation: _ambientCtrl,
          builder: (context, _) {
            final t = _ambientCtrl.value * 2 * pi;
            return CustomPaint(
              painter: _AmbientMotesPainter(t),
            );
          },
        ),

        // Layer 7: Forefront interactive interactive content
        widget.child,
      ],
    );
  }
}

class _AmbientMotesPainter extends CustomPainter {
  _AmbientMotesPainter(this.t);
  final double t;

  static final List<Offset> _moteSeeds = [
    const Offset(0.18, 0.25),
    const Offset(0.82, 0.32),
    const Offset(0.35, 0.65),
    const Offset(0.68, 0.78),
    const Offset(0.50, 0.20),
    const Offset(0.25, 0.85),
    const Offset(0.75, 0.15),
    const Offset(0.12, 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _moteSeeds.length; i++) {
      final seed = _moteSeeds[i];
      final dx = seed.dx * size.width + sin(t + i) * 14;
      final dy = seed.dy * size.height + cos(t * 0.8 + i) * 18;
      final alpha = (0.20 + 0.15 * sin(t + i * 1.5)).clamp(0.05, 0.45);

      paint.color = AppTheme.gold.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), 1.8 + (i % 3) * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientMotesPainter oldDelegate) =>
      oldDelegate.t != t;
}
