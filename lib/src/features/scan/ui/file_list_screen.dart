import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../virtual_tree/widgets/collector_tree_view.dart';
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
    // Tree wiring now happens in main() before any drops arrive.
  }

  @override
  Widget build(BuildContext context) {
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

    // The FileListScreen now always shows the CollectorTreeView.
    // The parent widget is responsible for switching between the HomeScreen and this screen.
    // The CollectorTreeView itself handles the display of an empty state.
    return const CollectorTreeView();
  }
}
