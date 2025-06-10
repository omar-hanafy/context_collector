// lib/src/features/editor/services/monaco_editor_providers.dart
import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:context_collector/context_collector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- RIVERPOD PROVIDERS ---
final unifiedMonacoProvider =
    StateNotifierProvider<UnifiedMonacoService, EditorStatus>((ref) {
  final service = UnifiedMonacoService();
  ref.onDispose(service.dispose);
  return service;
});

final monacoReadyProvider =
    Provider<bool>((ref) => ref.watch(unifiedMonacoProvider).isReady);
final StateNotifierProvider<UnifiedMonacoService, EditorStatus>
    monacoEditorStatusProvider = unifiedMonacoProvider;
final Refreshable<UnifiedMonacoService> monacoEditorServiceProvider =
    unifiedMonacoProvider.notifier;

/// Convenient provider for checking if editor is ready
final monacoEditorReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(monacoEditorStatusProvider);
  return status.isReady;
});

/// Provider for AI token calculator
final tokenCalculatorProvider =
    Provider<AITokenCalculator>((ref) => AITokenCalculator());

/// Provider for selected AI model (persisted in session)
final selectedAIModelProvider = StateProvider<AIModel>((ref) {
  return AIModel.claudeSonnet; // Default to Claude for Context Collector
});
