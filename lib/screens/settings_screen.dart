import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/storage_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_chrome.dart';

/// Local prefs: haptics, SFX, zen streak, journal, clear data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _zenStreak = 0;
  List<({DateTime at, String text})> _journal = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final streak = await StorageService.instance.getZenStreak();
    final journal = await StorageService.instance.loadJournalEntries();
    if (!mounted) return;
    setState(() {
      _zenStreak = streak;
      _journal = journal.take(10).toList();
      _loading = false;
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear local data?'),
        content: const Text(
          'This removes saved targets, journal entries, and your zen streak. '
          'Sound and haptics settings stay as they are.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await StorageService.instance.clearAllLocalData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local data cleared')),
    );
    await _refresh();
  }

  String _formatWhen(DateTime at) {
    final local = at.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$m-$d · $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: PremiumBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      children: [
                        FadeSlideIn(
                          child: GlassPanel(
                            goldEdge: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Feel & feedback',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cartoon venting only — private, playful, not for harassment.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.goldSoft),
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Haptics'),
                                  subtitle: const Text('Vibration on hits & taps'),
                                  value: storage.hapticsEnabled,
                                  activeThumbColor: AppTheme.gold,
                                  onChanged: (v) async {
                                    await storage.setHapticsEnabled(v);
                                    if (v) VentSfx.light();
                                    if (mounted) setState(() {});
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Sound effects'),
                                  subtitle: const Text('Cartoon SFX during vents'),
                                  value: storage.sfxEnabled,
                                  activeThumbColor: AppTheme.gold,
                                  onChanged: (v) async {
                                    await storage.setSfxEnabled(v);
                                    if (mounted) setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: GlassPanel(
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: AppTheme.calm.withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(
                                    Icons.self_improvement,
                                    color: AppTheme.calm,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Zen streak',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(fontSize: 17),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _zenStreak > 0
                                            ? '$_zenStreak day${_zenStreak == 1 ? '' : 's'} of calm sessions'
                                            : 'Complete a calm session to start a streak',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Micro-journal',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 17),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last 10 notes from calm outros',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                if (_journal.isEmpty)
                                  Text(
                                    'No entries yet — write a quick note after breathing.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  )
                                else
                                  ..._journal.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatWhen(e.at),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: AppTheme.goldSoft,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            e.text,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 140),
                          child: GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privacy',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 17),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Everything stays on this device. No accounts. No cloud.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _confirmClear,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Clear all local data'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accent,
                                    side: BorderSide(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: Text(
                            'V1A · 1.0.0-a1',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.goldSoft
                                      .withValues(alpha: 0.7),
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
