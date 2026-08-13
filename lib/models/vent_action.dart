import 'package:flutter/material.dart';

enum VentActionType {
  smash,
  blender,
  punchBag,
  trashCan,
  balloonPop,
  firePoof,
  stomp,
  iceShatter,
  dartThrow,
  sledgehammer,
  catapult,
  lightning,
  sink,
  shredder,
  pinata,
}

class VentAction {
  const VentAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final VentActionType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  String get routePath => '/vent/${type.name}';

  static const List<VentAction> all = [
    VentAction(
      type: VentActionType.smash,
      title: 'Smash Face',
      subtitle: 'Tap & swipe to crack',
      icon: Icons.front_hand,
      color: Color(0xFFE94560),
    ),
    VentAction(
      type: VentActionType.blender,
      title: 'Juice Blender',
      subtitle: 'Drag into the swirl',
      icon: Icons.blender,
      color: Color(0xFFFF9800),
    ),
    VentAction(
      type: VentActionType.punchBag,
      title: 'Punch Bag',
      subtitle: 'Tap to punch',
      icon: Icons.sports_mma,
      color: Color(0xFFEF5350),
    ),
    VentAction(
      type: VentActionType.trashCan,
      title: 'Trash Can',
      subtitle: 'Toss it away',
      icon: Icons.delete_outline,
      color: Color(0xFF78909C),
    ),
    VentAction(
      type: VentActionType.balloonPop,
      title: 'Balloon Pop',
      subtitle: 'Tap to pop',
      icon: Icons.celebration,
      color: Color(0xFFAB47BC),
    ),
    VentAction(
      type: VentActionType.firePoof,
      title: 'Fire Poof',
      subtitle: 'Burn it away',
      icon: Icons.local_fire_department,
      color: Color(0xFFFF5722),
    ),
    VentAction(
      type: VentActionType.stomp,
      title: 'Stomp',
      subtitle: 'Tap to stomp flat',
      icon: Icons.directions_walk,
      color: Color(0xFF8D6E63),
    ),
    VentAction(
      type: VentActionType.iceShatter,
      title: 'Ice Shatter',
      subtitle: 'Freeze & crack',
      icon: Icons.ac_unit,
      color: Color(0xFF4FC3F7),
    ),
    VentAction(
      type: VentActionType.dartThrow,
      title: 'Dart Throw',
      subtitle: 'Aim & throw darts',
      icon: Icons.gps_fixed,
      color: Color(0xFF66BB6A),
    ),
    VentAction(
      type: VentActionType.sledgehammer,
      title: 'Sledgehammer',
      subtitle: 'Swing & smash',
      icon: Icons.hardware,
      color: Color(0xFF607D8B),
    ),
    VentAction(
      type: VentActionType.catapult,
      title: 'Catapult',
      subtitle: 'Launch into orbit',
      icon: Icons.rocket_launch,
      color: Color(0xFF795548),
    ),
    VentAction(
      type: VentActionType.lightning,
      title: 'Lightning Zap',
      subtitle: 'Call down thunder',
      icon: Icons.flash_on,
      color: Color(0xFFFFEB3B),
    ),
    VentAction(
      type: VentActionType.sink,
      title: 'Sink & Drown',
      subtitle: 'Fill the basin',
      icon: Icons.water_drop,
      color: Color(0xFF29B6F6),
    ),
    VentAction(
      type: VentActionType.shredder,
      title: 'Paper Shredder',
      subtitle: 'Shred to strips',
      icon: Icons.content_cut,
      color: Color(0xFF546E7A),
    ),
    VentAction(
      type: VentActionType.pinata,
      title: 'Piñata',
      subtitle: 'Whack for candy',
      icon: Icons.celebration,
      color: Color(0xFFE91E63),
    ),
  ];

  static VentAction? findByType(VentActionType type) {
    for (final action in all) {
      if (action.type == type) return action;
    }
    return null;
  }
}
