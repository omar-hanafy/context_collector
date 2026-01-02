// lib/src/state/expansion_state.dart

/// Manages the set of currently expanded folder IDs.
///
/// This class is a pure Dart implementation, free of Flutter dependencies,
/// allowing it to be used in ViewModels or BLoCs that are testable in
/// isolation.
///
/// ### Key Features
/// *   **Toggle:** [toggle] expansion state of a node.
/// *   **Bulk Operations:** [expandAll] and [collapseAll].
/// *   **Query:** Check [isExpanded] status efficiently.
class ExpansionSet {
  /// Creates a new [ExpansionSet], optionally with initial IDs.
  ExpansionSet({Set<String>? initiallyExpanded})
    : _expanded = {...?initiallyExpanded};

  final Set<String> _expanded;

  /// Returns true if [id] is currently expanded.
  bool isExpanded(String id) => _expanded.contains(id);

  /// Adds or removes [id] depending on [expanded]. Returns true if changed.
  bool setExpanded(String id, bool expanded) {
    return expanded ? _expanded.add(id) : _expanded.remove(id);
  }

  /// Toggles the expanded state of [id]. Returns true if changed.
  bool toggle(String id) => setExpanded(id, !isExpanded(id));

  /// Expands every id in [ids]. Returns true if any id was newly expanded.
  bool expandAll(Iterable<String> ids) {
    var changed = false;
    for (final id in ids) {
      if (_expanded.add(id)) {
        changed = true;
      }
    }
    return changed;
  }

  /// Collapses all ids. Returns true if any id was previously expanded.
  bool collapseAll() {
    if (_expanded.isEmpty) return false;
    _expanded.clear();
    return true;
  }

  /// Keeps only ids that satisfy [test]. Returns true if the set changed.
  bool retainWhere(bool Function(String id) test) {
    final before = _expanded.length;
    _expanded.removeWhere((element) => !test(element));
    return before != _expanded.length;
  }

  /// Returns a read-only view of the expanded IDs.
  Set<String> get expandedIds => Set.unmodifiable(_expanded);
}
