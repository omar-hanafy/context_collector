import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monaco_service.dart';

/// Main Monaco service provider
final monacoEditorStatusProvider =
    StateNotifierProvider<MonacoService, EditorStatus>((
      ref,
    ) {
      final service = MonacoService();
      ref.onDispose(service.dispose);
      return service;
    });

/// Convenient provider for checking if editor is ready
final monacoEditorReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(monacoEditorStatusProvider);
  return status.isReady;
});

/// Provider for MonacoController (nullable because it's created asynchronously)
final monacoControllerProvider = Provider<MonacoController?>((ref) {
  final service = ref.watch(monacoEditorStatusProvider.notifier);
  return service.controller;
});

/// Provider for AI token calculator
final tokenCalculatorProvider = Provider<AITokenCalculator>(
  (ref) => AITokenCalculator(),
);

/// Provider for selected AI model (persisted in session)
final selectedAIModelProvider = StateProvider<AIModel>((ref) {
  return AIModel.claudeSonnet; // Default to Claude for Context Collector
});
