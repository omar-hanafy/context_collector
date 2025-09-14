import 'package:flutter/material.dart';

/// Shared name prompt dialog used by Home and Editor.
Future<String?> promptForNewFileName(
  BuildContext context, {
  String initialName = 'pasted.txt',
}) async {
  final controller = TextEditingController(text: initialName);
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Name for new file'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. notes.md',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return 'Name cannot be empty';
            if (RegExp(r'[\\/:*?"<>|]').hasMatch(s)) {
              return 'Invalid characters in name';
            }
            return null;
          },
          onFieldSubmitted: (_) {
            if (formKey.currentState!.validate()) {
              Navigator.of(ctx).pop(controller.text.trim());
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(ctx).pop(controller.text.trim());
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
