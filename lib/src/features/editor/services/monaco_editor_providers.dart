// lib/src/features/editor/services/monaco_editor_providers.dart
import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:context_collector/src/features/editor/assets_manager/notifier.dart';
import 'package:context_collector/src/features/editor/services/monaco_editor_service.dart';
import 'package:context_collector/src/features/editor/services/monaco_editor_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for Monaco editor status
final monacoEditorStatusProvider =
    StateNotifierProvider<MonacoEditorStatusNotifier, MonacoEditorStatus>(
        (ref) {
  return MonacoEditorStatusNotifier();
});

/// Provider for the global Monaco editor service
final monacoEditorServiceProvider = Provider<MonacoEditorService>((ref) {
  final service = MonacoEditorService(ref);

  // Dispose when provider is disposed
  ref
    ..onDispose(service.dispose)

    // Listen to asset status changes to automatically initialize when ready
    ..listen<MonacoAssetStatus>(monacoAssetStatusProvider, (previous, next) {
      final editorStatus = ref.read(monacoEditorStatusProvider);

      // If assets just became ready and editor is idle, initialize
      if (previous?.isReady != true &&
          next.isReady &&
          editorStatus.state == MonacoEditorServiceState.idle) {
        debugPrint(
            '[MonacoEditorServiceProvider] Assets ready, initializing editor');
        service.initialize();
      }

      // If assets failed and editor was waiting, update status
      if (next.hasError &&
          editorStatus.state == MonacoEditorServiceState.waitingForAssets) {
        ref.read(monacoEditorStatusProvider.notifier).updateStatus(
              MonacoEditorStatus(
                state: MonacoEditorServiceState.error,
                error: 'Monaco assets failed to load: ${next.error}',
                lastUpdate: DateTime.now(),
              ),
            );
      }
    });

  return service;
});

/// Convenient provider for checking if editor is ready
final monacoEditorReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(monacoEditorStatusProvider);
  return status.isReady;
});

/// Provider for checking if editor should be visible
final monacoEditorVisibleProvider = Provider<bool>((ref) {
  final status = ref.watch(monacoEditorStatusProvider);
  return status.isVisible;
});

/// Provider for checking if editor can be shown (ready + has content)
final monacoEditorCanShowProvider = Provider<bool>((ref) {
  final status = ref.watch(monacoEditorStatusProvider);
  return status.canShow;
});

/// Provider for editor loading progress
final monacoEditorProgressProvider = Provider<double>((ref) {
  final status = ref.watch(monacoEditorStatusProvider);
  return status.progress;
});

/// Provider for AI token calculator
final tokenCalculatorProvider =
    Provider<AITokenCalculator>((ref) => AITokenCalculator());

/// Provider for selected AI model (persisted in session)
final selectedAIModelProvider = StateProvider<AIModel>((ref) {
  return AIModel.claudeSonnet; // Default to Claude for Context Collector
});
