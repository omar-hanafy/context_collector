// lib/src/models/commands.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_directory_tree/src/controller/directory_tree_controller.dart';

/// Basic command intents for tree interactions.
/// You can bind these with Actions/Shortcuts if you want declarative wiring.
class ExpandNodeIntent extends Intent {
  const ExpandNodeIntent(this.nodeId, {this.recursive = false});
  final String nodeId;
  final bool recursive;
}

class CollapseNodeIntent extends Intent {
  const CollapseNodeIntent(this.nodeId, {this.recursive = false});
  final String nodeId;
  final bool recursive;
}

class ToggleNodeIntent extends Intent {
  const ToggleNodeIntent(this.nodeId);
  final String nodeId;
}

class RevealNodeIntent extends Intent {
  const RevealNodeIntent({this.nodeId, this.virtualPath, this.select = false});
  final String? nodeId;
  final String? virtualPath;
  final bool select;
}

class SelectOnlyIntent extends Intent {
  const SelectOnlyIntent(this.nodeId);
  final String nodeId;
}

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

/// A minimal action set that operates on a DirectoryTreeController.
class DirectoryTreeAction<T extends Intent> extends Action<T> {
  DirectoryTreeAction(this.controller);
  final DirectoryTreeController controller;

  @override
  Object? invoke(T intent) {
    switch (intent) {
      case ExpandNodeIntent(:final nodeId, :final recursive):
        controller.expand(nodeId, recursive: recursive);
        return null;
      case CollapseNodeIntent(:final nodeId, :final recursive):
        controller.collapse(nodeId, recursive: recursive);
        return null;
      case ToggleNodeIntent(:final nodeId):
        controller.toggle(nodeId);
        return null;
      case RevealNodeIntent(:final nodeId, :final virtualPath, :final select):
        unawaited(controller.reveal(
            nodeId: nodeId, virtualPath: virtualPath, select: select));
        return null;
      case SelectOnlyIntent(:final nodeId):
        controller.selectOnly(nodeId);
        return null;
      case ClearSelectionIntent():
        controller.clearSelection();
        return null;
      default:
        return null;
    }
  }
}
