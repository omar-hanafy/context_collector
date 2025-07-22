import 'package:context_collector/src/features/scan/state/file_list_state.dart';
import 'package:context_collector/src/features/virtual_tree/services/tree_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/data/providers.dart';
import '../state/tree_state.dart';
import 'file_edit_dialog.dart';
import 'tree_node_widget.dart';

/// Main virtual tree view widget
class VirtualTreeView extends ConsumerWidget {
  const VirtualTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(treeStateProvider);
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final rootNode = treeState.nodes[TreeBuilder.treeRootId];

    if (rootNode == null || !treeState.hasNodes) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary.addOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tree is Empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.addOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drop files to begin or use actions above to create a virtual file.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.addOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Determine the state for the master checkbox
    final totalCount = selectionState.totalFilesCount;
    final selectedCount = selectionState.selectedFilesCount;
    bool? isChecked; // null is the indeterminate state
    if (selectedCount > 0 && selectedCount < totalCount) {
      isChecked = null;
    } else if (selectedCount == totalCount && totalCount > 0) {
      isChecked = true;
    } else {
      isChecked = false;
    }

    return Column(
      children: [
        // Tree header/toolbar with master checkbox
        Tooltip(
          message: '$selectedCount / $totalCount files selected',
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                // Master checkbox
                Checkbox(
                  value: isChecked,
                  tristate: true,
                  onChanged: (value) {
                    // When clicked, if it's not already fully checked, select all.
                    // Otherwise, deselect all.
                    if (isChecked ?? false) {
                      selectionNotifier.deselectAll();
                    } else {
                      selectionNotifier.selectAll();
                    }
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  'File Tree',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Tree actions
                _buildHeaderAction(
                  context: context,
                  ref: ref,
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh File Contents',
                  onPressed: selectionNotifier.refreshAllContents,
                ),
                const SizedBox(width: 4),
                _buildHeaderAction(
                  context: context,
                  ref: ref,
                  icon: Icons.note_add_outlined,
                  tooltip: 'New Virtual File',
                  onPressed: () => showCreateVirtualFileFlow(context, ref),
                ),
              ],
            ),
          ),
        ),

        // Tree content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TreeNodeWidget(
              node: rootNode, // Start rendering from the 'tree' node
              depth: 0,
              nodes: treeState.nodes,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAction({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }

  /// A static method to encapsulate the multi-dialog flow for creating a new file.
  /// Can be called from anywhere (e.g., the home screen or the tree view header).
  static void showCreateVirtualFileFlow(BuildContext context, WidgetRef ref) {
    final allNodes = ref.read(treeStateProvider).nodes;
    final rootChildren = allNodes[TreeBuilder.treeRootId]?.childIds ?? [];
    final existingNames =
        rootChildren.map((id) => allNodes[id]?.name).whereType<String>().toSet();

    _showNameDialog(
      context: context,
      title: 'New Virtual File',
      hint: 'Enter file name (e.g., notes.md)',
      existingNames: existingNames,
      onConfirm: (name) async {
        final content = await showFileEditDialog(
          context,
          fileName: name,
          initialContent: '',
        );
        // If the user saved the content, create the file via the notifier.
        if (content != null) {
          ref.read(selectionProvider.notifier).createVirtualFile(name, content);
        }
        
        // *** THE FIX ***
        // 1. Force Flutter's native text input plugin to release the keyboard.
        //    This is the key to solving the "dead keyboard" issue on macOS.
        await SystemChannels.textInput.invokeMethod<void>('TextInput.clearClient');
        
        // 2. Wait a brief moment for the engine to process the channel message.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        
        // 3. Now that the path is clear, tell Monaco to take focus.
        if (context.mounted) {
          ref.read(monacoEditorServiceProvider).bridge.requestFocus();
        }
      },
    );
  }


  static void _showNameDialog({
    required BuildContext context,
    required String title,
    required String hint,
    required Set<String> existingNames,
    required void Function(String) onConfirm,
  }) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name cannot be empty';
              }
              if (existingNames.contains(value.trim())) {
                return 'A file or folder with this name already exists';
              }
              if (RegExp(r'[\\/:*?"<>|]').hasMatch(value.trim())) {
                return 'Name contains invalid characters';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                onConfirm(controller.text.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                onConfirm(controller.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
