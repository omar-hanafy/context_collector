// lib/src/state/expansion_state.dart

/// Mutable set of expanded node ids without any framework dependencies.
class ExpansionSet {
  ExpansionSet({Set<String>? initiallyExpanded})
    : _expanded = {...?initiallyExpanded};

  final Set<String> _expanded;

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

  Set<String> get expandedIds => Set.unmodifiable(_expanded);
}
