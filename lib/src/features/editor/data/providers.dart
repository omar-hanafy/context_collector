import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/modal_overlay_coordinator.dart';
import 'monaco_service.dart';

/// Main Monaco service provider
final AutoDisposeStateNotifierProvider<MonacoService, EditorStatus>
monacoEditorStatusProvider =
    StateNotifierProvider.autoDispose<MonacoService, EditorStatus>((ref) {
      // Keep Monaco alive across routes so it can be pre-warmed on app start.
      // This prevents autoDispose from tearing it down when not directly watched.
      // Riverpod will still dispose it with the ProviderScope.
      // ignore: unused_local_variable
      final link = ref.keepAlive();

      return MonacoService(
        overlayCoordinator: ref.read(modalOverlayCoordinatorProvider),
      );
    });

/// Convenient provider for checking if editor is ready
final monacoEditorReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(monacoEditorStatusProvider);
  return status.isReady;
}, dependencies: [monacoEditorStatusProvider]);

/// Provider for MonacoController (nullable because it's created asynchronously)
/// Note: depend on lifecycle so consumers rebuild when controller becomes ready.
final monacoControllerProvider = Provider<MonacoController?>((ref) {
  // Watching state (or a slice) triggers rebuilds; watching `.notifier` would not.
  ref.watch(monacoEditorStatusProvider.select((s) => s.lifecycle));
  return ref.read(monacoEditorStatusProvider.notifier).controller;
}, dependencies: [monacoEditorStatusProvider]);
