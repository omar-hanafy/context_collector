// Flutter directory tree widgets & utilities.
//
// This package provides:
//  * Controllers: expansion, selection, filtering, and a top-level
//    [DirectoryTreeController] that coordinates them.
//  * Core widgets: [DirectoryTreeView] with animated diffs.
//  * Prebuilt UI: picker dialog, resizable splitter pane, and toolbar.
//  * Delegates & hooks: icon providers, sort & node builders, context menus.
//  * Services: flattening, reveal helpers, search filters, and path utils.
//
// See exports below for the public surface.

export 'package:directory_tree/directory_tree.dart' hide folderSelection;

// ------------------- Controllers -------------------
export 'src/controller/directory_tree_controller.dart';
export 'src/controller/expansion_controller.dart';
export 'src/controller/selection_controller.dart';
export 'src/controller/tree_diff.dart';
export 'src/delegates/context_menu_delegate.dart';
export 'src/delegates/icon_provider.dart';
// ------------------- Delegates & APIs -------------------
export 'src/delegates/node_renderer.dart';
export 'src/models/commands.dart';
// ------------------- Models & State -------------------
// ------------------- Prebuilt Dialogs/Panes -------------------
export 'src/prebuilt/directory_tree_picker.dart';
// ------------------- Services & Utilities -------------------
export 'src/services/reveal_path.dart';
export 'src/services/selection_utils.dart';
export 'src/theme/defaults.dart';
// ------------------- Theming -------------------
export 'src/theme/directory_tree_theme.dart';
export 'src/widgets/directory_tree_panel.dart';
export 'src/widgets/directory_tree_toolbar.dart';
// ------------------- Core Widgets -------------------
export 'src/widgets/directory_tree_view.dart';
export 'src/widgets/selection_shortcuts.dart';
// ------------------- UI Components & Helpers -------------------
export 'src/widgets/tree_node_tile.dart';
