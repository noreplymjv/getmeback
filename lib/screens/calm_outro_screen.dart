import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class CalmOutroScreen extends StatefulWidget {
  const CalmOutroScreen({super.key, required this.targetId});

  final String targetId;

  @override
  State<CalmOutroScreen> createState() => _CalmOutroScreenState();
}

class _CalmOutroScreenState extends State<CalmOutroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  bool _inhale = true;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathController.addListener(() {
      final inhale = _breathController.value < 0.5;
      if (inhale != _inhale) {
        setState(() => _inhale = inhale);
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'Feel better?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.calm,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Take a moment to breathe and reset.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _breathController,
                builder: (context, child) {
                  final scale = 0.6 + _breathController.value * 0.4;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.calm.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppTheme.calm.withValues(alpha: 0.6),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.calm.withValues(alpha: 0.2),
                            blurRadius: 30 * scale,
                            spreadRadius: 10 * scale,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _inhale ? 'Breathe In' : 'Breathe Out',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.calm,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                _inhale ? '4 seconds in...' : '4 seconds out...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.calm,
                  ),
                  child: const Text('Done — Back to Home'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    context.go('/vent-menu/${widget.targetId}'),
                child: const Text('Vent again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
