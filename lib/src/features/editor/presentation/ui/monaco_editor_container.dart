// lib/src/features/editor/presentation/ui/monaco_editor_container.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/extensions.dart';
import '../../../scan/presentation/state/selection_notifier.dart';
import '../../assets_manager/notifier.dart';
import '../../services/monaco_editor_providers.dart';
import '../../services/monaco_editor_service.dart';
import '../../services/monaco_editor_state.dart';
import 'monaco_editor_integrated.dart';

/// Monaco Editor Container - Always present in the editor screen
class MonacoEditorContainer extends ConsumerStatefulWidget {
  const MonacoEditorContainer({
    super.key,
    this.height,
    this.onReady,
  });

  final double? height;
  final VoidCallback? onReady;

  @override
  ConsumerState<MonacoEditorContainer> createState() =>
      _MonacoEditorContainerState();
}

class _MonacoEditorContainerState extends ConsumerState<MonacoEditorContainer> {
  bool _hasNotifiedReady = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize editor when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        final editorService = ref.read(monacoEditorServiceProvider);
        editorService.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorStatus = ref.watch(monacoEditorStatusProvider);
    final assetStatus = ref.watch(monacoAssetStatusProvider);
    final selectionState = ref.watch(selectionProvider);
    final editorService = ref.watch(monacoEditorServiceProvider);

    // Listen for selection changes to update editor content
    ref.listen<SelectionState>(selectionProvider, (previous, next) {
      debugPrint(
          '[MonacoEditorContainer] Selection changed - has content: ${next.combinedContent.isNotEmpty}');

      if (previous?.combinedContent != next.combinedContent) {
        Future.microtask(() {
          if (next.combinedContent.isNotEmpty) {
            debugPrint('[MonacoEditorContainer] Setting editor content');
            editorService.setContent(next.combinedContent);
          } else {
            debugPrint('[MonacoEditorContainer] Clearing editor content');
            editorService.clearContent();
          }
        });
      }
    });

    // Listen for status changes
    ref.listen<MonacoEditorStatus>(monacoEditorStatusProvider,
        (previous, next) {
      debugPrint(
          '[MonacoEditorContainer] Status changed: ${previous?.state} → ${next.state}');

      // Notify ready callback once
      if (!_hasNotifiedReady && next.isReady) {
        _hasNotifiedReady = true;
        widget.onReady?.call();
      }
    });

    // Only show editor if assets are ready
    final shouldCreateEditor = assetStatus.state == MonacoAssetState.ready;

    return Stack(
      children: [
        // Create editor widget when assets are ready
        if (shouldCreateEditor) _buildEditor(editorService, editorStatus),

        // Overlay for loading/error states during initialization
        if ((editorStatus.isLoading || editorStatus.hasError) &&
            !editorStatus.isReady)
          _buildOverlay(editorStatus),
      ],
    );
  }

  Widget _buildEditor(
    MonacoEditorService service,
    MonacoEditorStatus status,
  ) {
    debugPrint(
        '[MonacoEditorContainer] Building editor widget - Status: ${status.state}');

    return MonacoEditorIntegrated(
      key: const Key('monaco_editor_webview'),
      bridge: service.bridge,
      onReady: () {
        debugPrint(
            '[MonacoEditorContainer] Editor WebView ready, marking service ready');
        service.markEditorReady();
      },
      height: widget.height,
    );
  }

  Widget _buildOverlay(MonacoEditorStatus status) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(status.state),
        color: context.surface.addOpacity(0.95),
        child: Center(
          child: _buildStatusContent(status),
        ),
      ),
    );
  }

  Widget _buildStatusContent(MonacoEditorStatus status) {
    if (status.hasError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.error),
          const SizedBox(height: 16),
          Text(
            'Editor Error',
            style: context.titleMedium?.copyWith(color: context.error),
          ),
          const SizedBox(height: 8),
          Text(
            status.error ?? 'Unknown error',
            style: context.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.read(monacoEditorServiceProvider).retryInitialization();
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          value: status.progress > 0 ? status.progress : null,
        ),
        const SizedBox(height: 16),
        Text(
          'Loading Editor...',
          style: context.titleMedium,
        ),
        if (status.message != null) ...[
          const SizedBox(height: 8),
          Text(
            status.message!,
            style: context.bodySmall?.copyWith(
              color: context.onSurface.addOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}
