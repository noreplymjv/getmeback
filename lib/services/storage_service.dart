import 'package:shared_preferences/shared_preferences.dart';

import '../models/vent_target.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _targetsKey = 'vent_targets';

  Future<List<VentTarget>> loadTargets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_targetsKey);
    if (raw == null || raw.isEmpty) return [];
    return VentTarget.decodeList(raw);
  }

  Future<void> saveTarget(VentTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    final targets = await loadTargets();
    targets.removeWhere((t) => t.id == target.id);
    targets.insert(0, target);
    final trimmed = targets.take(10).toList();
    await prefs.setString(_targetsKey, VentTarget.encodeList(trimmed));
  }

  Future<void> deleteTarget(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final targets = await loadTargets();
    targets.removeWhere((t) => t.id == id);
    await prefs.setString(_targetsKey, VentTarget.encodeList(targets));
  }
}
