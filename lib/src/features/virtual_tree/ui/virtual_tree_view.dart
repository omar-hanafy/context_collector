import 'package:context_collector/src/features/scan/state/file_list_state.dart';
import 'package:context_collector/src/features/virtual_tree/services/tree_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tree_node.dart';
import '../state/tree_state.dart';
import 'tree_node_widget.dart';

/// Main virtual tree view widget
class VirtualTreeView extends ConsumerWidget {
  const VirtualTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(treeStateProvider);
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final rootNode = treeState.nodes[treeState.rootId];

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
              'No files in tree',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.addOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drop files or folders to get started',
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
                Icon(
                  Icons.account_tree_rounded,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.addOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'File Tree',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Tree actions
                IconButton(
                  icon: const Icon(Icons.unfold_more_rounded, size: 20),
                  onPressed: () => _expandAll(ref),
                  tooltip: 'Expand All',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.unfold_less_rounded, size: 20),
                  onPressed: () => _collapseAll(ref),
                  tooltip: 'Collapse All',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),

        // Tree content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rootNode.childIds
                  .map((childId) => treeState.nodes[childId])
                  .whereType<TreeNode>()
                  .map(
                    (child) => TreeNodeWidget(
                      node: child,
                      depth: 0,
                      nodes: treeState.nodes,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _expandAll(WidgetRef ref) {
    final notifier = ref.read(treeStateProvider.notifier);
    final nodes = ref.read(treeStateProvider).nodes;

    // Expand all folders
    for (final node in nodes.values) {
      if (node.type == NodeType.folder && !notifier.isExpanded(node.id)) {
        notifier.toggleFolderExpansion(node.id);
      }
    }
  }

  void _collapseAll(WidgetRef ref) {
    final notifier = ref.read(treeStateProvider.notifier);
    final nodes = ref.read(treeStateProvider).nodes;

    // Collapse all folders except root children
    for (final node in nodes.values) {
      if (node.type == NodeType.folder && node.parentId != TreeBuilder.rootId) {
        final isExpanded = notifier.isExpanded(node.id);
        if (isExpanded) {
          notifier.toggleFolderExpansion(node.id);
        }
      }
    }
  }
}
