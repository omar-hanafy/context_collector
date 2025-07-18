import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../virtual_tree/providers/virtual_tree_provider.dart';
import '../../virtual_tree/ui/virtual_tree_view.dart';
import '../state/file_list_state.dart';

/// Main file list screen (without drop zone - handled globally in editor)
class FileListScreen extends ConsumerStatefulWidget {
  const FileListScreen({super.key});

  @override
  ConsumerState<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends ConsumerState<FileListScreen> {
  @override
  void initState() {
    super.initState();
    // Connect virtual tree to scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(selectionProvider.notifier)
          .initializeVirtualTree(ref.read(virtualTreeProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);

    // Listen for errors
    ref.listen<SelectionState>(selectionProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: selectionNotifier.clearError,
            ),
          ),
        );
      }
    });

    return selectionState.hasFiles
        ? const VirtualTreeView()
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.addOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Drop files or directories here',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Or use the buttons in the app bar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.addOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
  }
}
