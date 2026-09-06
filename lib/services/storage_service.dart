import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vent_target.dart';
import '../utils/target_image.dart';

/// One micro-journal line after calm.
class JournalEntry {
  const JournalEntry({
    required this.at,
    required this.text,
    this.mood,
  });

  final DateTime at;
  final String text;
  /// Optional mood tag: lighter | calm | tired | tense | mixed
  final String? mood;
}

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _targetsKey = 'vent_targets';
  static const _hapticsKey = 'haptics_enabled';
  static const _sfxKey = 'sfx_enabled';
  static const _reducedFxKey = 'reduced_fx_enabled';
  static const _zenStreakKey = 'zen_streak_count';
  static const _zenLastCalmKey = 'zen_streak_last_calm';
  static const _journalKey = 'micro_journal_entries';
  static const _secureMigratedKey = 'vent_targets_secure_migrated';
  static const _journalSecureMigratedKey = 'micro_journal_secure_migrated';

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _hapticsEnabled = true;
  bool get hapticsEnabled => _hapticsEnabled;

  bool _sfxEnabled = true;
  bool get sfxEnabled => _sfxEnabled;

  bool _reducedFxEnabled = false;
  bool get reducedFxEnabled => _reducedFxEnabled;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticsEnabled = prefs.getBool(_hapticsKey) ?? true;
    _sfxEnabled = prefs.getBool(_sfxKey) ?? true;
    _reducedFxEnabled = prefs.getBool(_reducedFxKey) ?? false;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, enabled);
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, enabled);
  }

  Future<void> setReducedFxEnabled(bool enabled) async {
    _reducedFxEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedFxKey, enabled);
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

  /// Encode: `iso|mood|text` (mood may be empty). Legacy `iso|text` still loads.
  String _encodeJournalLine(JournalEntry e) {
    final mood = e.mood?.trim() ?? '';
    return '${e.at.toIso8601String()}|$mood|${e.text}';
  }

  JournalEntry? _parseJournalLine(String line) {
    final first = line.indexOf('|');
    if (first <= 0) return null;
    final at = DateTime.tryParse(line.substring(0, first));
    if (at == null) return null;
    final rest = line.substring(first + 1);
    final second = rest.indexOf('|');
    if (second < 0) {
      // Legacy: iso|text
      return JournalEntry(at: at, text: rest);
    }
    final moodRaw = rest.substring(0, second).trim();
    final text = rest.substring(second + 1);
    return JournalEntry(
      at: at,
      text: text,
      mood: moodRaw.isEmpty ? null : moodRaw,
    );
  }

  Future<void> saveJournalEntry(String text, {String? mood}) async {
    if (text.trim().isEmpty && (mood == null || mood.trim().isEmpty)) return;
    final body = text.trim().isEmpty ? (mood ?? '') : text.trim();
    final entry = JournalEntry(
      at: DateTime.now(),
      text: body,
      mood: mood?.trim().isEmpty == true ? null : mood?.trim(),
    );
    final existing = await _readJournalRaw();
    existing.insert(0, _encodeJournalLine(entry));
    if (existing.length > 30) existing.removeRange(30, existing.length);
    await _writeJournalRaw(existing);
  }

  /// Recent journal lines.
  Future<List<JournalEntry>> loadJournalEntries() async {
    final raw = await _readJournalRaw();
    final out = <JournalEntry>[];
    for (final line in raw) {
      final parsed = _parseJournalLine(line);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  Future<List<String>> _readJournalRaw() async {
    if (!kIsWeb) {
      try {
        await _migrateJournalToSecureIfNeeded();
        final raw = await _secure.read(key: _journalKey);
        if (raw != null && raw.isNotEmpty) {
          return raw.split('\n').where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        // Fall through to prefs.
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(_journalKey) ?? const []);
  }

  Future<void> _writeJournalRaw(List<String> lines) async {
    final joined = lines.join('\n');
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_journalKey, lines);
      return;
    }
    try {
      await _secure.write(key: _journalKey, value: joined);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_journalKey);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_journalKey, lines);
    }
  }

  Future<void> _migrateJournalToSecureIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_journalSecureMigratedKey) == true) return;

    final legacy = prefs.getStringList(_journalKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: _journalKey, value: legacy.join('\n'));
      await prefs.remove(_journalKey);
    }
    await prefs.setBool(_journalSecureMigratedKey, true);
  }

  /// Wipe targets, journal, and zen streak. Keeps haptics/SFX/reduced-FX toggles.
  Future<void> clearAllLocalData() async {
    final targets = await loadTargets();
    for (final t in List<VentTarget>.from(targets)) {
      await deleteTarget(t.id);
    }
    await _writeTargets([]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_journalKey);
    await prefs.remove(_zenStreakKey);
    await prefs.remove(_zenLastCalmKey);
    if (!kIsWeb) {
      try {
        await _secure.delete(key: _journalKey);
      } catch (_) {}
    }
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
