// lib/src/features/scan/presentation/ui/shared_drop_zone.dart
import 'package:context_collector/context_collector.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reusable widget that provides a drop zone for files and directories,
/// with visual feedback during a drag operation.
class DropZone extends ConsumerStatefulWidget {
  const DropZone({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DropZone> createState() => _SharedDropZoneState();
}

class _SharedDropZoneState extends ConsumerState<DropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final selectionNotifier = ref.read(selectionProvider.notifier);

    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isEmpty) return;
        await selectionNotifier.processDroppedItems(details.files);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isDragging ? context.primary.addOpacity(0.05) : null,
          border: _isDragging
              ? Border.all(
                  color: context.primary.addOpacity(0.3),
                  width: 2,
                )
              : null,
          borderRadius: _isDragging ? BorderRadius.circular(4) : null,
        ),
        child: widget.child,
      ),
    );
  }
}
