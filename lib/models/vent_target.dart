import 'dart:convert';

class VentTarget {
  VentTarget({
    required this.id,
    required this.name,
    required this.createdAt,
    this.presetId,
    this.imagePath,
  });

  final String id;
  final String name;
  final String? presetId;
  final String? imagePath;
  final DateTime createdAt;

  bool get isPreset => presetId != null;
  bool get hasPhoto => imagePath != null && imagePath!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'presetId': presetId,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VentTarget.fromJson(Map<String, dynamic> json) => VentTarget(
        id: json['id'] as String,
        name: json['name'] as String,
        presetId: json['presetId'] as String?,
        imagePath: json['imagePath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static String encodeList(List<VentTarget> targets) =>
      jsonEncode(targets.map((t) => t.toJson()).toList());

  static List<VentTarget> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => VentTarget.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
