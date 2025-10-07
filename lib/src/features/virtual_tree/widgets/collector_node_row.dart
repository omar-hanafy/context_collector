import 'package:flutter/material.dart';
import 'package:flutter_directory_tree/flutter_directory_tree.dart'
    as tree
    show
        DirectoryTreeController,
        DirectoryTreeTheme,
        FolderSelection,
        NodeType,
        NodeVisualState,
        VisibleNode,
        folderSelection;

import '../../scan/models/scanned_file.dart';
import '../../scan/ui/file_display_helper.dart';

/// Compact row renderer that mimics the legacy virtual tree styling.
class CollectorNodeRow extends StatefulWidget {
  const CollectorNodeRow({
    super.key,
    required this.controller,
    required this.node,
    required this.visualState,
    required this.file,
    required this.isActive,
    required this.onFileActivated,
  });

  final tree.DirectoryTreeController controller;
  final tree.VisibleNode node;
  final tree.NodeVisualState visualState;
  final ScannedFile? file;
  final bool isActive;
  final ValueChanged<String> onFileActivated;

  @override
  State<CollectorNodeRow> createState() => _CollectorNodeRowState();
}

class _CollectorNodeRowState extends State<CollectorNodeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = tree.DirectoryTreeTheme.of(context);
    final bg = _backgroundColor(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: theme.rowHeight,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: theme.roundedCorners
                ? BorderRadius.circular(4)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              _buildCheckbox(),
              const SizedBox(width: 8),
              _buildIcon(context),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.node.type == tree.NodeType.folder
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _textColor(context),
                  ),
                ),
              ),
              if (widget.file != null)
                _buildStatusIndicator(context, widget.file!),
            ],
          ),
        ),
      ),
    );
  }

  Color? _backgroundColor(BuildContext context) {
    if (widget.isActive) {
      return Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.22);
    }
    if (_hovered) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05);
    }
    return null;
  }

  Color _textColor(BuildContext context) {
    final file = widget.file;
    final base = Theme.of(context).colorScheme.onSurface;
    if (file != null && file.isDirty && !file.isVirtual) {
      const dirtyAccent = Color(0xFFFFB74D);
      return Color.alphaBlend(dirtyAccent.withValues(alpha: 0.7), base);
    }
    return base;
  }

  Widget _buildCheckbox() {
    if (widget.node.type == tree.NodeType.root) {
      return const SizedBox(width: 20, height: 20);
    }

    if (widget.node.type == tree.NodeType.file) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Checkbox(
          value: widget.visualState.isSelected,
          onChanged: (checked) {
            if (checked ?? false) {
              widget.controller.selection.addAll([widget.node.id]);
            } else {
              widget.controller.selection.removeAll([widget.node.id]);
            }
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    final tri = tree.folderSelection(widget.controller, widget.node.id);
    final bool? value = switch (tri) {
      tree.FolderSelection.all => true,
      tree.FolderSelection.none => false,
      tree.FolderSelection.partial => null,
    };

    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: value,
        tristate: true,
        onChanged: (_) {
          if (tri == tree.FolderSelection.all) {
            widget.controller.deselectSubtree(widget.node.id);
          } else {
            widget.controller.selectSubtree(widget.node.id);
          }
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (widget.node.type == tree.NodeType.folder) {
      final expanded = widget.visualState.isExpanded;
      final cs = Theme.of(context).colorScheme;
      return Icon(
        expanded ? Icons.folder_open : Icons.folder,
        size: 20,
        color: cs.secondary,
      );
    }

    if (widget.node.isVirtual) {
      final cs = Theme.of(context).colorScheme;
      return Icon(
        Icons.note_add,
        size: 18,
        color: cs.secondary,
      );
    }

    final file = widget.file;
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
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildStatusIndicator(BuildContext context, ScannedFile file) {
    final indicator = FileDisplayHelper.buildStatusIndicator(context, file);
    if (indicator == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: indicator,
    );
  }

  void _handleTap() {
    if (widget.node.type == tree.NodeType.folder) {
      widget.controller.toggle(widget.node.id);
      return;
    }
    final entryId = widget.node.entryId;
    if (entryId != null) {
      widget.onFileActivated(entryId);
    }
  }
}
