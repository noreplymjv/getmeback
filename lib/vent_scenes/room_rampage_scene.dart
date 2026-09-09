import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/prop_state.dart';
import '../models/room_setup.dart';
import '../models/vent_target.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/base_vent_scene.dart';
import '../widgets/dramatic_fx.dart';
import '../widgets/interactive_room_prop.dart';
import '../widgets/prop_destruction_scars.dart';
import '../widgets/prop_shatter_fx.dart';
import '../widgets/prop_voronoi_shatter.dart';
import '../widgets/smash_weapon_overlay.dart';
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
  final Map<String, int> _damageStages = {};

  final List<VoronoiShard> _voronoiShards = [];
  Offset? _strikeLightPoint;
  Color? _strikeLightColor;
  double _strikeLightIntensity = 0.0;

  SmashWeapon _selectedWeapon = SmashWeapon.hammer;
  final List<WeaponStrikeInstance> _strikes = [];
  int _strikeCounter = 0;

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

  int _maxHitsFor(RoomProp prop) {
    if (prop.effectiveMaterial == PropMaterial.glass ||
        prop.id.contains('glass') ||
        prop.id.contains('cup') ||
        prop.id.contains('mug') ||
        prop.id.contains('bulb') ||
        prop.id.contains('bottle')) {
      return 2;
    }
    return 3;
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
      'Select a demolition weapon & tap objects to smash',
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
    if (!mounted) return;
    if (_voronoiShards.isNotEmpty) {
      final size = MediaQuery.sizeOf(context);
      final floorY = size.height * 0.82;
      for (final s in _voronoiShards) {
        s.tick(0.016, floorY: floorY);
      }
      _voronoiShards.removeWhere((s) => s.life <= 0);
    }
    setState(() {});
  }

  void _triggerStrikeLight(Offset at, Color color) {
    setState(() {
      _strikeLightPoint = at;
      _strikeLightColor = color;
      _strikeLightIntensity = 1.0;
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() => _strikeLightIntensity = 0.0);
      }
    });
  }

  void _handleSwipeStrike(Offset velocity, Size stage, Offset stageOrigin) {
    if (_cleared) return;
    RoomProp? target;
    double closestDist = double.infinity;
    final centerStage = Offset(stage.width / 2, stage.height / 2);
    for (final p in widget.room.props) {
      if (_smashed.contains(p.id) || _smashing.contains(p.id)) continue;
      final a = p.anchorFor(widget.room.id);
      final propPos = Offset(a.dx * stage.width, a.dy * stage.height);
      final d = (propPos - centerStage).distance;
      if (d < closestDist) {
        closestDist = d;
        target = p;
      }
    }
    if (target != null) {
      final a = target.anchorFor(widget.room.id);
      final propCenter = Offset(a.dx * stage.width, a.dy * stage.height);
      _onPropTap(target, propCenter, propCenter + stageOrigin, stage);
      _setBanner('KINETIC SWIPE! ${target.label} struck!');
    }
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

  void _playWeaponAudio(SmashWeapon weapon, PropMaterial material) {
    switch (weapon) {
      case SmashWeapon.hammer:
        VentSfx.instance.play(Sfx.smash);
        VentSfx.heavy();
        break;
      case SmashWeapon.baseballBat:
        VentSfx.instance.play(Sfx.hit);
        VentSfx.medium();
        break;
      case SmashWeapon.laser:
        VentSfx.instance.play(Sfx.zap);
        VentSfx.light();
        break;
      case SmashWeapon.punch:
        VentSfx.instance.play(Sfx.hit);
        VentSfx.medium();
        break;
      case SmashWeapon.wreckingBall:
        VentSfx.instance.play(Sfx.boom);
        VentSfx.heavy();
        break;
    }
  }

  void _playMaterial(PropMaterial material, PropSmashStyle style) {
    switch (material) {
      case PropMaterial.glass:
        VentSfx.instance.play(Sfx.crack);
      case PropMaterial.ceramic:
        VentSfx.instance.play(Sfx.smash);
      case PropMaterial.wood:
        VentSfx.instance.play(Sfx.hit);
      case PropMaterial.metal:
        VentSfx.instance.play(Sfx.zap);
      case PropMaterial.plastic:
        VentSfx.instance.play(Sfx.pop);
      case PropMaterial.fabric:
        VentSfx.instance.play(Sfx.whoosh);
    }
    // ignore: unawaited_futures
    VentSfx.material(material);
    if (style == PropSmashStyle.spill || style == PropSmashStyle.splash) {
      VentSfx.instance.play(Sfx.splash);
    } else if (style == PropSmashStyle.explode) {
      VentSfx.instance.play(Sfx.boom);
      VentSfx.heavy();
    }
  }

  void _spawnWeaponStrike(Offset pos) {
    final strike = WeaponStrikeInstance(
      id: ++_strikeCounter,
      weapon: _selectedWeapon,
      position: pos,
      createdAt: DateTime.now(),
    );
    setState(() {
      _strikes.add(strike);
      _strikes.removeWhere((s) => s.isFinished);
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        setState(() => _strikes.removeWhere((s) => s.id == strike.id));
      }
    });
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
    final material = prop.effectiveMaterial;
    fx.triggerHitStop(material.hitStop);
    _playMaterial(material, style);
    if (!StorageService.instance.reducedFxEnabled) {
      _burst(viewportCenter, style, prop.color, prop: prop);
      // V3 Procedural Voronoi Shatter
      final w = prop.effectiveSizeNorm * stage.width;
      final propSize = Size(w, w * prop.effectiveAspectRatio);
      final voronoi = VoronoiShatterEngine.fracture(
        stageCenter: viewportCenter,
        propSize: propSize,
        localImpact: Offset(propSize.width / 2, propSize.height / 2),
        color: prop.color,
        material: material,
        cellCount: 16,
      );
      _voronoiShards.addAll(voronoi);

      // V3 Optical Shockwave & Chromatic Aberration
      fx.triggerShockwave(
        at: viewportCenter,
        color: prop.color,
        maxRadius: 340.0,
        chromatic: 0.82,
      );
      _triggerStrikeLight(viewportCenter, prop.color);
    } else {
      // Softened juice when Reduce motion is on.
      fx.impact(at: viewportCenter, count: 12, intensity: 0.7, color: prop.color);
    }
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

    // Spawn active weapon strike visual at tap coordinates
    _spawnWeaponStrike(viewportCenter);

    final holding = _holding;

    // Throw held item at this prop (instant combo smash)
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

    // Pick up throwable (first tap) if not yet damaged
    final currentStage = _damageStages[prop.id] ?? 0;
    if (prop.throwable && _holdingId == null && currentStage == 0) {
      setState(() => _holdingId = prop.id);
      VentSfx.light();
      VentSfx.instance.play(Sfx.whoosh);
      _setBanner('Holding ${prop.label} — now TAP another object to throw');
      return;
    }

    final maxHits = _maxHitsFor(prop);
    final nextStage = currentStage + 1;
    _damageStages[prop.id] = nextStage;

    if (nextStage < maxHits) {
      // Intermediate hit: Micro debris, crack decal, screen jolt
      _playWeaponAudio(_selectedWeapon, prop.effectiveMaterial);
      _shatter.microBurst(
        at: viewportCenter,
        color: prop.color,
        style: prop.effectiveMaterial.shatterStyle,
        count: 8,
      );
      fx.shakeBurst(amp: 10, duration: 0.18);
      fx.impact(at: viewportCenter, count: 12, color: _selectedWeapon.color);
      setState(() {});
      _setBanner('${prop.label} cracking! ($nextStage/$maxHits hits)');
    } else {
      // Final hit: Full destruction shatter
      final quirks = <String>[
        '${prop.label} smashed to pieces!',
        'CRASH — ${prop.label} obliterated!',
        '${prop.label} is destroyed!',
      ];
      _beginSmash(
        prop,
        stageCenter,
        viewportCenter,
        stage,
        banner: quirks[_rng.nextInt(quirks.length)],
      );
    }
  }

  void _maybeFinish(Offset center) {
    if (!_cleared) return;
    fx.triggerBulletTime(duration: const Duration(milliseconds: 1800));
    fx.confettiBurst(at: center, count: 90);
    fx.crackerBurst(at: center, volleys: 4);
    fx.glitterRain(at: center, count: 50);
    VentSfx.instance.play(Sfx.confetti);
    _setBanner('Room cleared. Feel better?');
    Future.delayed(const Duration(milliseconds: 2200), () {
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
                  : 'SMASH: tap objects with ${_selectedWeapon.label}',
          showTarget: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport =
                  Size(constraints.maxWidth, constraints.maxHeight);
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

              return MouseRegion(
                onHover: (event) {
                  final center = Offset(viewport.width / 2, viewport.height / 2);
                  final norm = Offset(
                    (event.position.dx - center.dx) / (viewport.width / 2),
                    (event.position.dy - center.dy) / (viewport.height / 2),
                  );
                  SensorService.instance.updatePointerParallax(norm);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
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
                        onPanEnd: (details) {
                          final v = details.velocity.pixelsPerSecond;
                          if (v.distance > 350) {
                            _handleSwipeStrike(v, stage, stageOrigin);
                          }
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // V3 Dynamic Point-Lighting on Strikes
                    if (_strikeLightIntensity > 0.01 && _strikeLightPoint != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _StrikeLightPainter(
                              point: _strikeLightPoint!,
                              color: _strikeLightColor ?? AppTheme.gold,
                              intensity: _strikeLightIntensity,
                            ),
                          ),
                        ),
                      ),
                    // V3 Procedural Voronoi Shatter Layer
                    if (_voronoiShards.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: VoronoiShatterPainter(shards: _voronoiShards),
                          ),
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
                          // Top HUD
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
                          // Interactive Room Props
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
                                    damageStage: _damageStages[prop.id] ?? 0,
                                    maxDamageStage: _maxHitsFor(prop),
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
                          // Animated Weapon Strike Overlays
                          SmashWeaponOverlay(
                            selectedWeapon: _selectedWeapon,
                            onSelectWeapon: (w) => setState(() => _selectedWeapon = w),
                            strikes: _strikes,
                          ),
                          // Bottom Floating Weapon Selector Bar
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 12,
                            child: Center(
                              child: SmashWeaponSelectorBar(
                                selectedWeapon: _selectedWeapon,
                                onSelectWeapon: (w) {
                                  setState(() => _selectedWeapon = w);
                                  _setBanner('Equipped ${w.label}');
                                  VentSfx.light();
                                },
                              ),
                            ),
                          ),
                          if (_banner != null)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 66,
                              child: IgnorePointer(
                                child: _BannerChip(text: _banner!),
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
              ),
            );
            },
          ),
        ),
      ),
    );
  }

  static Size _coverStage(Size viewport, double imageAspect) {
    final viewAspect = viewport.width / viewport.height;
    if (viewAspect > imageAspect) {
      return Size(viewport.width, viewport.width / imageAspect);
    }
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
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
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
                    ? '${room.name} — Smash each object'
                    : 'Holding ${holding!.label} — tap target to throw',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '$done/$total cleared',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.gold,
                fontSize: 12,
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
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
      color: Colors.black.withValues(alpha: 0.68),
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
                      const Icon(Icons.handyman, color: AppTheme.gold, size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'Realistic Room Demolition',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _tip(
                        Icons.gavel,
                        'Pick your weapon below (Hammer, Bat, Laser, Fist, Wrecking Ball)',
                      ),
                      _tip(
                        Icons.touch_app,
                        'Tap objects to crack them progressively before final shatter',
                      ),
                      _tip(
                        Icons.back_hand,
                        'Glass / cups can also be thrown at other room objects',
                      ),
                      _tip(
                        Icons.spa,
                        'Clearing the room unlocks the soothing Cool Down reset',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onGotIt,
                          child: const Text('Start Demolition'),
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
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrikeLightPainter extends CustomPainter {
  _StrikeLightPainter({
    required this.point,
    required this.color,
    required this.intensity,
  });

  final Offset point;
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;
    final rect = Rect.fromCircle(center: point, radius: 260.0);
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: intensity * 0.48),
          color.withValues(alpha: intensity * 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _StrikeLightPainter oldDelegate) =>
      oldDelegate.intensity != intensity ||
      oldDelegate.point != point ||
      oldDelegate.color != color;
}
