import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/vent_target.dart';
import '../theme/app_theme.dart';
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
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _goToCalm(context),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showTarget)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TargetAvatar(target: target, size: 80, showLabel: false),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _goToCalm(context),
                icon: const Icon(Icons.spa),
                label: const Text('I feel better'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
