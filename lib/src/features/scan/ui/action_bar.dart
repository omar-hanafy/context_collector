import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Concise action bar that hides when no files
class ActionBar extends ConsumerWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);

    // Hide when no files
    if (!selectionState.hasFiles) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.addOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Compact file count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.addOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${selectionState.selectedFilesCount}/${selectionState.totalFilesCount}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Compact select buttons
          SizedBox(
            height: 32,
            child: TextButton(
              onPressed: selectionNotifier.selectAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('All', style: TextStyle(fontSize: 12)),
            ),
          ),
          SizedBox(
            height: 32,
            child: TextButton(
              onPressed: selectionState.hasSelectedFiles
                  ? selectionNotifier.deselectAll
                  : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('None', style: TextStyle(fontSize: 12)),
            ),
          ),

          const Spacer(),

          // Compact actions
          if (selectionState.isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              onPressed: selectionState.hasSelectedFiles
                  ? selectionNotifier.saveToFile
                  : null,
              icon: const Icon(Icons.save, size: 18),
              tooltip: 'Save to File',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: selectionNotifier.clearFiles,
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Clear All',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          ],
        ],
      ),
    );
  }
}
