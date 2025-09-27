// lib/src/delegates/context_menu_delegate.dart
import 'package:directory_tree/directory_tree.dart' show VisibleNode;
import 'package:flutter/material.dart';

class NodeAction {
  const NodeAction({
    required this.id,
    required this.label,
    this.icon,
    this.onInvoke,
  });

  final String id;
  final String label;
  final Widget? icon;
  final Future<void> Function(VisibleNode node)? onInvoke;
}

/// Abstract menu plumbing. Concrete (e.g. Material) wrappers can present UI.
abstract class ContextMenuDelegate {
  const ContextMenuDelegate();

  /// Provide actions for a node.
  List<NodeAction> actionsFor(VisibleNode node);

  /// Wrap `child` to handle the platform’s “context menu” gesture.
  /// Basic implementations may simply return the child.
  Widget wrapWithMenu(BuildContext context, Widget child, VisibleNode node);
}

/// A practical Material implementation that shows a popup on right‑click.
class MaterialContextMenuDelegate extends ContextMenuDelegate {
  const MaterialContextMenuDelegate(this._provider);
  final List<NodeAction> Function(VisibleNode node) _provider;

  @override
  List<NodeAction> actionsFor(VisibleNode node) => _provider(node);

  @override
  Widget wrapWithMenu(BuildContext context, Widget child, VisibleNode node) {
    Future<void> showMenuAt(Offset position) async {
      final items = actionsFor(node);
      if (items.isEmpty) return;

      final selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx,
          position.dy,
        ),
        items: [
          for (final a in items)
            PopupMenuItem<String>(
              value: a.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (a.icon != null) ...[a.icon!, const SizedBox(width: 8)],
                  Text(a.label),
                ],
              ),
            ),
        ],
      );

      if (selected == null) return;
      NodeAction? action;
      for (final candidate in items) {
        if (candidate.id == selected) {
          action = candidate;
          break;
        }
      }
      if (action?.onInvoke == null) return;
      await action!.onInvoke!(node);
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (details) => showMenuAt(details.globalPosition),
      onLongPressStart: (details) => showMenuAt(details.globalPosition),
      child: child,
    );
  }
}
