// lib/src/features/editor/services/monaco_asset_manager.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// States for Monaco asset management
enum MonacoAssetState {
  idle,
  initializing,
  copying,
  verifying,
  ready,
  error,
  retrying,
}

/// Detailed asset preparation status
class MonacoAssetStatus {
  const MonacoAssetStatus({
    required this.state,
    this.progress = 0.0,
    this.message,
    this.error,
    this.assetPath,
    this.retryCount = 0,
    this.lastUpdate,
  });

  final MonacoAssetState state;
  final double progress;
  final String? message;
  final String? error;
  final String? assetPath;
  final int retryCount;
  final DateTime? lastUpdate;

  MonacoAssetStatus copyWith({
    MonacoAssetState? state,
    double? progress,
    String? message,
    String? error,
    String? assetPath,
    int? retryCount,
    DateTime? lastUpdate,
  }) {
    return MonacoAssetStatus(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error ?? this.error,
      assetPath: assetPath ?? this.assetPath,
      retryCount: retryCount ?? this.retryCount,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  bool get isReady => state == MonacoAssetState.ready;

  bool get isLoading => [
        MonacoAssetState.initializing,
        MonacoAssetState.copying,
        MonacoAssetState.verifying,
        MonacoAssetState.retrying,
      ].contains(state);

  bool get hasError => state == MonacoAssetState.error;

  @override
  String toString() =>
      'MonacoAssetStatus(state: $state, progress: ${(progress * 100).toInt()}%, message: $message)';
}

/// Monaco Asset Manager - Core service class
class MonacoAssetManager {
  MonacoAssetManager(this._ref);

  static const String _assetBaseDir = 'assets/monaco';
  static const String _cacheSubDir = 'monaco_editor_cache';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  final Ref _ref;
  String? _cachedAssetPath;
  Timer? _retryTimer;
  Completer<String>? _initCompleter;

  /// Initialize Monaco assets - main entry point
  Future<String> initializeAssets() async {
    debugPrint('[MonacoAssetManager] Starting asset initialization');

    // Return cached path if already ready
    if (_cachedAssetPath != null) {
      debugPrint(
          '[MonacoAssetManager] Assets already ready at: $_cachedAssetPath');
      return _cachedAssetPath!;
    }

    // If initialization is already in progress, wait for it
    if (_initCompleter != null) {
      debugPrint('[MonacoAssetManager] Initialization in progress, waiting...');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<String>();

    try {
      await _performInitialization();
      final assetPath = _cachedAssetPath!;
      _initCompleter!.complete(assetPath);
      return assetPath;
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    } finally {
      _initCompleter = null;
    }
  }

  /// Perform the actual initialization process
  Future<void> _performInitialization() async {
    _updateStatus(MonacoAssetStatus(
      state: MonacoAssetState.initializing,
      message: 'Preparing Monaco Editor assets...',
      lastUpdate: DateTime.now(),
    ));

    try {
      // Step 1: Determine target directory
      final targetDir = await _getTargetDirectory();
      debugPrint('[MonacoAssetManager] Target directory: $targetDir');

      // Step 2: Check if assets are already prepared and valid
      if (await _validateExistingAssets(targetDir)) {
        debugPrint('[MonacoAssetManager] Valid assets found, skipping copy');
        _cachedAssetPath = targetDir;
        _updateStatus(MonacoAssetStatus(
          state: MonacoAssetState.ready,
          progress: 1,
          message: 'Monaco Editor assets ready',
          assetPath: targetDir,
          lastUpdate: DateTime.now(),
        ));
        return;
      }

      // Step 3: Copy all Monaco assets
      await _copyAllAssets(targetDir);

      // Step 4: Verify the copied assets
      await _verifyAssets(targetDir);

      // Step 5: Cache the path and mark as ready
      _cachedAssetPath = targetDir;
      _updateStatus(MonacoAssetStatus(
        state: MonacoAssetState.ready,
        progress: 1,
        message: 'Monaco Editor assets ready',
        assetPath: targetDir,
        lastUpdate: DateTime.now(),
      ));

      debugPrint(
          '[MonacoAssetManager] Asset initialization completed successfully');
    } catch (e) {
      await _handleInitializationError(e);
    }
  }

  /// Get the target directory for Monaco assets
  Future<String> _getTargetDirectory() async {
    if (Platform.isWindows || Platform.isMacOS) {
      // Desktop: Use app support directory for persistent caching
      final appDir = await getApplicationSupportDirectory();
      return path.join(appDir.path, _cacheSubDir);
    } else {
      // Unsupported platform
      throw UnsupportedError('Context Collector only supports macOS and Windows');
    }
  }

  /// Validate existing assets to avoid unnecessary copying
  Future<bool> _validateExistingAssets(String targetDir) async {
    _updateStatus(MonacoAssetStatus(
      state: MonacoAssetState.verifying,
      progress: 0.1,
      message: 'Checking existing assets...',
      lastUpdate: DateTime.now(),
    ));

    try {
      // Check if essential Monaco files exist
      final vsDir =
          Directory(path.join(targetDir, 'monaco-editor', 'min', 'vs'));
      if (!vsDir.existsSync()) return false;

      final essentialFiles = [
        'loader.js',
        'editor/editor.main.js',
        'editor/editor.main.css',
      ];

      for (final file in essentialFiles) {
        final filePath = path.join(vsDir.path, file);
        if (!File(filePath).existsSync()) {
          debugPrint('[MonacoAssetManager] Missing essential file: $file');
          return false;
        }
      }

      // Check if assets are reasonably recent (less than 30 days old)
      final loaderFile = File(path.join(vsDir.path, 'loader.js'));
      final stat = loaderFile.statSync();
      final age = DateTime.now().difference(stat.modified);
      if (age.inDays > 30) {
        debugPrint(
            '[MonacoAssetManager] Assets are old (${age.inDays} days), refreshing');
        return false;
      }

      debugPrint('[MonacoAssetManager] Existing assets are valid');
      return true;
    } catch (e) {
      debugPrint('[MonacoAssetManager] Asset validation error: $e');
      return false;
    }
  }

  /// Copy all Monaco assets with progress tracking
  Future<void> _copyAllAssets(String targetDir) async {
    _updateStatus(MonacoAssetStatus(
      state: MonacoAssetState.copying,
      progress: 0.2,
      message: 'Copying Monaco Editor files...',
      lastUpdate: DateTime.now(),
    ));

    try {
      // Clean target directory
      final targetDirectory = Directory(targetDir);
      if (targetDirectory.existsSync()) {
        await targetDirectory.delete(recursive: true);
      }
      await targetDirectory.create(recursive: true);

      // Get all Monaco assets
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final monacoAssets = assetManifest
          .listAssets()
          .where((key) => key.startsWith(_assetBaseDir))
          .toList();

      debugPrint(
          '[MonacoAssetManager] Found ${monacoAssets.length} Monaco assets to copy');

      if (monacoAssets.isEmpty) {
        throw Exception('No Monaco assets found in bundle');
      }

      // Copy assets with progress tracking
      int copiedCount = 0;
      const batchSize = 10;

      for (int i = 0; i < monacoAssets.length; i += batchSize) {
        final batch = monacoAssets.skip(i).take(batchSize);

        await Future.wait(
          batch.map((assetKey) => _copyAssetFile(assetKey, targetDir)),
          eagerError: false, // Continue even if some files fail
        );

        copiedCount += batch.length;
        final progress =
            0.2 + (copiedCount / monacoAssets.length) * 0.6; // 20% to 80%

        _updateStatus(MonacoAssetStatus(
          state: MonacoAssetState.copying,
          progress: progress,
          message:
              'Copying Monaco assets ($copiedCount/${monacoAssets.length})...',
          lastUpdate: DateTime.now(),
        ));
      }

      debugPrint(
          '[MonacoAssetManager] Successfully copied ${monacoAssets.length} assets');
    } catch (e) {
      debugPrint('[MonacoAssetManager] Asset copying failed: $e');
      rethrow;
    }
  }

  /// Copy a single asset file
  Future<void> _copyAssetFile(String assetKey, String targetDir) async {
    try {
      final relativePath = assetKey.substring('$_assetBaseDir/'.length);
      if (relativePath.isEmpty) return;

      final targetPath = path.join(targetDir, relativePath);
      final targetFile = File(targetPath);

      // Create parent directories
      await targetFile.parent.create(recursive: true);

      // Copy the asset
      final bytes = await rootBundle.load(assetKey);
      await targetFile.writeAsBytes(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('[MonacoAssetManager] Failed to copy $assetKey: $e');
      // Don't rethrow - some assets might be directories or have permission issues
    }
  }

  /// Verify that the copied assets are complete
  Future<void> _verifyAssets(String targetDir) async {
    _updateStatus(MonacoAssetStatus(
      state: MonacoAssetState.verifying,
      progress: 0.9,
      message: 'Verifying Monaco assets...',
      lastUpdate: DateTime.now(),
    ));

    try {
      // Verify essential Monaco files exist and are non-empty
      final vsDir =
          Directory(path.join(targetDir, 'monaco-editor', 'min', 'vs'));

      final essentialFiles = [
        'loader.js',
        'editor/editor.main.js',
        'editor/editor.main.css',
      ];

      for (final file in essentialFiles) {
        final filePath = path.join(vsDir.path, file);
        final fileObj = File(filePath);

        if (!fileObj.existsSync()) {
          throw Exception('Essential file missing: $file');
        }

        final size = await fileObj.length();
        if (size == 0) {
          throw Exception('Essential file is empty: $file');
        }
      }

      debugPrint('[MonacoAssetManager] Asset verification completed');
    } catch (e) {
      debugPrint('[MonacoAssetManager] Asset verification failed: $e');
      rethrow;
    }
  }

  /// Handle initialization errors with retry logic
  Future<void> _handleInitializationError(dynamic error) async {
    final currentStatus = _ref.read(monacoAssetStatusProvider);
    final newRetryCount = currentStatus.retryCount + 1;

    debugPrint(
        '[MonacoAssetManager] Initialization error (attempt $newRetryCount): $error');

    if (newRetryCount >= _maxRetries) {
      _updateStatus(MonacoAssetStatus(
        state: MonacoAssetState.error,
        error:
            'Failed to initialize Monaco assets after $_maxRetries attempts: $error',
        retryCount: newRetryCount,
        lastUpdate: DateTime.now(),
      ));
      throw Exception('Monaco asset initialization failed: $error');
    }

    // Exponential backoff for retries
    final retryDelay = Duration(
      milliseconds:
          _retryDelay.inMilliseconds * pow(2, newRetryCount - 1).toInt(),
    );

    _updateStatus(MonacoAssetStatus(
      state: MonacoAssetState.retrying,
      message:
          'Retrying in ${retryDelay.inSeconds} seconds (attempt $newRetryCount/$_maxRetries)...',
      error: error.toString(),
      retryCount: newRetryCount,
      lastUpdate: DateTime.now(),
    ));

    _retryTimer = Timer(retryDelay, () {
      debugPrint(
          '[MonacoAssetManager] Retrying initialization (attempt $newRetryCount)');
      _performInitialization();
    });
  }

  /// Manual retry method for external triggers
  Future<String> retryInitialization() async {
    debugPrint('[MonacoAssetManager] Manual retry requested');
    _retryTimer?.cancel();
    _cachedAssetPath = null;
    _initCompleter = null;
    return initializeAssets();
  }

  /// Clean up cached assets
  Future<void> clearCache() async {
    debugPrint('[MonacoAssetManager] Clearing Monaco asset cache');

    try {
      _retryTimer?.cancel();
      _cachedAssetPath = null;
      _initCompleter = null;

      final targetDir = await _getTargetDirectory();
      final directory = Directory(targetDir);

      if (directory.existsSync()) {
        await directory.delete(recursive: true);
        debugPrint('[MonacoAssetManager] Cache cleared successfully');
      }

      _updateStatus(MonacoAssetStatus(
        state: MonacoAssetState.idle,
        message: 'Cache cleared',
        lastUpdate: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('[MonacoAssetManager] Error clearing cache: $e');
    }
  }

  /// Update status through Riverpod
  void _updateStatus(MonacoAssetStatus status) {
    _ref.read(monacoAssetStatusProvider.notifier).updateStatus(status);
  }

  /// Get current asset path (null if not ready)
  String? get assetPath => _cachedAssetPath;

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
    _initCompleter = null;
  }
}

/// Riverpod notifier for Monaco asset status
class MonacoAssetStatusNotifier extends StateNotifier<MonacoAssetStatus> {
  MonacoAssetStatusNotifier()
      : super(const MonacoAssetStatus(state: MonacoAssetState.idle));

  void updateStatus(MonacoAssetStatus status) {
    state = status;
    debugPrint('[MonacoAssetStatusNotifier] Status updated: $status');
  }

  void reset() {
    state = const MonacoAssetStatus(state: MonacoAssetState.idle);
  }
}

/// Riverpod providers for Monaco asset management
final monacoAssetStatusProvider =
    StateNotifierProvider<MonacoAssetStatusNotifier, MonacoAssetStatus>((ref) {
  return MonacoAssetStatusNotifier();
});

final monacoAssetManagerProvider = Provider<MonacoAssetManager>((ref) {
  final manager = MonacoAssetManager(ref);
  ref.onDispose(manager.dispose);
  return manager;
});

/// Convenient provider for checking if assets are ready
final monacoAssetsReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(monacoAssetStatusProvider);
  return status.isReady;
});

/// Provider for getting the asset path when ready
final monacoAssetPathProvider = Provider<String?>((ref) {
  final status = ref.watch(monacoAssetStatusProvider);
  return status.isReady ? status.assetPath : null;
});

/// Extension methods for easier usage
extension MonacoAssetManagerX on MonacoAssetManager {
  /// Wait for assets to be ready with timeout
  Future<String> waitForAssets({Duration? timeout}) async {
    final completer = Completer<String>();
    Timer? timeoutTimer;
    ProviderSubscription? subscription;

    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException(
              'Monaco assets not ready within timeout', timeout));
        }
      });
    }

    // Listen for status changes
    subscription = _ref.listen<MonacoAssetStatus>(
      monacoAssetStatusProvider,
      (previous, next) {
        if (next.isReady && !completer.isCompleted) {
          completer.complete(next.assetPath!);
        } else if (next.hasError && !completer.isCompleted) {
          completer.completeError(Exception(next.error));
        }
      },
    );

    // Check current state
    final currentStatus = _ref.read(monacoAssetStatusProvider);
    if (currentStatus.isReady) {
      completer.complete(currentStatus.assetPath!);
    } else if (currentStatus.hasError) {
      completer.completeError(Exception(currentStatus.error));
    }

    try {
      final result = await completer.future;
      return result;
    } finally {
      timeoutTimer?.cancel();
      subscription.close();
    }
  }
}
