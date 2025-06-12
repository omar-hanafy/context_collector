import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scan/ui/file_display_helper.dart';
import '../models/tree_node.dart';
import '../state/tree_state.dart';

/// Folder selection state
enum FolderSelectionState { none, partial, all }

/// Widget for displaying a single tree node
class TreeNodeWidget extends ConsumerStatefulWidget {
  const TreeNodeWidget({
    super.key,
    required this.node,
    required this.depth,
    required this.nodes,
  });

  final TreeNode node;
  final int depth;
  final Map<String, TreeNode> nodes;

  @override
  ConsumerState<TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends ConsumerState<TreeNodeWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(treeStateProvider.notifier);
    final treeState = ref.watch(treeStateProvider);
    final scannerFiles = ref.watch(selectionProvider).fileMap;

    final isExpanded = notifier.isExpanded(widget.node.id);
    final isSelected = treeState.selectedNodeIds.contains(widget.node.id);
    final file = widget.node.fileId != null
        ? scannerFiles[widget.node.fileId]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => _handleNodeTap(context, ref),
            onSecondaryTapDown: (details) => _showContextMenu(context, details),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: _getBackgroundColor(context, isSelected),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16.0 * widget.depth + 8),

                  // Expand/collapse icon for folders
                  if (widget.node.type == NodeType.folder)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_more : Icons.chevron_right,
                          size: 18,
                        ),
                        onPressed: () => notifier.toggleFolderExpansion(widget.node.id),
                        padding: EdgeInsets.zero,
                        splashRadius: 12,
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  
                  // Selection checkbox (for both files and folders)
                  if (widget.node.type != NodeType.root)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: widget.node.type == NodeType.file
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (value) => _handleSelectionChange(ref, value ?? false),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            )
                          : _buildFolderCheckbox(ref),
                    ),

                  const SizedBox(width: 4),

                  // Node icon
                  _buildNodeIcon(context, widget.node, file),

                  const SizedBox(width: 8),

                  // Node name
                  Expanded(
                    child: Text(
                      widget.node.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.node.type == NodeType.folder
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _getTextColor(context, isSelected),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Status indicators
                  if (file != null) ...[
                    _buildStatusIndicator(context, file),
                    const SizedBox(width: 8),
                  ],

                  // Hover actions
                  if (_isHovered) ...[
                    if (widget.node.type == NodeType.folder) ...[
                      _buildHoverAction(
                        icon: Icons.create_new_folder_outlined,
                        tooltip: 'New Folder',
                        onPressed: _createNewFolder,
                      ),
                      _buildHoverAction(
                        icon: Icons.note_add_outlined,
                        tooltip: 'New File',
                        onPressed: _createNewFile,
                      ),
                    ],
                    if (widget.node.type == NodeType.file && file != null) ...[
                      _buildHoverAction(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit',
                        onPressed: _editFile,
                      ),
                    ],
                  ],

                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),

        // Children (if folder is expanded)
        if (widget.node.type == NodeType.folder && isExpanded)
          ...widget.node.childIds
              .map((id) => widget.nodes[id])
              .whereType<TreeNode>()
              .map(
                (child) => TreeNodeWidget(
                  node: child,
                  depth: widget.depth + 1,
                  nodes: widget.nodes,
                ),
              ),
      ],
    );
  }

  Color _getBackgroundColor(BuildContext context, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSelected) {
      return colorScheme.primary.addOpacity(0.15);
    } else if (_isHovered) {
      return colorScheme.onSurface.addOpacity(0.05);
    }

    return Colors.transparent;
  }

  Color _getTextColor(BuildContext context, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSelected && widget.node.type == NodeType.file) {
      return colorScheme.primary;
    }

    return colorScheme.onSurface;
  }

  Widget _buildNodeIcon(
    BuildContext context,
    TreeNode node,
    ScannedFile? file,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (node.type == NodeType.folder) {
      final isExpanded = ref
          .read(treeStateProvider.notifier)
          .isExpanded(node.id);
      return Icon(
        isExpanded ? Icons.folder_open : Icons.folder,
        color: Colors.amber.shade700,
        size: 20,
      );
    }

    // File icon based on status
    if (node.isVirtual) {
      return Icon(
        Icons.note_add,
        color: Colors.green.shade600,
        size: 18,
      );
    }

    // Icon based on file extension
    if (file != null) {
      return Icon(
        FileDisplayHelper.getIconForExtension(file.extension),
        size: 18,
        color: FileDisplayHelper.getIconColor(file.extension, context),
      );
    }

    return Icon(
      Icons.insert_drive_file,
      size: 18,
      color: colorScheme.onSurface.addOpacity(0.7),
    );
  }

  

  Widget _buildStatusIndicator(BuildContext context, ScannedFile file) {
    final indicator = FileDisplayHelper.buildStatusIndicator(context, file);
    if (indicator != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: indicator,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHoverAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        splashRadius: 12,
      ),
    );
  }
  
  void _handleNodeTap(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(treeStateProvider.notifier);
    
    if (widget.node.type == NodeType.folder) {
      // For folders, toggle expansion
      notifier.toggleFolderExpansion(widget.node.id);
    } else {
      // For files, toggle selection
      notifier.toggleNode(widget.node.id);
    }
  }
  
  Widget _buildFolderCheckbox(WidgetRef ref) {
    final folderState = _getFolderSelectionState(ref);
    
    return Checkbox(
      value: folderState == FolderSelectionState.all ? true : 
             folderState == FolderSelectionState.none ? false : null,
      tristate: true,
      onChanged: (value) {
        // If partially selected or none selected, select all
        // If all selected, deselect all
        final shouldSelect = folderState != FolderSelectionState.all;
        _handleSelectionChange(ref, shouldSelect);
      },
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
  
  FolderSelectionState _getFolderSelectionState(WidgetRef ref) {
    if (widget.node.type != NodeType.folder) return FolderSelectionState.none;
    
    final treeState = ref.watch(treeStateProvider);
    
    // Check selection state of all files in this folder
    final fileNodes = <String>[];
    _collectFileNodesInFolder(widget.node.id, fileNodes, treeState.nodes);
    
    if (fileNodes.isEmpty) return FolderSelectionState.none;
    
    final selectedCount = fileNodes.where((nodeId) => treeState.selectedNodeIds.contains(nodeId)).length;
    
    if (selectedCount == 0) return FolderSelectionState.none;
    if (selectedCount == fileNodes.length) return FolderSelectionState.all;
    return FolderSelectionState.partial;
  }

  void _collectFileNodesInFolder(String folderId, List<String> fileNodes, Map<String, TreeNode> nodes) {
  final folder = nodes[folderId];
  if (folder == null) return;

  for (final childId in folder.childIds) {
  final child = nodes[childId];
  if (child == null) continue;

  if (child.type == NodeType.file) {
  fileNodes.add(childId);
  } else {
  _collectFileNodesInFolder(childId, fileNodes, nodes);
  }
  }
  }
  
  void _handleSelectionChange(WidgetRef ref, bool selected) {
    final notifier = ref.read(treeStateProvider.notifier);
    
    if (widget.node.type == NodeType.file) {
      notifier.toggleNode(widget.node.id);
    } else if (widget.node.type == NodeType.folder) {
      if (selected) {
        notifier.selectFolder(widget.node.id);
      } else {
        notifier.deselectFolder(widget.node.id);
      }
    }
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (overlay == null) {
      return;
    }

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: _buildContextMenuItems(context),
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value);
      }
    });
  }

  List<PopupMenuEntry<String>> _buildContextMenuItems(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];
    
    PopupMenuItem<String> menuItem(String value, IconData icon, String text) {
      return PopupMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      );
    }

    if (widget.node.type == NodeType.folder) {
      items.addAll([
        menuItem('new_file', Icons.note_add, 'New File'),
        menuItem('new_folder', Icons.create_new_folder, 'New Folder'),
        const PopupMenuDivider(),
        menuItem('select_all', Icons.select_all, 'Select All Files'),
      ]);
    }

    if (widget.node.type == NodeType.file) {
      items.addAll([
        menuItem('edit', Icons.edit, 'Edit'),
        menuItem('copy_path', Icons.content_copy, 'Copy Path'),
      ]);
    }

    // Common actions
    items.addAll([
      const PopupMenuDivider(),
      menuItem('remove', Icons.delete_outline, 'Remove'),
    ]);

    return items;
  }

  void _handleContextMenuAction(String action) {
    final notifier = ref.read(treeStateProvider.notifier);

    switch (action) {
      case 'new_file':
        _createNewFile();
      case 'new_folder':
        _createNewFolder();
      case 'select_all':
        notifier.selectFolder(widget.node.id);
      case 'edit':
        _editFile();
      case 'copy_path':
        _copyPath();
      case 'remove':
        notifier.removeNode(widget.node.id);
    }
  }

  void _createNewFile() {
    _showCreateDialog(
      title: 'New File',
      hint: 'Enter file name',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'File name cannot be empty';
        }
        return null;
      },
      onConfirm: (name) {
        ref
            .read(treeStateProvider.notifier)
            .createNode(
              parentId: widget.node.id,
              name: name,
              isFolder: false,
              content: '', // Empty content for new file
            );
      },
    );
  }

  void _createNewFolder() {
    _showCreateDialog(
      title: 'New Folder',
      hint: 'Enter folder name',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Folder name cannot be empty';
        }
        return null;
      },
      onConfirm: (name) {
        ref
            .read(treeStateProvider.notifier)
            .createNode(
              parentId: widget.node.id,
              name: name,
              isFolder: true,
            );
      },
    );
  }

  void _editFile() {
    // TODO: Show edit dialog
    // This will be implemented when the edit UI is ready
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _copyPath() {
    final path = widget.node.sourcePath ?? widget.node.virtualPath;
    Clipboard.setData(ClipboardData(text: path));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $path')),
    );
  }

  void _showCreateDialog({
    required String title,
    required String hint,
    required String? Function(String?) validator,
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
            validator: validator,
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
