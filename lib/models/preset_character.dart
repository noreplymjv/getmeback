import 'package:flutter/material.dart';

enum PresetCategory {
  all('All'),
  work('Work & Boss'),
  dating('Ex & Dating'),
  neighbor('Neighbors'),
  commute('Road & Commute'),
  public('Public & Chaos');

  const PresetCategory(this.label);
  final String label;
}

class PresetCharacter {
  const PresetCharacter({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.category,
    this.tagline = '',
    this.assetPath,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
  final PresetCategory category;
  final String tagline;
  final String? assetPath;

  static const List<PresetCharacter> all = [
    // 👔 Work & Boss
    PresetCharacter(
      id: 'angry_boss',
      name: 'Angry Boss',
      emoji: '👔',
      color: Color(0xFF5C6BC0),
      category: PresetCategory.work,
      tagline: 'Demands weekend overtime',
      assetPath: 'assets/presets/angry_boss.png',
    ),
    PresetCharacter(
      id: 'micromanager',
      name: 'Micromanager',
      emoji: '📋',
      color: Color(0xFF3F51B5),
      category: PresetCategory.work,
      tagline: '"Did you get my email about the email?"',
    ),
    PresetCharacter(
      id: 'lazy_coworker',
      name: 'Lazy Coworker',
      emoji: '☕',
      color: Color(0xFF5C6BC0),
      category: PresetCategory.work,
      tagline: 'On coffee break #7 today',
    ),
    PresetCharacter(
      id: 'credit_stealer',
      name: 'Credit Stealer',
      emoji: '😈',
      color: Color(0xFF7E57C2),
      category: PresetCategory.work,
      tagline: 'Presents your idea as theirs',
    ),
    PresetCharacter(
      id: 'corporate_snob',
      name: 'Corporate Snob',
      emoji: '💼',
      color: Color(0xFF303F9F),
      category: PresetCategory.work,
      tagline: '"Let\'s circle back and align synergistically"',
    ),

    // 💔 Ex & Dating
    PresetCharacter(
      id: 'toxic_ex_gf',
      name: 'Toxic Ex-GF',
      emoji: '💅',
      color: Color(0xFFE91E63),
      category: PresetCategory.dating,
      tagline: 'Gaslights and kept your favorite hoodie',
    ),
    PresetCharacter(
      id: 'toxic_ex_bf',
      name: 'Toxic Ex-BF',
      emoji: '🧢',
      color: Color(0xFFD81B60),
      category: PresetCategory.dating,
      tagline: '"She is just a close friend, relax"',
    ),
    PresetCharacter(
      id: 'ghosting_date',
      name: 'Ghosting Date',
      emoji: '👻',
      color: Color(0xFFC2185B),
      category: PresetCategory.dating,
      tagline: 'Disappeared after dinner',
    ),
    PresetCharacter(
      id: 'ex_friend',
      name: 'Fake Bestie',
      emoji: '💔',
      color: Color(0xFFEC407A),
      category: PresetCategory.dating,
      tagline: 'Spills your secrets behind your back',
      assetPath: 'assets/presets/ex_friend.png',
    ),
    PresetCharacter(
      id: 'gold_digger',
      name: 'Gold Digger',
      emoji: '💍',
      color: Color(0xFFFF4081),
      category: PresetCategory.dating,
      tagline: '"Oops, I forgot my wallet again!"',
    ),

    // 🏠 Neighbors & Landlords
    PresetCharacter(
      id: 'annoying_neighbor',
      name: 'Noisy Neighbor',
      emoji: '🔊',
      color: Color(0xFF66BB6A),
      category: PresetCategory.neighbor,
      tagline: 'Midnight bass & bowling ball rehearsals',
      assetPath: 'assets/presets/annoying_neighbor.png',
    ),
    PresetCharacter(
      id: 'greedy_landlord',
      name: 'Greedy Landlord',
      emoji: '💰',
      color: Color(0xFF2E7D32),
      category: PresetCategory.neighbor,
      tagline: 'Raises rent 30% without fixing plumbing',
    ),
    PresetCharacter(
      id: 'nosy_neighbor',
      name: 'Nosy Neighbor',
      emoji: '👀',
      color: Color(0xFF43A047),
      category: PresetCategory.neighbor,
      tagline: 'Stares through your window blinds',
    ),
    PresetCharacter(
      id: 'lawnmower_guy',
      name: '7 AM Lawnmower',
      emoji: '🚜',
      color: Color(0xFF689F38),
      category: PresetCategory.neighbor,
      tagline: 'Starts the weed-whacker at dawn on Sunday',
    ),
    PresetCharacter(
      id: 'barking_dog_owner',
      name: 'Barking Dog Owner',
      emoji: '🐕',
      color: Color(0xFF558B2F),
      category: PresetCategory.neighbor,
      tagline: 'Lets puppy bark nonstop for 9 hours',
    ),

    // 🚗 Road & Commute
    PresetCharacter(
      id: 'rude_driver',
      name: 'Road Rage Driver',
      emoji: '🚗',
      color: Color(0xFFFF7043),
      category: PresetCategory.commute,
      tagline: 'Honks 0.01s after light turns green',
      assetPath: 'assets/presets/rude_driver.png',
    ),
    PresetCharacter(
      id: 'tailgater',
      name: 'Aggressive Tailgater',
      emoji: '🚙',
      color: Color(0xFFF4511E),
      category: PresetCategory.commute,
      tagline: 'Drives 2 inches from your bumper',
    ),
    PresetCharacter(
      id: 'no_blinker',
      name: 'No-Blinker Swerver',
      emoji: '⚡',
      color: Color(0xFFE64A19),
      category: PresetCategory.commute,
      tagline: 'Cuts across 4 highway lanes without turning signal',
    ),
    PresetCharacter(
      id: 'slow_lane_hogger',
      name: 'Fast Lane Hogger',
      emoji: '🐢',
      color: Color(0xFFD84315),
      category: PresetCategory.commute,
      tagline: 'Drives 10 under speed limit in passing lane',
    ),
    PresetCharacter(
      id: 'double_parker',
      name: 'Double Parker',
      emoji: '🅿️',
      color: Color(0xFFBF360C),
      category: PresetCategory.commute,
      tagline: 'Blocks your driveway for hours',
    ),

    // 😤 Public & Chaos
    PresetCharacter(
      id: 'karen',
      name: 'The "Karen"',
      emoji: '😤',
      color: Color(0xFFAB47BC),
      category: PresetCategory.public,
      tagline: '"I need to speak to your manager right now!"',
      assetPath: 'assets/presets/karen.png',
    ),
    PresetCharacter(
      id: 'spammer_scammer',
      name: 'Crypto Scammer',
      emoji: '📞',
      color: Color(0xFF8E24AA),
      category: PresetCategory.public,
      tagline: 'Calls about your car\'s extended warranty',
    ),
    PresetCharacter(
      id: 'line_cutter',
      name: 'Line Cutter',
      emoji: '🚶‍♂️',
      color: Color(0xFF6A1B9A),
      category: PresetCategory.public,
      tagline: 'Pretends they didn\'t see the 40-person queue',
    ),
    PresetCharacter(
      id: 'movie_spoiler',
      name: 'Movie Spoiler',
      emoji: '🍿',
      color: Color(0xFF4A148C),
      category: PresetCategory.public,
      tagline: 'Blabs the movie ending while walking into theater',
    ),
    PresetCharacter(
      id: 'grumpy_cat',
      name: 'Grumpy Pet',
      emoji: '🐱',
      color: Color(0xFF78909C),
      category: PresetCategory.public,
      tagline: 'Knocks your water glass off the table intentionally',
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

  static List<PresetCharacter> byCategory(PresetCategory category) {
    if (category == PresetCategory.all) return all;
    return all.where((p) => p.category == category).toList();
  }
}
