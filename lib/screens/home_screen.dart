import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/room_setup.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_chrome.dart';

/// Front door: Character vent, Room rampage, or Watch Demo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  FadeSlideIn(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.gold.withValues(alpha: 0.45),
                            ),
                            color: AppTheme.gold.withValues(alpha: 0.1),
                          ),
                          child: const Text(
                            'PREMIUM VENT',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () {
                            VentSfx.light();
                            context.push('/settings');
                          },
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: AppTheme.goldSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 60),
                    child: GradientTitle('GetMeBack'),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Two clear paths:\n'
                      '• Characters = faces (preset or upload) → pick a vent action\n'
                      '• Rooms = pictured rooms → tap objects directly to smash',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.45,
                          ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: _ModeCard(
                      title: 'Characters',
                      subtitle:
                          'Faces & photos → then choose Smash, Blender, Lightning…',
                      icon: Icons.face_retouching_natural,
                      previewAsset: 'assets/presets/angry_boss.png',
                      colors: const [Color(0xFFE94560), Color(0xFF7B2CBF)],
                      onTap: () {
                        VentSfx.light();
                        context.push('/characters');
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _ModeCard(
                      title: 'Rooms & Scenes',
                      subtitle:
                          'Real room pictures — tap plates, glasses, furniture to smash.',
                      icon: Icons.meeting_room,
                      previewAsset: RoomSetup.all.first.resolvedAsset,
                      colors: const [Color(0xFF26A69A), Color(0xFF1565C0)],
                      onTap: () {
                        VentSfx.light();
                        context.push('/rooms');
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: _ModeCard(
                      title: 'Watch Demo',
                      subtitle:
                          'Hands-free tour — the app shows features by itself.',
                      icon: Icons.play_circle_filled,
                      colors: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
                      onTap: () {
                        VentSfx.light();
                        VentSfx.instance.unlock();
                        context.push('/demo');
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: Text(
                      'Tip: start with Watch Demo if you’re new. '
                      'Open Settings for sound & haptics.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.goldSoft,
                          ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 360),
                    child: Text(
                      'V1A · 1.0.0-a1',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.goldSoft.withValues(alpha: 0.7),
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.previewAsset,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? previewAsset;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: 18,
      goldEdge: true,
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          label: '$title. $subtitle',
          child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.first.withValues(alpha: 0.55),
                  colors.last.withValues(alpha: 0.28),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (previewAsset != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: SizedBox(
                      height: 96,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            previewAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                ColoredBox(color: colors.first),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: colors.first.withValues(alpha: 0.9),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.gold),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
