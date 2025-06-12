// UI DIALOG FOR DUPLICATE HANDLING
// Create this new file in your scan feature UI directory

import 'package:flutter/material.dart';

enum DuplicateAction {
  mergeSmart,      // Only add new files (was mergeNew)
  replaceAll,      // Replace existing files  
  addAsDuplicate,  // Create duplicate with new folder (was duplicate)
}

class DuplicateHandlingDialog extends StatelessWidget {
  const DuplicateHandlingDialog({
    super.key,
    required this.duplicatePaths,
  });

  final List<String> duplicatePaths;

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
          const Text('Duplicate Directory Detected'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The following directories are already in your collection:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: duplicatePaths
                  .map((path) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $path',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ))
                  .toList(),
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
        PopupMenuButton<DuplicateAction>(
          onSelected: (action) => Navigator.of(context).pop(action),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: DuplicateAction.mergeSmart,
              child: ListTile(
                leading: const Icon(Icons.merge_rounded),
                title: const Text('Merge Smart'),
                subtitle: const Text('Only add files that don\'t already exist'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: DuplicateAction.replaceAll,
              child: ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Replace Entire Directory'),
                subtitle: const Text('Remove all existing files from this directory and add fresh copies'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: DuplicateAction.addAsDuplicate,
              child: ListTile(
                leading: const Icon(Icons.copy_all_rounded),
                title: const Text('Add as Duplicate'),
                subtitle: const Text('Create new folder with suffix (e.g., "project (2)")'),
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

/// Show duplicate handling dialog
Future<DuplicateAction?> showDuplicateHandlingDialog(
  BuildContext context,
  List<String> duplicatePaths,
) async {
  return showDialog<DuplicateAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DuplicateHandlingDialog(
      duplicatePaths: duplicatePaths,
    ),
  );
}
