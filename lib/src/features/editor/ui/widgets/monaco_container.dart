import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../context_collector.dart';
import '../../../scan/ui/file_display_helper.dart';

/// Global container with layered architecture.
/// This widget is the main controller that orchestrates the visibility of the UI
/// and the flow of data between the file selection and the editor service.
class GlobalMonacoContainer extends ConsumerStatefulWidget {
  const GlobalMonacoContainer({
    required this.child, // This will be the HomeScreen
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<GlobalMonacoContainer> createState() =>
      _GlobalMonacoContainerState();
}

class _GlobalMonacoContainerState extends ConsumerState<GlobalMonacoContainer> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for active file/content changes to update the Monaco editor.
    ref.listen<SelectionState>(selectionProvider, (previous, next) async {
      final editorService = ref.read(monacoEditorStatusProvider.notifier);
      final controller = ref.read(monacoControllerProvider);

      final prevId = previous?.activeFileId;
      final nextId = next.activeFileId;

      // Persist current Monaco text into the previously active file before switching
      if (prevId != null && prevId != nextId && controller != null) {
        try {
          final currentText = await controller.getValue();
          ref.read(selectionProvider.notifier).saveEditorTextFor(prevId, currentText);
        } catch (_) {
          // Ignore non-fatal errors while reading the editor content
        }
      }

      // Determine target text and language for Monaco based on active file
      String targetText = '';
      String? language;
      if (nextId != null) {
        final file = next.fileMap[nextId];
        if (file != null) {
          targetText = file.effectiveContent;
          language = FileDisplayHelper.getLanguageFromFile(file);
        }
      }

      final activeChanged = prevId != nextId;
      final contentChanged = nextId != null &&
          (previous == null ||
              (previous.activeFileId == nextId &&
                  (previous.fileMap[nextId]?.effectiveContent ?? '') != targetText));

      if (activeChanged || contentChanged) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 80), () async {
          if (!mounted) return;
          await editorService.updateContent(targetText, language: language);
        });
      }
    });

    // Determine if the HomeScreen overlay should be visible.
    final selectionState = ref.watch(selectionProvider);
    final showHomeOverlay = selectionState.fileMap.isEmpty;

    return Material(
      child: Stack(
        children: [
          const EditorScreen(),
          Offstage(
            offstage: !showHomeOverlay,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
