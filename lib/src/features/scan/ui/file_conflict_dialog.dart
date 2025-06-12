import 'package:flutter/material.dart';

/// Actions for handling file conflicts
enum FileConflictAction {
  skip,     // Don't add conflicting files
  replace,  // Replace existing files
  copy,     // Add with new names
}

/// Dialog for handling individual file conflicts
class FileConflictDialog extends StatelessWidget {
  const FileConflictDialog({
    super.key,
    required this.conflictingFileNames,
  });

  final List<String> conflictingFileNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('File Conflicts Detected'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${conflictingFileNames.length} file(s) already exist in your collection:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: conflictingFileNames
                    .map((fileName) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $fileName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'What would you like to do?',
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<FileConflictAction>(
          onSelected: (action) => Navigator.of(context).pop(action),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: FileConflictAction.skip,
              child: ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('Skip'),
                subtitle: const Text('Don\'t add files that already exist'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: FileConflictAction.replace,
              child: ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Replace'),
                subtitle: const Text('Update existing files with new versions'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: FileConflictAction.copy,
              child: ListTile(
                leading: const Icon(Icons.copy_all_rounded),
                title: const Text('Add as Copies'),
                subtitle: const Text('Rename new files (e.g., file (copy).js)'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          child: FilledButton.icon(
            onPressed: null, // Handled by PopupMenuButton
            icon: const Icon(Icons.arrow_drop_down),
            label: const Text('Choose Action'),
          ),
        ),
      ],
    );
  }
}

/// Show file conflict dialog
Future<FileConflictAction?> showFileConflictDialog(
  BuildContext context,
  List<String> conflictingFileNames,
) async {
  return showDialog<FileConflictAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => FileConflictDialog(
      conflictingFileNames: conflictingFileNames,
    ),
  );
}
