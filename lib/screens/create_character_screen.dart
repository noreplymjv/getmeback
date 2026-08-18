import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/preset_character.dart';
import '../models/vent_target.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/io_io.dart' if (dart.library.html) '../utils/io_stub.dart' as io;
import '../utils/target_image.dart';
import '../widgets/premium_chrome.dart';

class CreateCharacterScreen extends StatefulWidget {
  const CreateCharacterScreen({super.key});

  @override
  State<CreateCharacterScreen> createState() => _CreateCharacterScreenState();
}

class _CreateCharacterScreenState extends State<CreateCharacterScreen> {
  final _nameController = TextEditingController();
  String? _selectedPresetId;
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _saving = false;
  String? _pickError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _pickError = null);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _selectedPresetId = null;
        // On web, dart:io paths are useless — keep a display marker.
        _imagePath = kIsWeb ? 'web-picked' : file.path;
      });
    } catch (e) {
      setState(() {
        _pickError = kIsWeb
            ? 'Could not open photo picker in this browser. Try Chrome, or use a preset.'
            : 'Could not pick photo: $e';
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name or label')),
      );
      return;
    }
    if (_selectedPresetId == null && _imageBytes == null && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a preset or upload a photo')),
      );
      return;
    }

    setState(() => _saving = true);

    String? savedImagePath;
    try {
      if (_imageBytes != null) {
        if (kIsWeb) {
          // Persist as data URI in SharedPreferences (local-only).
          savedImagePath = TargetImage.encodeJpegBytes(_imageBytes!);
        } else {
          final docs = await io.appDocumentsPath();
          final imagesDir = '$docs/target_images';
          await io.ensureDir(imagesDir);
          final id = const Uuid().v4();
          savedImagePath = '$imagesDir/$id.jpg';
          await io.writeBytes(savedImagePath, _imageBytes!);
        }
      } else if (_imagePath != null && !kIsWeb && _imagePath != 'web-picked') {
        final docs = await io.appDocumentsPath();
        final imagesDir = '$docs/target_images';
        await io.ensureDir(imagesDir);
        final id = const Uuid().v4();
        savedImagePath = '$imagesDir/$id.jpg';
        await io.copyFile(_imagePath!, savedImagePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo: $e')),
        );
      }
      return;
    }

    final target = VentTarget(
      id: const Uuid().v4(),
      name: name,
      presetId: _selectedPresetId,
      imagePath: savedImagePath,
      createdAt: DateTime.now(),
    );

    await StorageService.instance.saveTarget(target);

    if (mounted) {
      context.go('/vent-menu/${target.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Target'),
      ),
      body: PremiumBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name / Label',
                hintText: 'e.g. That rude coworker',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
            Text(
              'Pick a Preset',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in PresetCharacter.all)
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedPresetId = preset.id;
                      _imagePath = null;
                      _imageBytes = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 72,
                      height: 88,
                      decoration: BoxDecoration(
                        color: preset.color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedPresetId == preset.id
                              ? AppTheme.gold
                              : Colors.white.withValues(alpha: 0.08),
                          width: _selectedPresetId == preset.id ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: preset.assetPath != null
                                    ? Image.asset(
                                        preset.assetPath!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            preset.emoji,
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          preset.emoji,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              preset.name,
                              style: const TextStyle(fontSize: 9, height: 1.1),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Or Upload Photo',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Photos stay in this browser only (not uploaded to a server).'
                  : 'Photos stay on your device only.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(kIsWeb ? 'Choose Photo' : 'Gallery'),
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ],
            ),
            if (_pickError != null) ...[
              const SizedBox(height: 12),
              Text(
                _pickError!,
                style: TextStyle(color: Colors.red.shade300, fontSize: 13),
              ),
            ],
            if (_imageBytes != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _imageBytes!,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 32),
            ShineButton(
              label: _saving ? 'Saving...' : 'Start Venting',
              icon: Icons.auto_awesome,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
