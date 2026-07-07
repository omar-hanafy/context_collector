import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_directory_tree/flutter_directory_tree.dart' as tree;
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/dialogs/name_prompt.dart';
import '../../scan/state/file_list_state.dart';
import '../directory_tree_adapter.dart';
import '../providers/virtual_tree_provider.dart';
import 'collector_node_row.dart';
import 'special_file_row.dart';

/// Main tree view composited from the shared DirectoryTreeAdapter.
class CollectorTreeView extends ConsumerWidget {
  const CollectorTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adapter = ref.watch(directoryTreeAdapterProvider);
    final selection = ref.watch(selectionProvider);
    final notifier = ref.read(selectionProvider.notifier);
    final controller = adapter.controller;

    final data = adapter.data;
    final treeNode = data.nodes[tree.TreeBuilder.treeRootId];
    final rootChildren =
        data.nodes[tree.TreeBuilder.rootId]?.childIds ?? const <String>[];
    final hasTreeChildren = treeNode?.childIds.isNotEmpty ?? false;
    final hasRootExtras = rootChildren.any(
      (id) => id != tree.TreeBuilder.treeRootId,
    );
    final hasNodes =
        hasTreeChildren ||
        hasRootExtras ||
        adapter.headerNode != null ||
        adapter.footerNode != null;

    if (!hasNodes) {
      return _EmptyTreePlaceholder(colorScheme: Theme.of(context).colorScheme);
    }

    final headerFile = adapter.headerEntryId == null
        ? null
        : selection.fileMap[adapter.headerEntryId!];

    final footerFile = adapter.footerEntryId == null
        ? null
        : selection.fileMap[adapter.footerEntryId!];

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (adapter.headerNode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SpecialFileRow(
                adapter: adapter,
                node: adapter.headerNode,
                file: headerFile,
                activeFileId: selection.activeFileId,
                onFileActivated: (fileId) {
                  notifier
                    ..setActiveFile(fileId)
                    ..exitCombinedPreview();
                },
              ),
            ),
          Expanded(
            child: tree.DirectoryTreeTheme(
              data: tree.DirectoryTreeThemeData(
                rowHeight: adapter.rowHeight,
                indent: 16,
                indentGuides: false,
                roundedCorners: true,
              ),
              child: tree.SelectionShortcuts(
                controller: controller,
                child: tree.DirectoryTreeView(
                  controller: controller,
                  showScrollbar: true,
                  preserveScrollOnChanges: true,
                  expanderGap: 0,
                  expanderBuilder: (ctx, node, isExpanded, onPressed) =>
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          icon: Icon(
                            isExpanded
                                ? Icons.expand_more
                                : Icons.chevron_right,
                            size: 18,
                          ),
                          onPressed: onPressed,
                          padding: EdgeInsets.zero,
                          splashRadius: 12,
                        ),
                      ),
                  contextMenuDelegate: _buildContextMenuDelegate(
                    context,
                    ref,
                    adapter,
                  ),
                  nodeBuilder: (ctx, node, state) {
                    final file = node.entryId == null
                        ? null
                        : selection.fileMap[node.entryId!];
                    final isActive =
                        node.entryId != null &&
                        node.entryId == selection.activeFileId;
                    return CollectorNodeRow(
                      controller: controller,
                      node: node,
                      visualState: state,
                      file: file,
                      isActive: isActive,
                      onFileActivated: (fileId) {
                        notifier
                          ..setActiveFile(fileId)
                          ..exitCombinedPreview();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          if (adapter.footerNode != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SpecialFileRow(
                adapter: adapter,
                node: adapter.footerNode,
                file: footerFile,
                activeFileId: selection.activeFileId,
                onFileActivated: (fileId) {
                  notifier
                    ..setActiveFile(fileId)
                    ..exitCombinedPreview();
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Flow for creating a new virtual file via dialog, matching the legacy UI.
  static void showCreateVirtualFileFlow(BuildContext context, WidgetRef ref) {
    final selection = ref.read(selectionProvider);
    final existingNames = selection.fileMap.values.map((f) => f.name).toSet();
    final notifier = ref.read(selectionProvider.notifier);

    unawaited(
      _promptAndCreateVirtualFile(
        context: context,
        existingNames: existingNames,
        notifier: notifier,
      ),
    );
  }

  static Future<void> _promptAndCreateVirtualFile({
    required BuildContext context,
    required Set<String> existingNames,
    required FileListNotifier notifier,
  }) async {
    final name = await promptForName(
      context,
      title: 'New Virtual File',
      hintText: 'Enter file name (e.g., notes.md)',
      confirmText: 'Create',
      existingNames: existingNames,
    );
    if (!context.mounted || name == null || name.trim().isEmpty) return;
    notifier.createVirtualFile(name.trim(), '');
  }

  tree.ContextMenuDelegate _buildContextMenuDelegate(
    BuildContext context,
    WidgetRef ref,
    DirectoryTreeAdapter adapter,
  ) {
    final notifier = ref.read(selectionProvider.notifier);
    final messenger = ScaffoldMessenger.maybeOf(context);

    return tree.MaterialContextMenuDelegate(
      (tree.VisibleNode node) {
        final items = <tree.NodeAction>[];

        if (node.type == tree.NodeType.folder) {
          items.add(
            tree.NodeAction(
              id: 'select_all',
              label: 'Select All Files',
              icon: const Icon(Icons.select_all, size: 18),
              onInvoke: (n) async {
                adapter.controller.selectSubtree(n.id);
              },
            ),
          );
        }

        if (node.type == tree.NodeType.file) {
          items.add(
            tree.NodeAction(
              id: 'copy_path',
              label: 'Copy Path',
              icon: const Icon(Icons.content_copy, size: 18),
              onInvoke: (n) async {
                final path = n.sourcePath ?? n.virtualPath;
                await Clipboard.setData(ClipboardData(text: path));
                messenger?.showSnackBar(
                  SnackBar(content: Text('Copied: $path')),
                );
              },
            ),
          );
        }

        items.add(
          tree.NodeAction(
            id: 'remove',
            label: 'Remove',
            icon: const Icon(Icons.delete_outline, size: 18),
            onInvoke: (n) async {
              notifier.removeNodes({n.id});
            },
          ),
        );

        return items;
      },
    );
  }
}

class _EmptyTreePlaceholder extends StatelessWidget {
  const _EmptyTreePlaceholder({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_rounded,
            size: 64,
            color: colorScheme.primary.setOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Tree is Empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drop files to begin or use the toolbar to create a virtual file.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
