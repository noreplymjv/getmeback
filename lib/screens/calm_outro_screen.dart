import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/storage_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/dramatic_fx.dart';
import '../widgets/micro_journal_dialog.dart';
import '../widgets/premium_chrome.dart';

class CalmOutroScreen extends StatefulWidget {
  const CalmOutroScreen({super.key, required this.targetId});

  final String targetId;

  @override
  State<CalmOutroScreen> createState() => _CalmOutroScreenState();
}

class _CalmOutroScreenState extends State<CalmOutroScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late final DramaticFxController _fx = DramaticFxController();
  bool _inhale = true;
  int _zenStreak = 0;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        if (mounted) setState(() => _inhale = true);
      } else if (status == AnimationStatus.reverse) {
        if (mounted) setState(() => _inhale = false);
      }
    });
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
    _loadStreak();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      final center = Offset(size.width / 2, size.height * 0.42);
      VentSfx.instance.play(Sfx.confetti);
      _fx.crackerBurst(at: center, volleys: 5);
      _fx.glitterRain(at: center, count: 50);
    });
  }

  Future<void> _loadStreak() async {
    final streak = await StorageService.instance.recordCalmCompletion();
    if (mounted) setState(() => _zenStreak = streak);
  }

  Future<void> _finish() async {
    final entry = await showMicroJournalDialog(context);
    if (!mounted) return;
    if (entry != null) {
      await StorageService.instance.saveJournalEntry(entry);
    }
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _fx.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DramaticFxTicker(
      controller: _fx,
      child: Scaffold(
        body: PremiumBackdrop(
          calm: true,
          child: VentFxLayer(
            fx: _fx,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        if (_zenStreak > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ZenStreakBadge(streak: _zenStreak),
                          ),
                        const Spacer(),
                        const GradientTitle('Feel better?', size: 34),
                        const SizedBox(height: 10),
                        Text(
                          'The drama is over. Take a slow, premium breath.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 44),
                        AnimatedBuilder(
                          animation: _breathController,
                          builder: (context, child) {
                            final scale = 0.62 + _breathController.value * 0.38;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 196,
                                height: 196,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.calm.withValues(alpha: 0.28),
                                      AppTheme.calm.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppTheme.calm.withValues(alpha: 0.75),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.calm.withValues(alpha: 0.35),
                                      blurRadius: 40 * scale,
                                      spreadRadius: 8 * scale,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.gold.withValues(alpha: 0.12),
                                      blurRadius: 60,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _inhale ? 'Breathe In' : 'Breathe Out',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: AppTheme.calm,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _inhale ? '4 seconds in...' : '4 seconds out...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        ShineButton(
                          label: 'Done — Back to Home',
                          icon: Icons.home_rounded,
                          color: AppTheme.calm,
                          onPressed: _finish,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              context.go('/vent-menu/${widget.targetId}'),
                          child: const Text(
                            'Vent again',
                            style: TextStyle(
                              color: AppTheme.gold,
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
          ),
        ),
      ),
    );
  }
}

class _ZenStreakBadge extends StatelessWidget {
  const _ZenStreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.calm.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.calm.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa, color: AppTheme.calm, size: 20),
            const SizedBox(width: 8),
            Text(
              'Zen streak: $streak day${streak == 1 ? '' : 's'}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.calm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
