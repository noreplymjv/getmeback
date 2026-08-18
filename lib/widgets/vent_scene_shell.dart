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
  });

  final VentTarget target;
  final String title;
  final String hint;
  final Widget child;
  final VoidCallback? onFinish;
  final bool showTarget;

  void _goToCalm(BuildContext context) {
    if (onFinish != null) {
      onFinish!();
    } else {
      context.go('/calm/${target.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _goToCalm(context),
            child: const Text(
              'Done',
              style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: PremiumBackdrop(
        intensity: 0.85,
        child: SafeArea(
          child: Column(
            children: [
              if (showTarget)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TargetAvatar(
                    target: target,
                    size: 52,
                    showLabel: false,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
                child: GlassPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  radius: 18,
                  child: Text(
                    hint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.goldSoft,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(child: child),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: ShineButton(
                  label: 'I feel better',
                  icon: Icons.spa,
                  color: AppTheme.calm,
                  onPressed: () => _goToCalm(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
