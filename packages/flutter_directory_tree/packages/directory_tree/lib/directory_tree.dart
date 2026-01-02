/// The core entry point for the `directory_tree` package.
///
/// This library provides a complete toolkit for building, managing, and
/// interacting with virtual file system trees. It is designed to be
/// framework-agnostic, making it suitable for both Flutter UIs and CLI
/// applications.
///
/// ### Core Concepts
///
/// *   **Builder:** Use [TreeBuilder] to transform raw file entries into a
///     structured, deterministic [TreeData] graph.
/// *   **Models:** [TreeEntry] (input), [TreeNode] (graph node), and [TreeData]
///     (immutable tree state).
/// *   **Operations:** Utilities for flattening the tree for display
///     ([FlattenStrategy]), calculating diffs ([diffVisibleNodes]), and
///     managing selection/expansion.
///
/// ### Usage Example
library;

export 'src/builder/tree_builder.dart';
export 'src/models/tree_data.dart';
export 'src/models/tree_entry.dart';
export 'src/models/tree_node.dart';
export 'src/ops/flatten.dart';
export 'src/ops/list_diff.dart';
export 'src/ops/path_utils.dart';
export 'src/ops/reveal.dart';
export 'src/ops/search_filter.dart';
export 'src/ops/selection_utils.dart';
export 'src/ops/sort_delegate.dart';
export 'src/ops/visible_node.dart';
export 'src/state/expansion_state.dart';
export 'src/state/selection_state.dart';
