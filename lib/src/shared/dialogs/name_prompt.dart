import 'package:flutter/material.dart';

/// Shared name prompt dialog used by Home and Editor.
Future<String?> promptForNewFileName(
  BuildContext context, {
  String initialName = 'pasted.txt',
  Set<String> existingNames = const <String>{},
}) async {
  return promptForName(
    context,
    title: 'Name for new file',
    initialName: initialName,
    hintText: 'e.g. notes.md',
    confirmText: 'Create',
    existingNames: existingNames,
  );
}

Future<String?> promptForName(
  BuildContext context, {
  required String title,
  String initialName = '',
  String? labelText,
  String? hintText,
  String confirmText = 'OK',
  Set<String> existingNames = const <String>{},
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NamePromptDialog(
      title: title,
      initialName: initialName,
      labelText: labelText,
      hintText: hintText,
      confirmText: confirmText,
      existingNames: existingNames,
    ),
  );
}

class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({
    required this.title,
    required this.initialName,
    required this.labelText,
    required this.hintText,
    required this.confirmText,
    required this.existingNames,
  });

  final String title;
  final String initialName;
  final String? labelText;
  final String? hintText;
  final String confirmText;
  final Set<String> existingNames;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Name cannot be empty';
    if (widget.existingNames.contains(name)) {
      return 'A file or folder with this name already exists';
    }
    if (RegExp(r'[\\/:*?"<>|]').hasMatch(name)) {
      return 'Invalid characters in name';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            isDense: widget.labelText != null,
          ),
          validator: _validateName,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
