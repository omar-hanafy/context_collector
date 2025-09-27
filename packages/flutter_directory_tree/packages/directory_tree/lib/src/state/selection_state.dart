// lib/src/state/selection_state.dart

enum SelectionMode { single, multi }

/// Framework-agnostic selection model that mirrors the Flutter controller API.
class SelectionSet {
  SelectionSet({this.mode = SelectionMode.single});

  SelectionMode mode;
  final Set<String> _selected = <String>{};

  bool isSelected(String id) => _selected.contains(id);

  Set<String> get selectedIds => Set.unmodifiable(_selected);

  /// Keeps only [id] in the selection. Returns true if changed.
  bool selectOnly(String id) {
    if (_selected.length == 1 && _selected.contains(id)) {
      return false;
    }
    _selected
      ..clear()
      ..add(id);
    return true;
  }

  /// Toggles [id] depending on [mode]. Returns true if changed.
  bool toggle(String id) {
    if (mode == SelectionMode.single) {
      return selectOnly(id);
    }
    if (_selected.contains(id)) {
      _selected.remove(id);
      return true;
    }
    _selected.add(id);
    return true;
  }

  /// Clears all selections. Returns true if anything was cleared.
  bool clear() {
    if (_selected.isEmpty) return false;
    _selected.clear();
    return true;
  }

  /// Shift-like range selection based on the visible order. Returns true if changed.
  bool selectRange(
    List<String> orderedVisibleIds,
    String anchorId,
    String toId,
  ) {
    if (mode == SelectionMode.single) {
      return selectOnly(toId);
    }
    final anchorIndex = orderedVisibleIds.indexOf(anchorId);
    final targetIndex = orderedVisibleIds.indexOf(toId);
    if (anchorIndex == -1 || targetIndex == -1) {
      return false;
    }
    final start = anchorIndex < targetIndex ? anchorIndex : targetIndex;
    final end = anchorIndex < targetIndex ? targetIndex : anchorIndex;
    final next = orderedVisibleIds.sublist(start, end + 1);
    if (_selected.length == next.length && _selected.containsAll(next)) {
      return false;
    }
    _selected
      ..clear()
      ..addAll(next);
    return true;
  }

  /// Adds [ids] to the selection. Returns true if any id was newly added.
  bool addAll(Iterable<String> ids) {
    var changed = false;
    for (final id in ids) {
      if (_selected.add(id)) {
        changed = true;
      }
    }
    return changed;
  }

  /// Removes [ids] from the selection. Returns true if any id was removed.
  bool removeAll(Iterable<String> ids) {
    var changed = false;
    for (final id in ids) {
      if (_selected.remove(id)) {
        changed = true;
      }
    }
    return changed;
  }

  /// Keeps only ids that satisfy [test]. Returns true if the set changed.
  bool retainWhere(bool Function(String id) test) {
    final before = _selected.length;
    _selected.removeWhere((element) => !test(element));
    return before != _selected.length;
  }
}
