import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Optional one-line reflection after calm breathing.
Future<String?> showMicroJournalDialog(BuildContext context) {
  return showDialog<String>(
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
            'One word or phrase for how you feel now?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => _save(context),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.calm),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save(BuildContext context) {
    final text = _controller.text.trim();
    Navigator.pop(context, text.isEmpty ? null : text);
  }
}
