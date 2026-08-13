import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/vent_action.dart';
import 'models/vent_target.dart';
import 'screens/calm_outro_screen.dart';
import 'screens/create_character_screen.dart';
import 'screens/home_screen.dart';
import 'screens/vent_menu_screen.dart';
import 'services/storage_service.dart';
import 'vent_scenes/anvil_drop_scene.dart';
import 'vent_scenes/balloon_pop_scene.dart';
import 'vent_scenes/black_hole_scene.dart';
import 'vent_scenes/blender_scene.dart';
import 'vent_scenes/boxing_ko_scene.dart';
import 'vent_scenes/catapult_scene.dart';
import 'vent_scenes/dart_throw_scene.dart';
import 'vent_scenes/fire_poof_scene.dart';
import 'vent_scenes/ice_shatter_scene.dart';
import 'vent_scenes/lightning_scene.dart';
import 'vent_scenes/paint_bomb_scene.dart';
import 'vent_scenes/pinata_scene.dart';
import 'vent_scenes/punch_bag_scene.dart';
import 'vent_scenes/shredder_scene.dart';
import 'vent_scenes/sink_scene.dart';
import 'vent_scenes/sledgehammer_scene.dart';
import 'vent_scenes/smash_scene.dart';
import 'vent_scenes/stomp_scene.dart';
import 'vent_scenes/tornado_scene.dart';
import 'vent_scenes/trash_can_scene.dart';
import 'vent_scenes/volcano_scene.dart';

CustomTransitionPage<void> _fadeSlide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _fadeSlide(state, const HomeScreen()),
    ),
    GoRoute(
      path: '/create',
      pageBuilder: (context, state) =>
          _fadeSlide(state, const CreateCharacterScreen()),
    ),
    GoRoute(
      path: '/vent-menu/:targetId',
      pageBuilder: (context, state) {
        final targetId = state.pathParameters['targetId']!;
        return _fadeSlide(state, VentMenuScreen(targetId: targetId));
      },
    ),
    GoRoute(
      path: '/calm/:targetId',
      pageBuilder: (context, state) {
        final targetId = state.pathParameters['targetId']!;
        return _fadeSlide(state, CalmOutroScreen(targetId: targetId));
      },
    ),
    GoRoute(
      path: '/vent/:action/:targetId',
      pageBuilder: (context, state) {
        final actionName = state.pathParameters['action']!;
        final targetId = state.pathParameters['targetId']!;
        return _fadeSlide(
          state,
          _VentSceneLoader(
            actionName: actionName,
            targetId: targetId,
          ),
        );
      },
    ),
  ],
);

class _VentSceneLoader extends StatefulWidget {
  const _VentSceneLoader({
    required this.actionName,
    required this.targetId,
  });

  final String actionName;
  final String targetId;

  @override
  State<_VentSceneLoader> createState() => _VentSceneLoaderState();
}

class _VentSceneLoaderState extends State<_VentSceneLoader> {
  VentTarget? _target;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final targets = await StorageService.instance.loadTargets();
    final target = targets.where((t) => t.id == widget.targetId).firstOrNull;
    if (mounted) setState(() => _target = target);
  }

  @override
  Widget build(BuildContext context) {
    if (_target == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final type = VentActionType.values
        .where((t) => t.name == widget.actionName)
        .firstOrNull;

    if (type == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unknown action')),
        body: const Center(child: Text('Vent action not found')),
      );
    }

    final target = _target!;

    return switch (type) {
      VentActionType.smash => SmashScene(target: target),
      VentActionType.blender => BlenderScene(target: target),
      VentActionType.punchBag => PunchBagScene(target: target),
      VentActionType.trashCan => TrashCanScene(target: target),
      VentActionType.balloonPop => BalloonPopScene(target: target),
      VentActionType.firePoof => FirePoofScene(target: target),
      VentActionType.stomp => StompScene(target: target),
      VentActionType.iceShatter => IceShatterScene(target: target),
      VentActionType.dartThrow => DartThrowScene(target: target),
      VentActionType.sledgehammer => SledgehammerScene(target: target),
      VentActionType.catapult => CatapultScene(target: target),
      VentActionType.lightning => LightningScene(target: target),
      VentActionType.sink => SinkScene(target: target),
      VentActionType.shredder => ShredderScene(target: target),
      VentActionType.pinata => PinataScene(target: target),
      VentActionType.anvilDrop => AnvilDropScene(target: target),
      VentActionType.tornado => TornadoScene(target: target),
      VentActionType.paintBomb => PaintBombScene(target: target),
      VentActionType.blackHole => BlackHoleScene(target: target),
      VentActionType.boxingKo => BoxingKoScene(target: target),
      VentActionType.volcano => VolcanoScene(target: target),
    };
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
