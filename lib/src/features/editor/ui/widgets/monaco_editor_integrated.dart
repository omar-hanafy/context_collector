import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A stateless, declarative UI widget that displays the Monaco Editor.
///
/// This widget listens to the [monacoProvider] and renders the appropriate
/// UI for the current editor state (loading, ready, or error). It holds no
/// internal state or complex logic, delegating all of that to the service.
class MonacoEditorIntegrated extends ConsumerWidget {
  const MonacoEditorIntegrated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the single source of truth for the editor's status.
    final editorStatus = ref.watch(monacoEditorStatusProvider);
    final service = ref.read(monacoEditorStatusProvider.notifier);

    // The entire UI is built declaratively based on the service's state.
    return Stack(
      children: [
        Offstage(
          offstage: editorStatus.lifecycle != EditorLifecycle.ready,
          child: SizedBox.expand(
            child: service.webviewWidget,
          ),
        ),
        Offstage(
          offstage: editorStatus.lifecycle != EditorLifecycle.error,
          child: _ErrorView(
            error: editorStatus.error,
            onRetry: service.initialize,
          ),
        ),
        Offstage(
          offstage:
              editorStatus.lifecycle == EditorLifecycle.ready ||
              editorStatus.lifecycle == EditorLifecycle.error,
          child: _LoadingView(
            message: editorStatus.message,
          ),
        ),
      ],
    );
  }
}

/// A private helper widget for displaying the loading state.
class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Starting Monaco Editor...',
              style: context.bodyMedium?.copyWith(
                color: context.onSurface.setOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.bodySmall?.copyWith(
                color: context.onSurface.setOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A private helper widget for displaying the error state.
class _ErrorView extends StatelessWidget {
  const _ErrorView({this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: context.error),
            const SizedBox(height: 16),
            Text(
              'Monaco Editor Error',
              style: context.titleLarge?.copyWith(color: context.error),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error ?? 'An unknown error occurred during initialization.',
                textAlign: TextAlign.center,
                style: context.bodyMedium?.copyWith(
                  color: context.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Initialization'),
            ),
          ],
        ),
      ),
    );
  }
}
