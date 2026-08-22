import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/room_hotspots.dart';
import '../models/room_setup.dart';
import '../models/vent_target.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/base_vent_scene.dart';
import '../widgets/dramatic_fx.dart';
import '../widgets/vent_scene_shell.dart';

class RoomRampageScene extends StatefulWidget {
  const RoomRampageScene({
    super.key,
    required this.target,
    required this.room,
  });

  final VentTarget target;
  final RoomSetup room;

  @override
  State<RoomRampageScene> createState() => _RoomRampageSceneState();
}

class _RoomRampageSceneState extends BaseVentSceneState<RoomRampageScene> {
  final Set<String> _smashed = {};
  String? _holdingId;
  String? _banner;
  bool _showCoach = true;
  late final AnimationController _pulse;
  final _rng = Random();

  int get _total => widget.room.props.length;
  int get _done => _smashed.length;
  bool get _cleared => _done >= _total;

  RoomProp? get _holding {
    if (_holdingId == null) return null;
    for (final p in widget.room.props) {
      if (p.id == _holdingId) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _setBanner('Tap the glowing objects to smash them');
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _dismissCoach() {
    if (!_showCoach) return;
    setState(() => _showCoach = false);
  }

  void _setBanner(String text) {
    setState(() => _banner = text);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _banner == text) setState(() => _banner = null);
    });
  }

  void _playStyle(PropSmashStyle style) {
    switch (style) {
      case PropSmashStyle.shatter:
      case PropSmashStyle.crack:
        VentSfx.instance.play(Sfx.smash);
        VentSfx.heavy();
        break;
      case PropSmashStyle.spill:
      case PropSmashStyle.splash:
        VentSfx.instance.play(Sfx.splash);
        VentSfx.medium();
        break;
      case PropSmashStyle.explode:
        VentSfx.instance.play(Sfx.boom);
        VentSfx.heavy();
        break;
      case PropSmashStyle.tipOver:
      case PropSmashStyle.smashFlat:
        VentSfx.instance.play(Sfx.hit);
        VentSfx.medium();
        break;
    }
  }

  void _burst(Offset at, PropSmashStyle style, Color color) {
    switch (style) {
      case PropSmashStyle.shatter:
      case PropSmashStyle.crack:
        fx.megaImpact(at: at, color: color);
        fx.comicPop(at: at, color: color);
        break;
      case PropSmashStyle.spill:
      case PropSmashStyle.splash:
        fx.impact(at: at, count: 36, intensity: 1.2, color: color);
        fx.glitterRain(at: at, count: 28);
        break;
      case PropSmashStyle.explode:
        fx.megaImpact(at: at, color: color);
        fx.crackerBurst(at: at, volleys: 3);
        break;
      case PropSmashStyle.tipOver:
      case PropSmashStyle.smashFlat:
        fx.impact(at: at, count: 24, intensity: 1.0, color: color);
        fx.comicPop(at: at, color: AppTheme.gold);
        break;
    }
  }

  void _onPropTap(RoomProp prop, Offset center) {
    if (_smashed.contains(prop.id)) return;
    _dismissCoach();

    final holding = _holding;

    // Throw held item at this prop.
    if (holding != null && holding.id != prop.id) {
      final reaction = prop.reactions[holding.id] ??
          (holding.id == 'glass' ||
                  holding.label.toLowerCase().contains('glass')
              ? prop.reactions['glass']
              : null);

      setState(() {
        _smashed.add(holding.id);
        _smashed.add(prop.id);
        _holdingId = null;
      });

      final style = reaction?.style ?? prop.style;
      final msg = reaction?.message ??
          '${holding.label} → ${prop.label}!';
      _setBanner(msg);
      _playStyle(style);
      _burst(center, style, prop.color);
      _maybeFinish(center);
      return;
    }

    // Pick up throwable (first tap) — does NOT smash yet.
    if (prop.throwable && _holdingId == null) {
      setState(() => _holdingId = prop.id);
      VentSfx.light();
      VentSfx.instance.play(Sfx.whoosh);
      _setBanner('Holding ${prop.label} — now TAP another object to throw');
      return;
    }

    // Direct smash.
    setState(() {
      _smashed.add(prop.id);
      if (_holdingId == prop.id) _holdingId = null;
    });
    final quirks = <String>[
      '${prop.label} smashed!',
      'CRASH — ${prop.label}!',
      '${prop.label} is gone!',
    ];
    _setBanner(quirks[_rng.nextInt(quirks.length)]);
    _playStyle(prop.style);
    _burst(center, prop.style, prop.color);
    _maybeFinish(center);
  }

  void _maybeFinish(Offset center) {
    if (!_cleared) return;
    fx.confettiBurst(at: center, count: 90);
    fx.crackerBurst(at: center, volleys: 4);
    fx.glitterRain(at: center, count: 50);
    VentSfx.instance.play(Sfx.confetti);
    _setBanner('Room cleared. Feel better?');
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) context.go('/calm/${widget.target.id}');
    });
  }

  void _cancelHold() {
    if (_holdingId == null) return;
    setState(() => _holdingId = null);
    _setBanner('Put down. Tap an object to smash.');
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final holding = _holding;

    return DramaticFxTicker(
      controller: fx,
      child: VentSceneShell(
        target: widget.target,
        title: room.name,
        hint: _cleared
            ? 'Room wrecked. Nice.'
            : holding != null
                ? 'THROW: tap any other glowing object'
                : 'SMASH: tap glowing objects · glass/cups pick up first',
        showTarget: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              fit: StackFit.expand,
              children: [
                // Full-bleed room art
                Positioned.fill(
                  child: Image.asset(
                    room.resolvedAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: room.gradient,
                        ),
                      ),
                    ),
                  ),
                ),
                // Soft vignette so props pop
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.15,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),
                // Empty space: cancel hold only (never auto-smash)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _cancelHold,
                    child: const SizedBox.expand(),
                  ),
                ),
                    ventFxLayer(
                  fx: fx,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (holding != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        left: 10,
                        right: 10,
                        child: _HudBar(
                          room: room,
                          done: _done,
                          total: _total,
                          holding: holding,
                        ),
                      ),
                      for (final prop in room.props)
                        _SmashableProp(
                          roomId: room.id,
                          prop: prop,
                          smashed: _smashed.contains(prop.id),
                          holding: _holdingId == prop.id,
                          throwTarget: holding != null &&
                              holding.id != prop.id &&
                              !_smashed.contains(prop.id),
                          pulse: _pulse,
                          stage: size,
                          onTap: (center) => _onPropTap(prop, center),
                        ),
                      if (_banner != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 56,
                          child: IgnorePointer(
                            child: _BannerChip(text: _banner!),
                          ),
                        ),
                      if (!_cleared && _done > 0)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: IgnorePointer(
                            child: _RemainingStrip(
                              room: room,
                              smashed: _smashed,
                            ),
                          ),
                        ),
                      if (_showCoach)
                        Positioned.fill(
                          child: _CoachOverlay(
                            onGotIt: _dismissCoach,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HudBar extends StatelessWidget {
  const _HudBar({
    required this.room,
    required this.done,
    required this.total,
    required this.holding,
  });

  final RoomSetup room;
  final int done;
  final int total;
  final RoomProp? holding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(room.icon, color: room.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                holding == null
                    ? 'Tap objects to smash'
                    : 'Holding ${holding!.label} — tap a target',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '$done/$total',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemainingStrip extends StatelessWidget {
  const _RemainingStrip({
    required this.room,
    required this.smashed,
  });

  final RoomSetup room;
  final Set<String> smashed;

  @override
  Widget build(BuildContext context) {
    final left = room.props.where((p) => !smashed.contains(p.id)).toList();
    if (left.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Text(
              '${left.length} left',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final p in left.take(8))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: p.color.withValues(alpha: 0.35),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(p.icon, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                p.label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}

class _CoachOverlay extends StatelessWidget {
  const _CoachOverlay({required this.onGotIt});

  final VoidCallback onGotIt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, color: AppTheme.gold, size: 42),
                      const SizedBox(height: 12),
                      const Text(
                        'How Room Rampage works',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _tip(Icons.flash_on, 'Tap the pulsing pins on furniture — not empty wall'),
                      _tip(Icons.back_hand, 'Glass / cups: first tap = pick up'),
                      _tip(Icons.sports_handball,
                          'Then TAP another object to throw & react'),
                      _tip(Icons.block, 'Empty background never smashes itself'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onGotIt,
                          child: const Text('Got it — smash away'),
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
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.goldSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.3,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmashableProp extends StatelessWidget {
  const _SmashableProp({
    required this.roomId,
    required this.prop,
    required this.smashed,
    required this.holding,
    required this.throwTarget,
    required this.pulse,
    required this.stage,
    required this.onTap,
  });

  final String roomId;
  final RoomProp prop;
  final bool smashed;
  final bool holding;
  final bool throwTarget;
  final Animation<double> pulse;
  final Size stage;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    const hit = 72.0;
    final norm = RoomHotspots.forProp(
      roomId: roomId,
      propId: prop.id,
      fallback: prop.align,
    );
    final dx = norm.dx * stage.width;
    final dy = norm.dy * stage.height;
    final center = Offset(dx, dy);

    final accent = holding
        ? AppTheme.gold
        : throwTarget
            ? const Color(0xFFFFEB3B)
            : Colors.white;

    return Positioned(
      left: dx - hit / 2,
      top: dy - hit / 2,
      width: hit,
      height: hit + 20,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: smashed ? null : () => onTap(center),
        child: AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            if (smashed) {
              return Opacity(
                opacity: 0.2,
                child: _pin(accent, ringScale: 0.7, showLabel: false),
              );
            }

            final ringScale = 1 + pulse.value * 0.22;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: holding ? 1.1 : 1,
                  child: _pin(
                    accent,
                    ringScale: ringScale,
                    action: holding
                        ? 'HOLD'
                        : throwTarget
                            ? 'THROW'
                            : prop.throwable
                                ? 'PICK'
                                : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prop.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.92),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.95),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pin(
    Color accent, {
    required double ringScale,
    String? action,
    bool showLabel = true,
  }) {
    const core = 12.0;
    const ring = 36.0;
    return SizedBox(
      width: ring * ringScale * 1.4,
      height: ring * ringScale * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: ring * ringScale,
            height: ring * ringScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
          ),
          Container(
            width: core,
            height: core,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          if (action != null && showLabel)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Text(
                  action,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
