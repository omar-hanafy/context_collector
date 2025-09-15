// lib/src/features/scan/presentation/ui/shared_drop_zone.dart
import 'dart:async';

import 'package:context_collector/context_collector.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/name_prompt.dart' as prompts;

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
      onDragDone: (DropDoneDetails details) async {
        setState(() => _isDragging = false);

        final fileItems = <XFile>[];
        final textPayloads = <String>{};

        for (final item in details.files) {
          if (item.isMemoryBacked && item.isTextLike) {
            try {
              final text = await item.readAsText();
              final normalized = text?.trim();
              if (normalized != null && normalized.isNotEmpty) {
                textPayloads.add(normalized);
              }
            } catch (_) {}
            continue;
          }
          fileItems.add(item);
        }

        if (fileItems.isNotEmpty) {
          await selectionNotifier.processDroppedItems(fileItems);
          // Ignore accompanying text flavors when files are present.
        } else {
          for (final text in textPayloads) {
            final name = await prompts.promptForNewFileName(
              context,
              initialName: 'pasted.txt',
            );
            if (name != null && name.trim().isNotEmpty) {
              selectionNotifier.createVirtualFile(name.trim(), text);
            }
          }
          // Recover Monaco focus after dialog/virtual-file creation in editor route.
          // Safe to call even if editor is not currently mounted.
          unawaited(
            ref.read(monacoEditorStatusProvider.notifier).recoverKeyboardFocus(),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isDragging
              ? Theme.of(context).colorScheme.primary.setOpacity(0.05)
              : null,
          border: _isDragging
              ? Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.child,
      ),
    );
  }
}
