// lib/src/controller/tree_diff.dart
import 'package:directory_tree/directory_tree.dart' show VisibleNode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

export 'package:directory_tree/directory_tree.dart'
    show ListDiff, diffVisibleNodes;

/// Jump the scroll so that the same top-row id stays anchored after a list change.
/// Safe to call repeatedly; it runs after layout.
void schedulePreserveScrollOffset({
  required ScrollController controller,
  required List<VisibleNode> before,
  required List<VisibleNode> after,
  required double rowExtent,
}) {
  if (!controller.hasClients || before.isEmpty || after.isEmpty) return;

  final oldOffset = controller.offset.clamp(0.0, double.infinity);
  final oldTopIndex =
      (oldOffset / rowExtent).floor().clamp(0, before.length - 1);
  final anchorId = before[oldTopIndex].id;

  final newIndex = after.indexWhere((n) => n.id == anchorId);
  if (newIndex == -1) return; // Anchor vanished; do nothing.

  final remainder = oldOffset - (oldTopIndex * rowExtent);
  final target = (newIndex * rowExtent + remainder).clamp(0.0, double.infinity);

  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
    final max = controller.position.maxScrollExtent;
    controller.jumpTo(target.clamp(0.0, max));
  });
}
