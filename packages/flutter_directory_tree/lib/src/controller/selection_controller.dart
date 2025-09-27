// lib/src/controller/selection_controller.dart
import 'package:directory_tree/directory_tree.dart'
    show SelectionMode, SelectionSet;
import 'package:flutter/foundation.dart';

export 'package:directory_tree/directory_tree.dart' show SelectionMode;

/// Minimal selection model with toggle + range.
class SelectionController extends ChangeNotifier {
  SelectionController(
      {SelectionMode mode = SelectionMode.single, SelectionSet? state})
      : _state = state ?? SelectionSet(mode: mode) {
    // Ensure injected state follows the requested mode.
    _state.mode = mode;
  }

  final SelectionSet _state;
  bool _batching = false;
  bool _dirty = false;

  SelectionMode get mode => _state.mode;
  set mode(SelectionMode value) => _state.mode = value;

  bool isSelected(String id) => _state.isSelected(id);

  Set<String> get selectedIds => _state.selectedIds;

  void selectOnly(String id) {
    if (_state.selectOnly(id)) {
      _emitChange();
    }
  }

  void toggle(String id) {
    if (_state.toggle(id)) {
      _emitChange();
    }
  }

  void clear() {
    if (_state.clear()) {
      _emitChange();
    }
  }

  /// Shift-like range selection using the current visible order.
  void selectRange(
      List<String> orderedVisibleIds, String anchorId, String toId) {
    if (_state.selectRange(orderedVisibleIds, anchorId, toId)) {
      _emitChange();
    }
  }

  /// Keep only ids that still exist in the new tree.
  void retainWhere(bool Function(String id) test) {
    if (_state.retainWhere(test)) {
      _emitChange();
    }
  }

  /// Perform several selection updates while emitting at most one notification.
  void performBatch(void Function() updates) {
    if (_batching) {
      updates();
      return;
    }
    _batching = true;
    try {
      updates();
    } finally {
      _batching = false;
      if (_dirty) {
        _dirty = false;
        notifyListeners();
      }
    }
  }

  /// Add [ids] to the current selection.
  void addAll(Iterable<String> ids) {
    if (_state.addAll(ids)) {
      _emitChange();
    }
  }

  /// Remove [ids] from the current selection.
  void removeAll(Iterable<String> ids) {
    if (_state.removeAll(ids)) {
      _emitChange();
    }
  }

  SelectionSet get state {
    final snapshot = SelectionSet(mode: _state.mode);
    if (_state.selectedIds.isNotEmpty) {
      snapshot.addAll(_state.selectedIds);
    }
    return snapshot;
  }

  void _emitChange() {
    if (_batching) {
      _dirty = true;
    } else {
      notifyListeners();
    }
  }
}
