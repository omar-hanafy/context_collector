// lib/src/features/editor/presentation/ui/global_monaco_container.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../scan/presentation/state/selection_notifier.dart';
import '../../services/monaco_editor_providers.dart';
import 'editor_screen.dart';

/// Global container with layered architecture
/// Bottom layer: Complete Editor UI (file list + monaco editor) - always loaded
/// Top layer: Home Screen - fades in/out based on file selection
class GlobalMonacoContainer extends ConsumerWidget {
  const GlobalMonacoContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final editorStatus = ref.watch(monacoEditorStatusProvider);
    
    // Show home overlay when:
    // 1. No files are manually added (not including welcome/test content)
    // 2. All files have been cleared
    final showHomeOverlay = selectionState.allFiles.isEmpty;
    
    debugPrint('[GlobalMonacoContainer] Build - ShowHomeOverlay: $showHomeOverlay, Files: ${selectionState.allFiles.length}');

    return Material(
      child: Stack(
        children: [
          // BOTTOM LAYER: Complete Editor UI (always present, always loaded)
          const EditorScreen(),
          
          // TOP LAYER: Home Screen overlay (fades in/out)
          // Using IgnorePointer to ensure underlying widgets can receive events when hidden
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: showHomeOverlay
                ? child // This is the HomeScreen with drop zone
                : IgnorePointer(
                    key: const ValueKey('ignore-pointer'),
                    child: Container(
                      key: const ValueKey('empty-overlay'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
