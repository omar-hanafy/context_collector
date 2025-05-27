// lib/src/features/editor/services/monaco_editor_service.dart
import 'dart:async';

import 'package:context_collector/src/features/editor/services/monaco_editor_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bridge/monaco_bridge_platform.dart';
import '../domain/editor_settings.dart';
import 'monaco_editor_state.dart';

/// Global Monaco Editor Service
/// Manages a single instance of Monaco Editor throughout the app lifecycle
class MonacoEditorService {
  MonacoEditorService(this._ref) {
    _bridge = MonacoBridgePlatform();
    _config = const MonacoEditorConfig(showInitContent: false);
  }

  final Ref _ref;
  late final MonacoBridgePlatform _bridge;
  late final MonacoEditorConfig _config;

  Completer<void>? _initCompleter;
  Timer? _retryTimer;
  StreamSubscription? _assetStatusSubscription;

  // Content management
  String? _currentContent;
  String? _queuedContent;
  bool _isContentUpdatePending = false;


  /// Get the bridge instance (for UI components)
  MonacoBridgePlatform get bridge => _bridge;

  /// Get current editor content
  String? get currentContent => _currentContent;

  /// Initialize the editor service
  /// This should be called once at app startup after assets are ready
  Future<void> initialize() async {
    debugPrint('[MonacoEditorService] Starting initialization');

    // Check current state
    final currentStatus = _ref.read(monacoEditorStatusProvider);
    if (currentStatus.state != MonacoEditorServiceState.idle) {
      debugPrint('[MonacoEditorService] Already initialized or initializing: ${currentStatus.state}');
      return;
    }

    // Prevent multiple initializations
    if (_initCompleter != null) {
      debugPrint('[MonacoEditorService] Already initializing, waiting...');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      // Update state to trigger UI creation
      _updateStatus(MonacoEditorStatus(
        state: MonacoEditorServiceState.initializing,
        progress: 0.1,
        message: 'Initializing Monaco Editor...',
        lastUpdate: DateTime.now(),
      ));

      // Mark as loading - this will trigger the UI to create the WebView
      _updateStatus(MonacoEditorStatus(
        state: MonacoEditorServiceState.loading,
        progress: 0.5,
        message: 'Loading Monaco Editor...',
        lastUpdate: DateTime.now(),
      ));

      // The actual readiness will be signaled by the UI component
      // via markEditorReady()
    } catch (e) {
      await _handleInitializationError(e);
    }
  }

  /// Called by the UI when the editor WebView is ready
  void markEditorReady() {
    debugPrint('[MonacoEditorService] Editor marked as ready');



    _updateStatus(MonacoEditorStatus(
      state: MonacoEditorServiceState.ready,
      progress: 1.0,
      message: 'Monaco Editor ready',
      isVisible: true, // Always visible in layered architecture
      hasContent: _currentContent != null || _config.showInitContent,
      lastUpdate: DateTime.now(),
    ));

    // Complete initialization
    _initCompleter?.complete();
    _initCompleter = null;

    // Set initial content if configured
    if (_config.showInitContent && _currentContent == null && _queuedContent == null) {
      Future.microtask(() async {
        await _bridge.setContent(_config.initContent);
        await _bridge.setLanguage(_config.initLanguage);
      });
    }

    // Process any queued content
    if (_queuedContent != null) {
      debugPrint('[MonacoEditorService] Processing queued content');
      final content = _queuedContent!;
      _queuedContent = null;
      setContent(content);
    }
  }

  /// Set editor content
  Future<void> setContent(String content) async {
    debugPrint(
        '[MonacoEditorService] Setting content (length: ${content.length})');

    _currentContent = content;
    final status = _ref.read(monacoEditorStatusProvider);

    // If not ready, queue the content
    if (!status.isReady) {
      debugPrint('[MonacoEditorService] Editor not ready, queueing content');
      _queuedContent = content;
      _updateStatus(status.copyWith(
        queuedContent: content,
        hasContent: true,
      ));
      return;
    }

    // Prevent concurrent updates
    if (_isContentUpdatePending) {
      _queuedContent = content;
      return;
    }

    _isContentUpdatePending = true;

    try {
      await _bridge.setContent(content);

      _updateStatus(status.copyWith(
        hasContent: content.isNotEmpty,
        queuedContent: null,
      ));

      // Process any content that was queued during update
      if (_queuedContent != null) {
        final nextContent = _queuedContent!;
        _queuedContent = null;
        await setContent(nextContent);
      }
    } finally {
      _isContentUpdatePending = false;
    }
  }

  /// Clear editor content
  Future<void> clearContent() async {
    debugPrint('[MonacoEditorService] Clearing content');

    // Set back to init content if configured
    if (_config.showInitContent) {
      await setContent(_config.initContent);
      await _bridge.setLanguage(_config.initLanguage);
    } else {
      await setContent('');
    }

    _currentContent = null;
  }

  /// Show the editor (no longer needed with layered architecture)
  @Deprecated('Editor visibility is now managed by overlay')
  void show() {
    debugPrint('[MonacoEditorService] Show requested (deprecated)');
    // No-op: visibility is now controlled by the overlay
  }

  /// Hide the editor (no longer needed with layered architecture)
  @Deprecated('Editor visibility is now managed by overlay')
  void hide() {
    debugPrint('[MonacoEditorService] Hide requested (deprecated)');
    // No-op: visibility is now controlled by the overlay
  }

  /// Apply editor settings
  Future<void> applySettings(EditorSettings settings) async {
    final status = _ref.read(monacoEditorStatusProvider);
    if (status.isReady) {
      await _bridge.updateSettings(settings);
      await _bridge.applyKeybindingPreset(settings.keybindingPreset);

      if (settings.customKeybindings.isNotEmpty) {
        await _bridge.setupKeybindings(settings.customKeybindings);
      }
    }
  }

  /// Retry initialization after error
  Future<void> retryInitialization() async {
    debugPrint('[MonacoEditorService] Manual retry requested');

    _retryTimer?.cancel();
    _initCompleter = null;

    await initialize();
  }

  /// Get current status
  MonacoEditorStatus get status => _ref.read(monacoEditorStatusProvider);

  /// Get live stats from the editor
  ValueNotifier<Map<String, int>> get liveStats => _bridge.liveStats;

  // Private methods

  void _updateStatus(MonacoEditorStatus status) {
    _ref.read(monacoEditorStatusProvider.notifier).updateStatus(status);
  }

  Future<void> _handleInitializationError(dynamic error) async {
    final currentStatus = _ref.read(monacoEditorStatusProvider);
    final newRetryCount = currentStatus.retryCount + 1;

    debugPrint(
        '[MonacoEditorService] Initialization error (attempt $newRetryCount): $error');

    if (newRetryCount >= _config.maxRetries) {
      _updateStatus(MonacoEditorStatus(
        state: MonacoEditorServiceState.error,
        error:
            'Failed to initialize Monaco Editor after ${_config.maxRetries} attempts: $error',
        retryCount: newRetryCount,
        lastUpdate: DateTime.now(),
      ));

      _initCompleter?.completeError(error.toString());
      _initCompleter = null;
      return;
    }

    // Calculate retry delay with exponential backoff
    final retryDelay = _config.retryDelay * newRetryCount;

    _updateStatus(MonacoEditorStatus(
      state: MonacoEditorServiceState.retrying,
      message:
          'Retrying in ${retryDelay.inSeconds} seconds (attempt $newRetryCount/${_config.maxRetries})...',
      error: error.toString(),
      retryCount: newRetryCount,
      lastUpdate: DateTime.now(),
    ));

    _retryTimer = Timer(retryDelay, () {
      debugPrint(
          '[MonacoEditorService] Retrying initialization (attempt $newRetryCount)');
      initialize();
    });
  }

  /// Dispose of resources
  void dispose() {
    debugPrint('[MonacoEditorService] Disposing');
    _retryTimer?.cancel();
    _assetStatusSubscription?.cancel();
    _bridge.dispose();
  }
}

/// State notifier for Monaco editor status
class MonacoEditorStatusNotifier extends StateNotifier<MonacoEditorStatus> {
  MonacoEditorStatusNotifier()
      : super(const MonacoEditorStatus(state: MonacoEditorServiceState.idle));

  void updateStatus(MonacoEditorStatus status) {
    state = status;
    debugPrint('[MonacoEditorStatusNotifier] Status updated: $status');
  }

  void reset() {
    state = const MonacoEditorStatus(state: MonacoEditorServiceState.idle);
  }
}
