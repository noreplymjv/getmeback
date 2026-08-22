import 'package:shared_preferences/shared_preferences.dart';

import '../models/vent_target.dart';
import '../utils/target_image.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _targetsKey = 'vent_targets';
  static const _hapticsKey = 'haptics_enabled';

  bool _hapticsEnabled = true;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticsEnabled = prefs.getBool(_hapticsKey) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, enabled);
  }

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
    final overflow = targets.length > 10 ? targets.sublist(10) : <VentTarget>[];
    final trimmed = targets.take(10).toList();
    for (final dropped in overflow) {
      await _cleanupPhoto(dropped);
    }
    await prefs.setString(_targetsKey, VentTarget.encodeList(trimmed));
  }

  Future<void> deleteTarget(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final targets = await loadTargets();
    VentTarget? removed;
    for (final t in targets) {
      if (t.id == id) removed = t;
    }
    targets.removeWhere((t) => t.id == id);
    await prefs.setString(_targetsKey, VentTarget.encodeList(targets));
    if (removed != null) await _cleanupPhoto(removed);
  }

  Future<void> _cleanupPhoto(VentTarget target) async {
    await TargetImage.deleteStoredPhoto(target.imagePath);
  }
}
