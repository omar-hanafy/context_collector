// lib/src/features/editor/presentation/ui/monaco_asset_loading_widget.dart
import 'dart:async';

import 'package:context_collector/context_collector.dart';
import 'package:context_collector/src/features/editor/assets_manager/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget that shows Monaco asset loading progress
class MonacoAssetLoadingWidget extends ConsumerWidget {
  const MonacoAssetLoadingWidget({
    super.key,
    this.onReady,
    this.showDetails = true,
    this.compact = false,
  });

  final VoidCallback? onReady;
  final bool showDetails;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(monacoAssetStatusProvider);

    // Trigger callback when ready
    ref.listen<MonacoAssetStatus>(monacoAssetStatusProvider, (previous, next) {
      if (next.isReady && previous?.state != MonacoAssetState.ready) {
        onReady?.call();
      }
    });

    if (status.isReady) {
      return _buildReadyState(context);
    }

    if (compact) {
      return _buildCompactLoading(context, status);
    }

    return _buildFullLoading(context, status, ref);
  }

  Widget _buildReadyState(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: context.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: context.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Monaco Editor Ready',
            style: context.bodyMedium?.copyWith(
              color: context.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoading(BuildContext context, MonacoAssetStatus status) {
    return Container(
      padding:
          const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: status.progress > 0 ? status.progress : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(status),
            style: context.bodySmall?.copyWith(
              color: context.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullLoading(
      BuildContext context, MonacoAssetStatus status, WidgetRef ref) {
    return Container(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(12),
                decoration: BoxDecoration(
                  color: context.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.code,
                  color: context.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preparing Monaco Editor',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Setting up the code editor for optimal performance',
                      style: context.bodySmall?.copyWith(
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress indicator
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: status.progress > 0 ? status.progress : null,
                      backgroundColor: context.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(status.progress * 100).toInt()}%',
                    style: context.bodySmall?.copyWith(
                      color: context.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusIcon(context, status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.message ?? _getStatusText(status),
                      style: context.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (showDetails) ...[
            const SizedBox(height: 16),
            _buildDetailsSection(context, status, ref),
          ],

          if (status.hasError) ...[
            const SizedBox(height: 16),
            _buildErrorSection(context, status, ref),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, MonacoAssetStatus status) {
    switch (status.state) {
      case MonacoAssetState.idle:
        return Icon(Icons.hourglass_empty,
            size: 16, color: context.onSurfaceVariant);
      case MonacoAssetState.initializing:
        return SizedBox(
          width: 16,
          height: 16,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: context.primary),
        );
      case MonacoAssetState.copying:
        return Icon(Icons.download, size: 16, color: context.primary);
      case MonacoAssetState.verifying:
        return Icon(Icons.verified, size: 16, color: context.primary);
      case MonacoAssetState.ready:
        return Icon(Icons.check_circle, size: 16, color: context.primary);
      case MonacoAssetState.error:
        return Icon(Icons.error, size: 16, color: context.error);
      case MonacoAssetState.retrying:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: context.secondary),
        );
    }
  }

  Widget _buildDetailsSection(
      BuildContext context, MonacoAssetStatus status, WidgetRef ref) {
    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: context.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Details',
                style: context.bodySmall?.copyWith(
                  color: context.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow(context, 'Status', _getStatusText(status)),
          if (status.progress > 0)
            _buildDetailRow(
                context, 'Progress', '${(status.progress * 100).toInt()}%'),
          if (status.retryCount > 0)
            _buildDetailRow(
                context, 'Retry Count', status.retryCount.toString()),
          if (status.lastUpdate != null)
            _buildDetailRow(
                context, 'Last Update', _formatTime(status.lastUpdate!)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: context.bodySmall?.copyWith(
                color: context.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: context.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(
      BuildContext context, MonacoAssetStatus status, WidgetRef ref) {
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: context.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: context.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Initialization Failed',
                style: context.titleSmall?.copyWith(
                  color: context.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status.error ?? 'Unknown error occurred',
            style: context.bodySmall?.copyWith(
              color: context.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(monacoAssetManagerProvider).retryInitialization(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.onErrorContainer,
                  side: BorderSide(color: context.onErrorContainer),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () =>
                    ref.read(monacoAssetManagerProvider).clearCache(),
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Cache'),
                style: TextButton.styleFrom(
                  foregroundColor: context.onErrorContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(MonacoAssetStatus status) {
    switch (status.state) {
      case MonacoAssetState.idle:
        return 'Ready to initialize';
      case MonacoAssetState.initializing:
        return 'Initializing...';
      case MonacoAssetState.copying:
        return 'Copying assets...';
      case MonacoAssetState.verifying:
        return 'Verifying assets...';
      case MonacoAssetState.ready:
        return 'Ready';
      case MonacoAssetState.error:
        return 'Error occurred';
      case MonacoAssetState.retrying:
        return 'Retrying...';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

/// Simple loading indicator for Monaco assets
class MonacoAssetLoadingIndicator extends ConsumerWidget {
  const MonacoAssetLoadingIndicator({
    super.key,
    this.size = 24,
  });

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(monacoAssetStatusProvider);

    if (status.isReady) {
      return Icon(
        Icons.check_circle,
        size: size,
        color: context.primary,
      );
    }

    if (status.hasError) {
      return Icon(
        Icons.error,
        size: size,
        color: context.error,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: status.progress > 0 ? status.progress : null,
      ),
    );
  }
}

/// Consumer wrapper that automatically initializes Monaco assets
class MonacoAssetInitializer extends ConsumerStatefulWidget {
  const MonacoAssetInitializer({
    required this.child,
    super.key,
    this.loadingWidget,
    this.autoInitialize = true,
  });

  final Widget child;
  final Widget? loadingWidget;
  final bool autoInitialize;

  @override
  ConsumerState<MonacoAssetInitializer> createState() =>
      _MonacoAssetInitializerState();
}

class _MonacoAssetInitializerState
    extends ConsumerState<MonacoAssetInitializer> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeAssets();
      });
    }
  }

  Future<void> _initializeAssets() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    try {
      await ref.read(monacoAssetManagerProvider).initializeAssets();
    } catch (e) {
      debugPrint('[MonacoAssetInitializer] Initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(monacoAssetStatusProvider);

    if (status.isReady) {
      return widget.child;
    }

    return widget.loadingWidget ??
        MonacoAssetLoadingWidget(
          onReady: () {
            // Child will be rebuilt automatically due to Riverpod state change
          },
        );
  }
}

/// Hook for using Monaco asset status in functional widgets
extension MonacoAssetHooks on WidgetRef {
  /// Wait for Monaco assets to be ready
  Future<String> waitForMonacoAssets({Duration? timeout}) async {
    return read(monacoAssetManagerProvider).waitForAssets(timeout: timeout);
  }

  /// Initialize Monaco assets if not already done
  Future<String> initializeMonacoAssets() async {
    return read(monacoAssetManagerProvider).initializeAssets();
  }

  /// Check if Monaco assets are ready
  bool get areMonacoAssetsReady => read(monacoAssetsReadyProvider);

  /// Get Monaco asset path if ready
  String? get monacoAssetPath => read(monacoAssetPathProvider);
}
