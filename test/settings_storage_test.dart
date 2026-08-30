import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadSettings();
  });

  test('haptics and sfx default to enabled', () async {
    expect(StorageService.instance.hapticsEnabled, isTrue);
    expect(StorageService.instance.sfxEnabled, isTrue);
  });

  test('setSfxEnabled persists and reloads', () async {
    await StorageService.instance.setSfxEnabled(false);
    expect(StorageService.instance.sfxEnabled, isFalse);

    await StorageService.instance.loadSettings();
    expect(StorageService.instance.sfxEnabled, isFalse);

    await StorageService.instance.setSfxEnabled(true);
    expect(StorageService.instance.sfxEnabled, isTrue);
  });

  test('setHapticsEnabled persists', () async {
    await StorageService.instance.setHapticsEnabled(false);
    expect(StorageService.instance.hapticsEnabled, isFalse);
    await StorageService.instance.loadSettings();
    expect(StorageService.instance.hapticsEnabled, isFalse);
  });

  test('loadJournalEntries parses iso|text lines', () async {
    await StorageService.instance.saveJournalEntry('felt lighter');
    await StorageService.instance.saveJournalEntry('breathed out');

    final entries = await StorageService.instance.loadJournalEntries();
    expect(entries.length, greaterThanOrEqualTo(2));
    expect(entries.first.text, 'breathed out');
    expect(entries[1].text, 'felt lighter');
    expect(entries.first.at.isBefore(DateTime.now().add(const Duration(minutes: 1))),
        isTrue);
  });

  test('clearAllLocalData wipes journal and streak but keeps toggles', () async {
    await StorageService.instance.setSfxEnabled(false);
    await StorageService.instance.setHapticsEnabled(false);
    await StorageService.instance.saveJournalEntry('temporary note');
    await StorageService.instance.recordCalmCompletion();

    expect(await StorageService.instance.getZenStreak(), greaterThan(0));
    expect(
      (await StorageService.instance.loadJournalEntries()).isNotEmpty,
      isTrue,
    );

    await StorageService.instance.clearAllLocalData();

    expect(await StorageService.instance.loadJournalEntries(), isEmpty);
    expect(await StorageService.instance.getZenStreak(), 0);
    expect(StorageService.instance.sfxEnabled, isFalse);
    expect(StorageService.instance.hapticsEnabled, isFalse);
  });
}
