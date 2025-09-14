import 'package:context_collector/src/features/scan/state/file_list_state.dart';
import 'package:context_collector/src/features/virtual_tree/services/tree_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 
import '../state/tree_state.dart';
// Editing dialog removed; new files open directly in Monaco.
import 'tree_node_widget.dart';

/// Main virtual tree view widget
class VirtualTreeView extends ConsumerWidget {
  const VirtualTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(treeStateProvider);
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
              'Drop files to begin or use the toolbar to create a virtual file.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.addOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Tree content only (no header/app bar)
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TreeNodeWidget(
        node: rootNode, // Start rendering from the 'tree' node
        depth: 0,
        nodes: treeState.nodes,
      ),
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
        // Create empty file and open for editing in Monaco (Editor route will appear)
        ref.read(selectionProvider.notifier).createVirtualFile(name, '');
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
