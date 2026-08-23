import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vent_target.dart';
import '../utils/target_image.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _targetsKey = 'vent_targets';
  static const _hapticsKey = 'haptics_enabled';
  static const _zenStreakKey = 'zen_streak_count';
  static const _zenLastCalmKey = 'zen_streak_last_calm';
  static const _journalKey = 'micro_journal_entries';
  static const _secureMigratedKey = 'vent_targets_secure_migrated';

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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

  String _todayKey([DateTime? when]) {
    final d = when ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayKey() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return _todayKey(y);
  }

  /// Current zen streak (0 if broken).
  Future<int> getZenStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_zenLastCalmKey);
    if (last == null) return 0;
    if (last != _todayKey() && last != _yesterdayKey()) return 0;
    return prefs.getInt(_zenStreakKey) ?? 0;
  }

  /// Record a calm-session completion; returns updated streak.
  Future<int> recordCalmCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final last = prefs.getString(_zenLastCalmKey);
    var streak = prefs.getInt(_zenStreakKey) ?? 0;

    if (last == today) {
      return streak;
    }

    if (last == _yesterdayKey()) {
      streak += 1;
    } else {
      streak = 1;
    }

    await prefs.setInt(_zenStreakKey, streak);
    await prefs.setString(_zenLastCalmKey, today);
    return streak;
  }

  Future<void> saveJournalEntry(String text) async {
    if (text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_journalKey) ?? [];
    existing.insert(0, '${DateTime.now().toIso8601String()}|$text');
    if (existing.length > 30) existing.removeRange(30, existing.length);
    await prefs.setStringList(_journalKey, existing);
  }

  Future<List<VentTarget>> loadTargets() async {
    if (kIsWeb) return _loadTargetsFromPrefs();

    try {
      await _migrateTargetsToSecureIfNeeded();
      final raw = await _secure.read(key: _targetsKey);
      if (raw == null || raw.isEmpty) return [];
      return VentTarget.decodeList(raw);
    } catch (_) {
      return _loadTargetsFromPrefs();
    }
  }

  Future<void> saveTarget(VentTarget target) async {
    final targets = await loadTargets();
    targets.removeWhere((t) => t.id == target.id);
    targets.insert(0, target);
    final overflow = targets.length > 10 ? targets.sublist(10) : <VentTarget>[];
    final trimmed = targets.take(10).toList();
    for (final dropped in overflow) {
      await _cleanupPhoto(dropped);
    }
    await _writeTargets(trimmed);
  }

  Future<void> deleteTarget(String id) async {
    final targets = await loadTargets();
    VentTarget? removed;
    for (final t in targets) {
      if (t.id == id) removed = t;
    }
    targets.removeWhere((t) => t.id == id);
    await _writeTargets(targets);
    if (removed != null) await _cleanupPhoto(removed);
  }

  Future<List<VentTarget>> _loadTargetsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_targetsKey);
    if (raw == null || raw.isEmpty) return [];
    return VentTarget.decodeList(raw);
  }

  Future<void> _writeTargets(List<VentTarget> targets) async {
    final encoded = VentTarget.encodeList(targets);
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_targetsKey, encoded);
      return;
    }
    try {
      await _secure.write(key: _targetsKey, value: encoded);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_targetsKey, encoded);
    }
  }

  Future<void> _migrateTargetsToSecureIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_secureMigratedKey) == true) return;

    final legacy = prefs.getString(_targetsKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: _targetsKey, value: legacy);
      await prefs.remove(_targetsKey);
    }
    await prefs.setBool(_secureMigratedKey, true);
  }

  Future<void> _cleanupPhoto(VentTarget target) async {
    await TargetImage.deleteStoredPhoto(target.imagePath);
  }
}
