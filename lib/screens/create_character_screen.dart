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
import '../utils/text_sanitize.dart';
import '../utils/web_blob_store.dart' as blobs;
import '../widgets/premium_chrome.dart';
import '../widgets/responsive_columns.dart';

class CreateCharacterScreen extends StatefulWidget {
  const CreateCharacterScreen({super.key});

  @override
  State<CreateCharacterScreen> createState() => _CreateCharacterScreenState();
}

class _CreateCharacterScreenState extends State<CreateCharacterScreen> {
  final _nameController = TextEditingController();
  String? _selectedPresetId;
  PresetCategory _selectedCategory = PresetCategory.all;
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
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 72,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _selectedPresetId = null;
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

  void _selectPreset(PresetCharacter preset) {
    setState(() {
      _selectedPresetId = preset.id;
      _imagePath = null;
      _imageBytes = null;
      if (_nameController.text.trim().isEmpty ||
          PresetCharacter.all.any((p) => p.name == _nameController.text.trim())) {
        _nameController.text = preset.name;
      }
    });
  }

  Future<void> _save() async {
    final name = sanitizeTargetName(_nameController.text);
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

    final targetId = const Uuid().v4();
    String? savedImagePath;
    try {
      if (_imageBytes != null) {
        if (kIsWeb) {
          await blobs.putPhotoBlob(targetId, _imageBytes!);
          savedImagePath = TargetImage.webBlobRef(targetId);
        } else {
          final docs = await io.appDocumentsPath();
          final imagesDir = '$docs/${TargetImage.relativeDir}';
          await io.ensureDir(imagesDir);
          final fileName = '$targetId.jpg';
          final abs = '$imagesDir/$fileName';
          await io.writeBytes(abs, _imageBytes!);
          savedImagePath = '${TargetImage.relativeDir}/$fileName';
        }
      } else if (_imagePath != null && !kIsWeb && _imagePath != 'web-picked') {
        final docs = await io.appDocumentsPath();
        final imagesDir = '$docs/${TargetImage.relativeDir}';
        await io.ensureDir(imagesDir);
        final fileName = '$targetId.jpg';
        final abs = '$imagesDir/$fileName';
        await io.copyFile(_imagePath!, abs);
        savedImagePath = '${TargetImage.relativeDir}/$fileName';
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
      id: targetId,
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
    final filteredPresets = PresetCharacter.byCategory(_selectedCategory);
    final gridWidth = MediaQuery.sizeOf(context).width - 48;
    final presetCols = responsivePresetColumns(
      gridWidth,
      filteredPresets.length,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Target'),
      ),
      body: PremiumBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name / Label',
                        hintText: 'e.g. Boss, Toxic Ex, Loud Neighbor',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Pick a Preset Character',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 19,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${filteredPresets.length} archetypes',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: PresetCategory.values.map((cat) {
                          final selected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat.label),
                              selected: selected,
                              selectedColor: AppTheme.gold.withValues(alpha: 0.25),
                              backgroundColor: AppTheme.card,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? AppTheme.gold : AppTheme.textSecondary,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppTheme.gold
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: presetCols,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filteredPresets.length,
                      itemBuilder: (context, index) {
                        final preset = filteredPresets[index];
                        final selected = _selectedPresetId == preset.id;
                        return InkWell(
                          onTap: () => _selectPreset(preset),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: selected
                                  ? preset.color.withValues(alpha: 0.35)
                                  : AppTheme.card.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.gold
                                    : Colors.white.withValues(alpha: 0.08),
                                width: selected ? 2.0 : 1.0,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.gold.withValues(alpha: 0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (preset.assetPath != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(
                                          preset.assetPath!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) => Text(
                                            preset.emoji,
                                            style: const TextStyle(fontSize: 34),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: preset.color.withValues(alpha: 0.2),
                                        ),
                                        child: Center(
                                          child: Text(
                                            preset.emoji,
                                            style: const TextStyle(fontSize: 26),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        preset.name,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: selected
                                              ? AppTheme.gold
                                              : AppTheme.textPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (selected)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.gold,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Or Custom Photo',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 19,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Private & playful — only use photos you have permission '
                      'to use. Cartoon venting, not real-world harm.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.goldSoft,
                            height: 1.35,
                          ),
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
        ),
      ),
    );
  }
}
