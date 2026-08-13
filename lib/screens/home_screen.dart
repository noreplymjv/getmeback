import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/vent_target.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_chrome.dart';
import '../widgets/target_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VentTarget> _recentTargets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    final targets = await StorageService.instance.loadTargets();
    if (mounted) {
      setState(() {
        _recentTargets = targets;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 80),
                        child: GradientTitle('GetMeBack'),
                      ),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: Text(
                          'Cinematic cartoon catharsis.\nRelease it. Then breathe.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.45,
                              ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: ShineButton(
                          label: 'Create Target',
                          icon: Icons.add_circle_outline,
                          onPressed: () async {
                            await context.push('/create');
                            _loadTargets();
                          },
                        ),
                      ),
                      const SizedBox(height: 36),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 260),
                        child: Row(
                          children: [
                            Text(
                              'Recent Targets',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const Spacer(),
                            Text(
                              '${_recentTargets.length}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 280),
                        child: Text(
                          'Pick someone to vent on — cartoon fun, zero harm.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recentTargets.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: GlassPanel(
                        goldEdge: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 48,
                              color: AppTheme.gold.withValues(alpha: 0.85),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Your stage is empty',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a target and let the fireworks fly.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final target = _recentTargets[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 40 * index),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassPanel(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  10,
                                ),
                                leading: TargetAvatar(
                                  target: target,
                                  size: 56,
                                  showLabel: false,
                                ),
                                title: Text(
                                  target.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  target.isPreset
                                      ? 'Preset character'
                                      : 'Custom photo',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.gold.withValues(alpha: 0.12),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.gold,
                                  ),
                                ),
                                onTap: () =>
                                    context.push('/vent-menu/${target.id}'),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _recentTargets.length,
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
