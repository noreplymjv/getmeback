import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/prop_state.dart';
import '../models/room_setup.dart';
import '../models/vent_target.dart';
import '../services/sensor_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/base_vent_scene.dart';
import '../widgets/dramatic_fx.dart';
import '../widgets/interactive_room_prop.dart';
import '../widgets/prop_destruction_scars.dart';
import '../widgets/prop_shatter_fx.dart';
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
  final Set<String> _smashing = {};
  String? _holdingId;
  String? _banner;
  bool _showCoach = true;
  late final AnimationController _pulse;
  late final PropShatterController _shatter;
  final List<DestructionScar> _scars = [];
  final _rng = Random();
  StreamSubscription<void>? _shakeSub;
  Offset _parallax = Offset.zero;

  static const _smashJuiceMs = 280;

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
    _shatter = PropShatterController()..addListener(_onShatterTick);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse.addListener(() {
      final p = SensorService.instance.parallax;
      if (p != _parallax && mounted) {
        setState(() => _parallax = p);
      }
    });
    _setBanner(
      'Tap the objects in the room to smash them',
    );
    SensorService.instance.start();
    _shakeSub = SensorService.instance.onShake.listen((_) => _earthquake());
  }

  void _earthquake() {
    if (!mounted || _cleared) return;
    final size = MediaQuery.sizeOf(context);
    final center = Offset(size.width / 2, size.height * 0.55);
    fx.triggerHitStop(const Duration(milliseconds: 50));
    fx.shakeBurst(amp: 26, duration: 0.45);
    fx.megaImpact(at: center, color: AppTheme.gold);
    fx.debrisRain(at: center, count: 30, color: const Color(0xFF8D6E63));
    VentSfx.heavy();
    _setBanner('EARTHQUAKE! Everything shook!');
  }

  void _onShatterTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
    SensorService.instance.stop();
    _shatter.removeListener(_onShatterTick);
    _shatter.dispose();
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

  void _playMaterial(PropMaterial material, PropSmashStyle style) {
    switch (material) {
      case PropMaterial.glass:
        VentSfx.instance.play(Sfx.crack);
        VentSfx.light();
      case PropMaterial.ceramic:
        VentSfx.instance.play(Sfx.smash);
        VentSfx.heavy();
      case PropMaterial.wood:
        VentSfx.instance.play(Sfx.hit);
        VentSfx.medium();
      case PropMaterial.metal:
        VentSfx.instance.play(Sfx.zap);
        VentSfx.medium();
      case PropMaterial.plastic:
        VentSfx.instance.play(Sfx.pop);
        VentSfx.light();
      case PropMaterial.fabric:
        VentSfx.instance.play(Sfx.whoosh);
        VentSfx.light();
    }
    if (style == PropSmashStyle.spill || style == PropSmashStyle.splash) {
      VentSfx.instance.play(Sfx.splash);
    } else if (style == PropSmashStyle.explode) {
      VentSfx.instance.play(Sfx.boom);
      VentSfx.heavy();
    }
  }

  void _playStyle(PropSmashStyle style, {PropMaterial? material}) {
    if (material != null) {
      _playMaterial(material, style);
      return;
    }
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

  void _burst(Offset at, PropSmashStyle style, Color color, {RoomProp? prop}) {
    if (prop != null) {
      final base = prop.color;
      final palette = <Color>[
        base,
        Color.lerp(base, Colors.white, 0.35)!,
        Color.lerp(base, Colors.black, 0.25)!,
        Color.lerp(base, const Color(0xFFFFD166), 0.2)!,
      ];
      _shatter.burst(
        at: at,
        color: base,
        style: prop.effectiveMaterial.shatterStyle,
        count: prop.effectiveMaterial.shardCount,
        palette: palette,
      );
    }
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

  void _leaveScar(RoomProp prop, Offset center, PropSmashStyle style, Size stage) {
    _scars.add(
      DestructionScar.fromProp(
        prop: prop,
        roomId: widget.room.id,
        stage: stage,
        center: center,
        style: style,
      ),
    );
  }

  void _finishSmash(RoomProp prop, Offset center, Size stage, PropSmashStyle style) {
    if (!mounted) return;
    setState(() {
      _smashing.remove(prop.id);
      _smashed.add(prop.id);
    });
    _leaveScar(prop, center, style, stage);
    _maybeFinish(center);
  }

  void _beginSmash(
    RoomProp prop,
    Offset stageCenter,
    Offset viewportCenter,
    Size stage, {
    PropSmashStyle? styleOverride,
    String? banner,
  }) {
    if (_smashed.contains(prop.id) || _smashing.contains(prop.id)) return;
    final style = styleOverride ?? prop.style;
    setState(() {
      _smashing.add(prop.id);
      if (_holdingId == prop.id) _holdingId = null;
    });
    if (banner != null) _setBanner(banner);
    _playStyle(style, material: prop.effectiveMaterial);
    _burst(viewportCenter, style, prop.color, prop: prop);
    Future.delayed(const Duration(milliseconds: _smashJuiceMs), () {
      _finishSmash(prop, stageCenter, stage, style);
    });
  }

  void _onPropTap(
    RoomProp prop,
    Offset stageCenter,
    Offset viewportCenter,
    Size stage,
  ) {
    if (_smashed.contains(prop.id) || _smashing.contains(prop.id)) return;
    _dismissCoach();

    final holding = _holding;

    // Throw held item at this prop.
    if (holding != null && holding.id != prop.id) {
      final reaction = prop.reactions[holding.id] ??
          (holding.id == 'glass' ||
                  holding.label.toLowerCase().contains('glass')
              ? prop.reactions['glass']
              : null);

      final style = reaction?.style ?? prop.style;
      final msg = reaction?.message ??
          '${holding.label} → ${prop.label}!';
      setState(() => _holdingId = null);
      _beginSmash(
        holding,
        stageCenter,
        viewportCenter,
        stage,
        styleOverride: style,
        banner: msg,
      );
      _beginSmash(
        prop,
        stageCenter,
        viewportCenter,
        stage,
        styleOverride: style,
      );
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

    // Direct smash with juice animation.
    final quirks = <String>[
      '${prop.label} smashed!',
      'CRASH — ${prop.label}!',
      '${prop.label} is gone!',
    ];
    _beginSmash(
      prop,
      stageCenter,
      viewportCenter,
      stage,
      banner: quirks[_rng.nextInt(quirks.length)],
    );
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
      child: PropShatterTicker(
        controller: _shatter,
        child: VentSceneShell(
          target: widget.target,
          title: room.name,
          hint: _cleared
              ? 'Room wrecked. Nice.'
              : holding != null
                  ? 'THROW: tap another object in the room'
                  : 'SMASH: tap objects directly · glass/cups pick up first',
          showTarget: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport =
                  Size(constraints.maxWidth, constraints.maxHeight);
              // Share one cover-fitted stage so props align to furniture.
              // Room art is 1536×1024 (3:2).
              const roomAspect = 1.5;
              final stage = _coverStage(viewport, roomAspect);
              final stageOrigin = Offset(
                (viewport.width - stage.width) / 2,
                (viewport.height - stage.height) / 2,
              );
              _shatter.floorY = stageOrigin.dy + stage.height * 0.92;
              _parallax = SensorService.instance.parallax;
              final props = List<RoomProp>.from(room.props)
                ..sort((a, b) => a.effectiveZIndex.compareTo(b.effectiveZIndex));
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Letterbox behind cover crop
                  const ColoredBox(color: Color(0xFF0A0814)),
                  Positioned(
                    left: stageOrigin.dx + _parallax.dx,
                    top: stageOrigin.dy + _parallax.dy,
                    width: stage.width,
                    height: stage.height,
                    child: Image.asset(
                      room.resolvedBaseAsset,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
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
                  Positioned(
                    left: stageOrigin.dx,
                    top: stageOrigin.dy,
                    width: stage.width,
                    height: stage.height,
                    child: DestructionScarsLayer(scars: _scars),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.15,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.32),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _cancelHold,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  VentFxLayer(
                    fx: fx,
                    child: propShatterLayer(
                      shatter: _shatter,
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
                          Positioned(
                            left: stageOrigin.dx,
                            top: stageOrigin.dy,
                            width: stage.width,
                            height: stage.height,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (final prop in props)
                                  InteractiveRoomProp(
                                    roomId: room.id,
                                    prop: prop,
                                    stage: stage,
                                    pulse: _pulse,
                                    smashed: _smashed.contains(prop.id),
                                    smashing: _smashing.contains(prop.id),
                                    holding: _holdingId == prop.id,
                                    throwTarget: holding != null &&
                                        holding.id != prop.id &&
                                        !_smashed.contains(prop.id) &&
                                        !_smashing.contains(prop.id),
                                    spriteMode: true,
                                    onTap: (center) => _onPropTap(
                                      prop,
                                      center,
                                      center + stageOrigin,
                                      stage,
                                    ),
                                  ),
                              ],
                            ),
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
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Stage size for BoxFit.cover of [imageAspect] into [viewport].
  static Size _coverStage(Size viewport, double imageAspect) {
    final viewAspect = viewport.width / viewport.height;
    if (viewAspect > imageAspect) {
      // Viewport wider than image → fill width, crop top/bottom.
      return Size(viewport.width, viewport.width / imageAspect);
    }
    // Viewport taller → fill height, crop sides.
    return Size(viewport.height * imageAspect, viewport.height);
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
                      _tip(
                        Icons.flash_on,
                        'Tap the real objects — plates, glasses, chairs',
                      ),
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
