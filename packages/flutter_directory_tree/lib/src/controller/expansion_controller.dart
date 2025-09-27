// lib/src/controller/expansion_controller.dart
import 'package:directory_tree/directory_tree.dart';
import 'package:flutter/foundation.dart';

/// Tracks which folder nodes are expanded.
class ExpansionController extends ChangeNotifier {
  ExpansionController({Set<String>? initiallyExpanded, ExpansionSet? state})
      : _state = state ?? ExpansionSet(initiallyExpanded: initiallyExpanded);

  final ExpansionSet _state;
  bool _batching = false;
  bool _dirty = false;

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

  bool isExpanded(String id) => _state.isExpanded(id);

  void setExpanded(String id, bool expanded) {
    _markChanged(_state.setExpanded(id, expanded));
  }

  void toggle(String id) {
    _markChanged(_state.toggle(id));
  }

  void expandAll(Iterable<String> ids) {
    performBatch(() {
      _markChanged(_state.expandAll(ids));
    });
  }

  void collapseAll() {
    performBatch(() {
      _markChanged(_state.collapseAll());
    });
  }

  Set<String> get expandedIds => _state.expandedIds;

  /// Keep only ids that still exist in the new tree.
  void retainWhere(bool Function(String id) test) {
    _markChanged(_state.retainWhere(test));
  }

  ExpansionSet get state => ExpansionSet(initiallyExpanded: _state.expandedIds);

  void _markChanged(bool changed) {
    if (!changed) return;
    if (_batching) {
      _dirty = true;
    } else {
      notifyListeners();
    }
  }
}
