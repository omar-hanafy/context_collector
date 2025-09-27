// Directory tree utilities.
//
// Exposes the core data models and `TreeBuilder` for constructing a
// deterministic virtual tree that can be consumed by Flutter or CLI UIs.

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
