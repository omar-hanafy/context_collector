// lib/src/widgets/directory_tree_panel.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_directory_tree/src/controller/directory_tree_controller.dart';
import 'package:flutter_directory_tree/src/delegates/node_renderer.dart';
import 'package:flutter_directory_tree/src/theme/defaults.dart';
import 'package:flutter_directory_tree/src/theme/directory_tree_theme.dart';
import 'package:flutter_directory_tree/src/widgets/directory_tree_toolbar.dart';
import 'package:flutter_directory_tree/src/widgets/directory_tree_view.dart';
import 'package:flutter_directory_tree/src/widgets/selection_shortcuts.dart';

class DirectoryTreePanel extends StatelessWidget {
  const DirectoryTreePanel({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    this.toolbar,
    this.shortcutsAutofocus = true,
  });

  final DirectoryTreeController controller;
  final NodeBuilder nodeBuilder;
  final Widget? toolbar;

  /// Whether the embedded SelectionShortcuts should request focus.
  final bool shortcutsAutofocus;

  @override
  Widget build(BuildContext context) {
    final currentTheme = DirectoryTreeTheme.of(context);
    final themed = DirectoryTreeDefaults.themed(context, base: currentTheme);

    return DirectoryTreeTheme(
      data: themed,
      child: Column(
        children: [
          toolbar ?? DirectoryTreeToolbar(controller: controller),
          Expanded(
            child: SelectionShortcuts(
              controller: controller,
              autofocus: shortcutsAutofocus,
              child: DirectoryTreeView(
                controller: controller,
                nodeBuilder: nodeBuilder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
