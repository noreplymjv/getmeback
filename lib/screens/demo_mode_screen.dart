import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/room_setup.dart';
import '../models/vent_action.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/dramatic_fx.dart';
import '../widgets/premium_chrome.dart';

class _DemoStep {
  const _DemoStep({
    required this.title,
    required this.body,
    required this.visual,
    this.duration = const Duration(seconds: 5),
    this.sfx,
  });

  final String title;
  final String body;
  final _DemoVisual visual;
  final Duration duration;
  final Sfx? sfx;
}

enum _DemoVisual {
  welcome,
  chooseMode,
  characters,
  ventActions,
  rooms,
  smashTips,
  calm,
  ready,
}

/// Hands-free feature tour — advances by itself with captions + FX.
class DemoModeScreen extends StatefulWidget {
  const DemoModeScreen({super.key});

  @override
  State<DemoModeScreen> createState() => _DemoModeScreenState();
}

class _DemoModeScreenState extends State<DemoModeScreen> {
  static const _steps = <_DemoStep>[
    _DemoStep(
      title: 'Welcome to GetMeBack',
      body:
          'Cartoon stress relief. Smash, splash, and laugh — then breathe.',
      visual: _DemoVisual.welcome,
      duration: Duration(seconds: 4),
      sfx: Sfx.whoosh,
    ),
    _DemoStep(
      title: 'Step 1 — Pick a path',
      body:
          'Home has two doors: Characters (faces) or Rooms & Scenes (smash props).',
      visual: _DemoVisual.chooseMode,
      duration: Duration(seconds: 5),
    ),
    _DemoStep(
      title: 'Characters',
      body:
          'Use a preset face or upload a photo. Then open the vent menu.',
      visual: _DemoVisual.characters,
      duration: Duration(seconds: 5),
      sfx: Sfx.hit,
    ),
    _DemoStep(
      title: 'Vent scenes',
      body:
          'Smash face, blender, lightning, volcano… 20+ cartoon actions on your target.',
      visual: _DemoVisual.ventActions,
      duration: Duration(seconds: 6),
      sfx: Sfx.smash,
    ),
    _DemoStep(
      title: 'Rooms & Scenes',
      body:
          'Kitchen, bathroom, office, cabin… 20 room setups packed with smashable props.',
      visual: _DemoVisual.rooms,
      duration: Duration(seconds: 6),
      sfx: Sfx.boom,
    ),
    _DemoStep(
      title: 'How to smash a room',
      body:
          'Tap props to break them. Pick up a glass, then throw it at the sofa — reactions change!',
      visual: _DemoVisual.smashTips,
      duration: Duration(seconds: 6),
      sfx: Sfx.splash,
    ),
    _DemoStep(
      title: 'Calm outro',
      body:
          'After you vent, a short breathing screen helps you reset. That’s the GetMeBack part.',
      visual: _DemoVisual.calm,
      duration: Duration(seconds: 5),
      sfx: Sfx.confetti,
    ),
    _DemoStep(
      title: 'Your turn',
      body:
          'Demo complete. Try Characters or Rooms — or replay this tour anytime.',
      visual: _DemoVisual.ready,
      duration: Duration(seconds: 8),
    ),
  ];

  final DramaticFxController _fx = DramaticFxController();
  int _index = 0;
  bool _paused = false;
  Timer? _timer;
  double _progress = 0;
  Timer? _tick;
  final _rng = Random();

  _DemoStep get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    _fx.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStep());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tick?.cancel();
    _fx.dispose();
    super.dispose();
  }

  void _startStep() {
    _timer?.cancel();
    _tick?.cancel();
    _progress = 0;
    final step = _step;
    if (step.sfx != null) {
      VentSfx.instance.unlock();
      VentSfx.instance.play(step.sfx!);
    }
    _burstFor(step.visual);
    if (_paused) {
      setState(() {});
      return;
    }
    final totalMs = step.duration.inMilliseconds;
    const tickMs = 50;
    var elapsed = 0;
    _tick = Timer.periodic(const Duration(milliseconds: tickMs), (_) {
      if (!mounted || _paused) return;
      elapsed += tickMs;
      setState(() => _progress = (elapsed / totalMs).clamp(0, 1));
      if (elapsed >= totalMs) {
        _tick?.cancel();
        _next();
      }
    });
  }

  void _burstFor(_DemoVisual v) {
    final size = MediaQuery.sizeOf(context);
    final c = Offset(size.width / 2, size.height * 0.38);
    switch (v) {
      case _DemoVisual.welcome:
      case _DemoVisual.ready:
        _fx.confettiBurst(at: c, count: 70);
        _fx.glitterRain(at: c, count: 40);
        break;
      case _DemoVisual.ventActions:
      case _DemoVisual.smashTips:
        _fx.megaImpact(at: c, color: AppTheme.accent);
        _fx.comicPop(at: c, color: AppTheme.gold);
        break;
      case _DemoVisual.rooms:
        _fx.crackerBurst(at: c, volleys: 3);
        break;
      case _DemoVisual.calm:
        _fx.glitterRain(at: c, count: 55);
        break;
      case _DemoVisual.chooseMode:
      case _DemoVisual.characters:
        _fx.impact(at: c, count: 20, intensity: 0.8, color: AppTheme.gold);
        break;
    }
  }

  void _next() {
    if (_index >= _steps.length - 1) {
      setState(() => _progress = 1);
      return;
    }
    setState(() => _index++);
    _startStep();
  }

  void _prev() {
    if (_index <= 0) return;
    setState(() => _index--);
    _startStep();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (!_paused) {
      _startStep();
    } else {
      _tick?.cancel();
      _timer?.cancel();
    }
  }

  void _replay() {
    setState(() {
      _index = 0;
      _paused = false;
    });
    _startStep();
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final isLast = _index == _steps.length - 1;

    return Scaffold(
      body: DramaticFxTicker(
        controller: _fx,
        child: PremiumBackdrop(
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: VentFxLayer(
                    fx: _fx,
                    child: const SizedBox.expand(),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Exit demo',
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.close),
                          ),
                          Expanded(
                            child: Text(
                              'Demo  ${_index + 1} / ${_steps.length}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.goldSoft,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: _paused ? 'Resume' : 'Pause',
                            onPressed: _togglePause,
                            icon: Icon(
                              _paused ? Icons.play_arrow : Icons.pause,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 4,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.1),
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          child: KeyedSubtree(
                            key: ValueKey(_index),
                            child: _DemoVisualPane(
                              visual: step.visual,
                              roomPreview: RoomSetup
                                  .all[_rng.nextInt(RoomSetup.all.length)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: GlassPanel(
                        goldEdge: true,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: AppTheme.gold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step.body,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _index > 0 ? _prev : null,
                                  child: const Text('Back'),
                                ),
                                const Spacer(),
                                if (isLast) ...[
                                  TextButton(
                                    onPressed: _replay,
                                    child: const Text('Replay'),
                                  ),
                                  const SizedBox(width: 8),
                                  ShineButton(
                                    label: 'Try Rooms',
                                    icon: Icons.meeting_room,
                                    onPressed: () => context.go('/rooms'),
                                  ),
                                ] else
                                  TextButton(
                                    onPressed: () {
                                      _tick?.cancel();
                                      _next();
                                    },
                                    child: const Text('Skip ›'),
                                  ),
                              ],
                            ),
                            if (isLast) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go('/characters'),
                                  icon: const Icon(Icons.face),
                                  label: const Text('Try Characters'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoVisualPane extends StatelessWidget {
  const _DemoVisualPane({
    required this.visual,
    required this.roomPreview,
  });

  final _DemoVisual visual;
  final RoomSetup roomPreview;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
        child: switch (visual) {
          _DemoVisual.welcome => _WelcomeArt(),
          _DemoVisual.chooseMode => const _TwoDoorsArt(),
          _DemoVisual.characters => const _FacesArt(),
          _DemoVisual.ventActions => const _ActionsArt(),
          _DemoVisual.rooms => _RoomsArt(room: roomPreview),
          _DemoVisual.smashTips => const _SmashTipArt(),
          _DemoVisual.calm => const _CalmArt(),
          _DemoVisual.ready => const _ReadyArt(),
        },
      ),
    );
  }
}

class _WelcomeArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.gold, AppTheme.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.45),
                blurRadius: 28,
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, size: 54, color: Colors.white),
        ),
        const SizedBox(height: 18),
        const GradientTitle('GetMeBack'),
      ],
    );
  }
}

class _TwoDoorsArt extends StatelessWidget {
  const _TwoDoorsArt();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _miniDoor(
            Icons.face_retouching_natural,
            'Characters',
            const Color(0xFFE94560),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniDoor(
            Icons.meeting_room,
            'Rooms',
            const Color(0xFF26A69A),
          ),
        ),
      ],
    );
  }

  Widget _miniDoor(IconData icon, String label, Color color) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _FacesArt extends StatelessWidget {
  const _FacesArt();

  @override
  Widget build(BuildContext context) {
    final faces = ['😠', '😤', '🙄', '😾', '😒', '😼'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final e in faces)
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
            ),
            child: Text(e, style: const TextStyle(fontSize: 36)),
          ),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.gold, width: 2),
          ),
          child: const Icon(Icons.upload, color: AppTheme.gold, size: 32),
        ),
      ],
    );
  }
}

class _ActionsArt extends StatelessWidget {
  const _ActionsArt();

  @override
  Widget build(BuildContext context) {
    final actions = VentAction.all.take(12).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final a = actions[i];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: a.color.withValues(alpha: 0.35),
            border: Border.all(color: a.color.withValues(alpha: 0.6)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(a.icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                a.title.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoomsArt extends StatelessWidget {
  const _RoomsArt({required this.room});

  final RoomSetup room;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: room.gradient,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(room.icon, size: 56, color: room.accent),
            const SizedBox(height: 12),
            Text(
              room.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            Text(
              '${room.props.length} smashable props',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final p in room.props.take(6))
                  Chip(
                    avatar: Icon(p.icon, size: 16, color: Colors.white),
                    label: Text(p.label, style: const TextStyle(fontSize: 11)),
                    backgroundColor: p.color.withValues(alpha: 0.45),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmashTipArt extends StatelessWidget {
  const _SmashTipArt();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _propBubble(Icons.local_bar, 'Glass', const Color(0xFF81D4FA)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward, color: AppTheme.gold, size: 32),
        ),
        _propBubble(Icons.weekend, 'Sofa', const Color(0xFF8D6E63)),
        const SizedBox(width: 12),
        const Text('💦', style: TextStyle(fontSize: 36)),
      ],
    );
  }

  Widget _propBubble(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: 0.85),
          ),
          child: Icon(icon, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CalmArt extends StatelessWidget {
  const _CalmArt();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.calm, width: 3),
            color: AppTheme.calm.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.air, size: 48, color: AppTheme.calm),
        ),
        const SizedBox(height: 16),
        const Text(
          'Breathe in… breathe out',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ],
    );
  }
}

class _ReadyArt extends StatelessWidget {
  const _ReadyArt();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 72, color: AppTheme.gold),
        SizedBox(height: 12),
        Text(
          'You’re ready',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
      ],
    );
  }
}
