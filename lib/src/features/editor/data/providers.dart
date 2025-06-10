// Monaco Editor Providers
import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:context_collector/context_collector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- RIVERPOD PROVIDERS ---
final monacoProvider = StateNotifierProvider<MonacoService, EditorStatus>((
  ref,
) {
  final service = MonacoService();
  ref.onDispose(service.dispose);
  return service;
});

final monacoReadyProvider = Provider<bool>(
  (ref) => ref.watch(monacoProvider).isReady,
);
final StateNotifierProvider<MonacoService, EditorStatus>
monacoEditorStatusProvider = monacoProvider;
final Refreshable<MonacoService> monacoEditorServiceProvider =
    monacoProvider.notifier;

/// Convenient provider for checking if editor is ready
final monacoEditorReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(monacoEditorStatusProvider);
  return status.isReady;
});

/// Provider for AI token calculator
final tokenCalculatorProvider = Provider<AITokenCalculator>(
  (ref) => AITokenCalculator(),
);

/// Provider for selected AI model (persisted in session)
final selectedAIModelProvider = StateProvider<AIModel>((ref) {
  return AIModel.claudeSonnet; // Default to Claude for Context Collector
});
