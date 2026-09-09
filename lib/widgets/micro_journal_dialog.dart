import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tactile_paper_shredder.dart';

/// Result of the optional post-calm check-in.
typedef MicroJournalResult = ({String text, String? mood});

const kMoodOptions = <({String id, String label})>[
  (id: 'lighter', label: 'Lighter'),
  (id: 'calm', label: 'Calm'),
  (id: 'tired', label: 'Tired'),
  (id: 'tense', label: 'Still tense'),
  (id: 'mixed', label: 'Mixed'),
];

/// Optional one-line reflection after calm breathing.
Future<MicroJournalResult?> showMicroJournalDialog(BuildContext context) {
  return showDialog<MicroJournalResult>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _MicroJournalDialog(),
  );
}

class _MicroJournalDialog extends StatefulWidget {
  const _MicroJournalDialog();

  @override
  State<_MicroJournalDialog> createState() => _MicroJournalDialogState();
}

class _MicroJournalDialogState extends State<_MicroJournalDialog> {
  final _controller = TextEditingController();
  String? _mood;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Quick check-in',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you feel now?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in kMoodOptions)
                ChoiceChip(
                  label: Text(m.label),
                  selected: _mood == m.id,
                  onSelected: (_) => setState(() => _mood = m.id),
                  selectedColor: AppTheme.calm.withValues(alpha: 0.35),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _mood == m.id ? AppTheme.calm : AppTheme.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Optional note (one phrase)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Journal note',
            child: TextField(
              controller: _controller,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Lighter, tired, relieved…',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _save(context),
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.content_cut_rounded, size: 16, color: AppTheme.accent),
          label: const Text(
            'Rage Shredder',
            style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pop(context);
            showDialog<void>(
              context: context,
              builder: (_) => const TactilePaperShredderDialog(),
            );
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        Semantics(
          button: true,
          label: 'Save check-in',
          child: FilledButton(
            onPressed: () => _save(context),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.calm),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  void _save(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty && _mood == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, (text: text, mood: _mood));
  }
}
