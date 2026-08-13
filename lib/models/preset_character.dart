import 'package:flutter/material.dart';

class PresetCharacter {
  const PresetCharacter({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.assetPath,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String? assetPath;

  static const List<PresetCharacter> all = [
    PresetCharacter(
      id: 'angry_boss',
      name: 'Angry Boss',
      emoji: '👔',
      color: Color(0xFF5C6BC0),
      assetPath: 'assets/presets/angry_boss.png',
    ),
    PresetCharacter(
      id: 'rude_driver',
      name: 'Rude Driver',
      emoji: '🚗',
      color: Color(0xFFFF7043),
      assetPath: 'assets/presets/rude_driver.png',
    ),
    PresetCharacter(
      id: 'ex_friend',
      name: 'Ex Friend',
      emoji: '💔',
      color: Color(0xFFEC407A),
      assetPath: 'assets/presets/ex_friend.png',
    ),
    PresetCharacter(
      id: 'annoying_neighbor',
      name: 'Annoying Neighbor',
      emoji: '🏠',
      color: Color(0xFF66BB6A),
      assetPath: 'assets/presets/annoying_neighbor.png',
    ),
    PresetCharacter(
      id: 'karen',
      name: 'Karen',
      emoji: '😤',
      color: Color(0xFFAB47BC),
      assetPath: 'assets/presets/karen.png',
    ),
    PresetCharacter(
      id: 'grumpy_cat',
      name: 'Grumpy Cat',
      emoji: '🐱',
      color: Color(0xFF78909C),
      assetPath: 'assets/presets/grumpy_cat.png',
    ),
  ];

  static PresetCharacter? findById(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}
