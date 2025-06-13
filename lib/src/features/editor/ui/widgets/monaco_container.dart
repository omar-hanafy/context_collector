// lib/src/features/editor/presentation/ui/global_monaco_container.dart
import 'dart:async';

import 'package:context_collector/src/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // Listen for changes in the selection state to update the editor.
    // This listener lives here, in a widget that is ALWAYS in the tree,
    // so it will never miss an update. This is the core fix.
    ref.listen<SelectionState>(selectionProvider, (previous, next) {
      if (previous?.combinedContent != next.combinedContent) {
        // Cancel any pending updates
        _debounceTimer?.cancel();

        // Debounce the update by 100ms to avoid rapid updates
        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            final editorService = ref.read(monacoProvider.notifier);
            debugPrint(
              '[GlobalListener] Updating editor content after debounce...',
            );
            editorService.updateContent(next.combinedContent);
          }
        });
      }
    });

    // Determine if the HomeScreen overlay should be visible.
    final selectionState = ref.watch(selectionProvider);
    final showHomeOverlay = selectionState.fileMap.isEmpty;

    return Material(
      child: Stack(
        children: [
          // BOTTOM LAYER: The EditorScreen is always present in the background,
          // fulfilling the "always-ready" requirement.
          const EditorScreen(),

          // TOP LAYER: The HomeScreen drop zone, which fades in or out.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: showHomeOverlay
                ? widget
                      .child // Show the HomeScreen
                : const SizedBox.shrink(key: ValueKey('hidden')), // Hide it
          ),
        ],
      ),
    );
  }
}
