import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/vent_target.dart';
import '../services/storage_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_chrome.dart';
import '../widgets/target_avatar.dart';

/// Pick or create a character, then open the vent action menu.
class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
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

  Future<bool> _confirmDelete(VentTarget target) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete target?'),
        content: Text(
          'Remove “${target.name}” from recent targets?'
          '${target.hasPhoto ? '\n\nIts saved photo will also be deleted.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteTarget(VentTarget target) async {
    final confirmed = await _confirmDelete(target);
    if (!confirmed || !mounted) return;
    await StorageService.instance.deleteTarget(target.id);
    VentSfx.light();
    if (!mounted) return;
    await _loadTargets();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted “${target.name}”'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Characters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: PremiumBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeSlideIn(
                            child: Text(
                              'Pick a face — preset or your photo — then choose a vent scene.\n'
                              'Swipe left or tap the trash icon to remove a target you no longer need.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 80),
                            child: ShineButton(
                              label: 'Create / Upload Target',
                              icon: Icons.add_circle_outline,
                              onPressed: () async {
                                await context.push('/create');
                                _loadTargets();
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 120),
                            child: Row(
                              children: [
                                Text(
                                  'Recent targets',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
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
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.gold),
                      ),
                    )
                  else if (_recentTargets.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      AppTheme.surface.withValues(alpha: 0.7),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.sentiment_neutral_rounded,
                                  size: 44,
                                  color: AppTheme.gold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No characters yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create one, or go back and try Rooms & Scenes.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
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
                                child: Dismissible(
                                  key: ValueKey('target-${target.id}'),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) =>
                                      _confirmDelete(target),
                                  onDismissed: (_) async {
                                    final name = target.name;
                                    final id = target.id;
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    await StorageService.instance
                                        .deleteTarget(id);
                                    VentSfx.light();
                                    if (!mounted) return;
                                    setState(() {
                                      _recentTargets.removeWhere(
                                        (t) => t.id == id,
                                      );
                                    });
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Deleted “$name”'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.85),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.delete_forever),
                                      ],
                                    ),
                                  ),
                                  child: GlassPanel(
                                    padding: EdgeInsets.zero,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        8,
                                        10,
                                      ),
                                      leading: TargetAvatar(
                                        target: target,
                                        size: 40,
                                        showLabel: false,
                                      ),
                                      title: Text(
                                        target.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        target.isPreset
                                            ? 'Preset character · swipe to delete'
                                            : 'Custom photo · swipe to delete',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white54,
                                              size: 22,
                                            ),
                                            tooltip: 'Delete target',
                                            onPressed: () =>
                                                _deleteTarget(target),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.gold
                                                  .withValues(alpha: 0.12),
                                            ),
                                            child: const Icon(
                                              Icons.chevron_right,
                                              color: AppTheme.gold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => context
                                          .push('/vent-menu/${target.id}'),
                                    ),
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
        ),
      ),
    );
  }
}
