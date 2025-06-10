// lib/src/features/editor/presentation/ui/global_monaco_container.dart
import 'package:context_collector/src/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global container with layered architecture.
/// This widget is the main controller that orchestrates the visibility of the UI
/// and the flow of data between the file selection and the editor service.
class GlobalMonacoContainer extends ConsumerWidget {
  const GlobalMonacoContainer({
    required this.child, // This will be the HomeScreen
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for changes in the selection state to update the editor.
    // This listener lives here, in a widget that is ALWAYS in the tree,
    // so it will never miss an update. This is the core fix.
    ref.listen<SelectionState>(selectionProvider, (previous, next) {
      if (previous?.combinedContent != next.combinedContent) {
        final editorService = ref.read(monacoProvider.notifier);
        // Use a microtask to avoid trying to update state during a build.
        Future.microtask(() {
          debugPrint(
            '[GlobalListener] Selection changed, updating editor content...',
          );
          editorService.updateContent(next.combinedContent);
        });
      }
    });

    // Determine if the HomeScreen overlay should be visible.
    final selectionState = ref.watch(selectionProvider);
    final showHomeOverlay = selectionState.allFiles.isEmpty;

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
                ? child // Show the HomeScreen
                : const SizedBox.shrink(key: ValueKey('hidden')), // Hide it
          ),
        ],
      ),
    );
  }
}
