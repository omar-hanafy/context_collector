import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/file_list_state.dart';

/// Simple dialog for pasting file and directory paths
class PastePathsDialog extends ConsumerWidget {
  const PastePathsDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PastePathsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    void submit() {
      final text = controller.text.trim();
      if (text.isEmpty) return;

      // Close dialog
      Navigator.of(context).pop();

      // Process the pasted paths
      ref.read(selectionProvider.notifier).processPastedPaths(text, context);
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.content_paste_go,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paste Paths',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'Paste file or directory paths (one per line)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.addOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Text input area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText:
                        'Examples:\n'
                        '/Users/john/Documents/project\n'
                        'C:\\Projects\\MyApp\\README.md\n'
                        '/path/to/file.txt',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface.addOpacity(0.3),
                    ),
                  ),
                  onSubmitted: (_) => submit(),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: submit,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Paths'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
