import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/modal_overlay_coordinator.dart';
import 'settings_service.dart';

@visibleForTesting
Uri monacoDocumentUriForFileId(String fileId) {
  return Uri(
    scheme: 'context-collector',
    host: 'file',
    pathSegments: <String>[fileId],
  );
}

final Uri _viewAllDocumentUri = Uri(
  scheme: 'context-collector',
  host: 'preview',
  pathSegments: const <String>['view-all'],
);

/// Whether the Monaco editor may claim the OS keyboard, given Flutter's
/// current [primary] focus and the editor's own [platformView] focus node.
///
/// This is the single gate every focus path in [MonacoService] passes
/// through, so background maintenance (content sync, option changes,
/// route/lifecycle recovery) can only ever KEEP focus the editor already
/// owns - never claim it from a dialog's `TextField`, a button, a menu, or
/// another route. On Windows, claiming focus moves real Win32 keyboard focus
/// into the WebView, so an unguarded nudge silently steals typing from an
/// open popup; this makes that impossible regardless of which path nudges.
///
/// Returns true only when the keyboard is genuinely unclaimed:
/// - nothing is focused ([primary] is null),
/// - the editor's own platform view owns focus, or
/// - focus rests on a [FocusScopeNode] that the editor lives under (an idle
///   route scope with no concrete child focused), or the editor is not yet
///   mounted (startup, [platformView] has no context).
///
/// A dialog's scope is a sibling overlay entry, not an ancestor of the
/// editor's node, so it correctly reads as foreign and the editor stands
/// down.
@visibleForTesting
bool editorMayClaimKeyboard(FocusNode? primary, FocusNode platformView) {
  if (primary == null) return true;
  if (primary == platformView) return true;
  if (primary is FocusScopeNode) {
    // Editor not mounted yet (startup): an idle scope means nobody has
    // claimed the keyboard.
    if (platformView.context == null) return true;
    // A bare scope claims nothing itself, but a foreign scope (a dialog's)
    // is about to focus its own child - only scopes the editor itself lives
    // under count as idle.
    return platformView.ancestors.contains(primary);
  }
  return false;
}

@visibleForTesting
bool editorPointerMayClaimKeyboard(PointerDownEvent event) {
  if (event.kind == PointerDeviceKind.mouse ||
      event.kind == PointerDeviceKind.trackpad) {
    return event.buttons == kPrimaryMouseButton;
  }
  return true;
}

@visibleForTesting
MonacoFocusIntent? editorPointerFocusIntent(
  PointerDownEvent event, {
  required bool editorHasFlutterFocus,
  required bool editorReportsFocused,
  required bool nativeInputReadinessStale,
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  // Web: the browser owns click-to-focus entirely. Pointer events over the
  // Monaco iframe dispatch inside the iframe's document and never reach this
  // Flutter Listener at all (browser DOM hit-testing runs before Flutter's),
  // so no Flutter-side focus work belongs to a web click. Without this
  // branch, web-on-macOS would fall into the host-OS macOS branch below by
  // accident (defaultTargetPlatform reports the host OS on web).
  if (isWeb) return null;
  final targetPlatform = platform ?? defaultTargetPlatform;
  if (!editorPointerMayClaimKeyboard(event)) return null;
  // Context Collector renders the package controller's raw WebView so it must
  // keep the same pointer-entry gate that MonacoEditor uses around it:
  // a stale native-input boundary always re-runs user recovery, macOS user
  // clicks always re-run input readiness recovery, and Windows avoids replaying
  // focus only when both focus signals are already current and fresh.
  if (nativeInputReadinessStale) return MonacoFocusIntent.user;
  if (targetPlatform == TargetPlatform.macOS) return MonacoFocusIntent.user;
  if (!editorHasFlutterFocus || !editorReportsFocused) {
    return MonacoFocusIntent.user;
  }
  return null;
}

enum MonacoInputReadiness {
  noEditorTarget,
  foreignKeyboardOwner,
  ready,
  stale,
}

@visibleForTesting
MonacoInputReadiness editorInputReadinessForFocusSignals({
  required bool editorMayClaimKeyboard,
  required bool editorWasLastKeyboardTarget,
  required bool editorHasFlutterFocus,
  required bool editorReportsFocused,
  required bool nativeInputReadinessStale,
}) {
  if (!editorMayClaimKeyboard) {
    return MonacoInputReadiness.foreignKeyboardOwner;
  }

  final editorIsFocusTarget =
      editorWasLastKeyboardTarget ||
      editorHasFlutterFocus ||
      editorReportsFocused;
  if (!editorIsFocusTarget) {
    return MonacoInputReadiness.noEditorTarget;
  }

  if (nativeInputReadinessStale) {
    return MonacoInputReadiness.stale;
  }

  return MonacoInputReadiness.ready;
}

MonacoFocusIntent editorInputReadinessFocusIntent(
  MonacoInputReadiness readiness,
) {
  return readiness == MonacoInputReadiness.stale
      ? MonacoFocusIntent.user
      : MonacoFocusIntent.maintenance;
}

@visibleForTesting
bool editorTracksNativeInputReadinessStaleness({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return false;
  return switch (platform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => false,
  };
}

/// Simplified Monaco service using the flutter_monaco package
class MonacoService extends StateNotifier<EditorStatus> {
  MonacoService({this._overlayCoordinator})
    : super(const EditorStatus(lifecycle: EditorLifecycle.initial)) {
    _overlayCoordinator?.addListener(_onOverlayDepthChanged);
  }

  MonacoController? _controller;
  String? _queuedContent;
  String? _queuedLanguage;
  String? _queuedFileDocumentId;
  bool _queuedViewAllDocument = false;
  final Map<String, _MonacoDocumentEntry> _fileDocuments = {};
  final Map<String, Future<_MonacoDocumentEntry>> _openingFileDocuments = {};
  _MonacoDocumentEntry? _viewAllDocument;
  Future<_MonacoDocumentEntry>? _openingViewAllDocument;
  String? _activeFileDocumentId;

  // App-wide floating-overlay tracking (dialogs, menus, sheets on any
  // navigator). On web the editor iframe must go pointer- and keyboard-inert
  // while one is open, or the overlay is visible but unreachable (browser DOM
  // hit-testing runs before Flutter's - see ModalOverlayCoordinator).
  final ModalOverlayCoordinator? _overlayCoordinator;
  bool _overlayLockApplied = false;

  // Ensures Flutter gives keyboard focus to the platform view (WebView)
  final FocusNode _platformViewFocus = FocusNode(
    debugLabel: 'MonacoPlatformView',
  );
  Completer<void>? _initCompleter;

  // Tracks whether Monaco itself reports the editor focused (its input can
  // receive keystrokes), driven by the controller's focus/blur stream. Lets a
  // pointer-down tell "already focused, leave it alone" apart from "Flutter
  // thinks it's focused but Monaco lost it" (the alt-tab/dialog desync), so the
  // latter still re-asserts focus on click. See editorPointerFocusIntent.
  bool _editorReportsFocused = false;
  bool _editorWasLastKeyboardTarget = false;
  bool _nativeInputReadinessStale = false;
  bool _visibleForKeyboardInput = true;
  StreamSubscription<bool>? _focusSub;
  StreamSubscription<void>? _reloadSub;

  // Ensures only the latest updateContent() call wins.
  int _setEpoch = 0;

  MonacoLanguage? _safeLangFromId(String? id) {
    if (id == null) return null;
    final trimmed = id.trim();
    return trimmed.isEmpty ? null : MonacoLanguage(trimmed);
  }

  /// Re-verify and re-apply value across frames; abort if a newer write arrived.
  Future<void> _stickValue(String content, int epoch, {int retries = 3}) async {
    for (var i = 0; i < retries; i++) {
      // Let any late init/model swap finish.
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (epoch != _setEpoch || _controller == null || !state.isReady) return;
      try {
        final got = await _controller!.document.getText();
        if (got == content) return; // content held
      } catch (_) {}
      try {
        await _controller!.document.setText(content);
      } catch (_) {}
    }
  }

  MonacoController? get controller => _controller;

  /// The embeddable editor view.
  ///
  /// Available as soon as the controller exists - BEFORE readiness. On web
  /// the editor iframe only loads while this widget is mounted and painted,
  /// so initialize() can only finish if the UI keeps it in the tree
  /// (underneath the opaque loading overlay) for the whole boot. Gating it
  /// on `state.isReady` deadlocks the web boot into a silent timeout.
  Widget get webviewWidget {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Ensure platform focus on pointer down, then DOM focus via controller.
    return Listener(
      // Important on macOS: don't claim the primary click; let WKWebView win it.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final intent = editorPointerFocusIntent(
          event,
          editorHasFlutterFocus: _platformViewFocus.hasFocus,
          editorReportsFocused: _editorReportsFocused,
          nativeInputReadinessStale: _nativeInputReadinessStale,
          platform: defaultTargetPlatform,
        );
        if (intent == null) {
          return;
        }
        _editorWasLastKeyboardTarget = true;
        unawaited(
          requestEditorFocus(
            attempts: 1,
            intent: intent,
          ),
        );
      },
      child: Focus(
        focusNode: _platformViewFocus,
        canRequestFocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }

          final hardware = HardwareKeyboard.instance;
          final isMac = defaultTargetPlatform == TargetPlatform.macOS;
          final primaryDown = isMac
              ? hardware.isMetaPressed
              : hardware.isControlPressed;
          if (!isMac && primaryDown) {
            final LogicalKeyboardKey key = event.logicalKey;
            const editCombos = <LogicalKeyboardKey>[
              LogicalKeyboardKey.keyC,
              LogicalKeyboardKey.keyV,
              LogicalKeyboardKey.keyX,
              LogicalKeyboardKey.keyA,
              LogicalKeyboardKey.keyZ,
            ];
            if (editCombos.contains(key)) {
              return KeyEventResult.skipRemainingHandlers;
            }
          }
          final hasModifier =
              primaryDown || hardware.isAltPressed || hardware.isShiftPressed;

          // Let shortcut combos bubble up to GlobalHotkeys / native menus.
          if (hasModifier) {
            return KeyEventResult.ignored;
          }

          // Plain typing keys should still be captured by the WebView.
          return KeyEventResult.skipRemainingHandlers;
        },
        descendantsAreFocusable: true,
        child: _controller!.webViewWidget,
      ),
    );
  }

  Future<void> initialize() async {
    // Make initialization idempotent and guard against concurrent callers.
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    if (state.lifecycle != EditorLifecycle.initial &&
        state.lifecycle != EditorLifecycle.error) {
      return;
    }
    _initCompleter = Completer<void>();

    debugPrint('[MonacoService] Initializing with flutter_monaco package...');

    try {
      // Load saved settings
      final options = await EditorSettingsService.load();

      // Entering (or re-entering via Retry) flips the UI back to the loading
      // panel; without this the error chrome stays frozen on screen for the
      // whole boot and Retry looks dead. Emitted after the first await:
      // initialize() is invoked from widget mount paths, and a synchronous
      // emission there would modify the provider mid-build.
      state = state.copyWith(
        lifecycle: EditorLifecycle.initial,
        message: 'Initializing...',
      );
      final queuedLanguage = _safeLangFromId(_queuedLanguage);
      final bootOptions = queuedLanguage == null
          ? options
          : options.copyWith(language: queuedLanguage);

      // Create controller with settings. v3 create returns before the page is
      // ready, so state is not promoted until whenReady completes below.
      _controller = await MonacoController.create(
        options: bootOptions,
        initialText: _queuedContent,
      );

      // Track Monaco's own focus state so a pointer-down only re-asserts focus
      // when the editor actually needs it (see editorPointerFocusIntent).
      _focusSub = _controller!.onFocusChanged.listen((focused) {
        _editorReportsFocused = focused;
        if (focused) {
          _editorWasLastKeyboardTarget = true;
        } else if (!_editorOwnsKeyboard()) {
          _editorWasLastKeyboardTarget = false;
        }
      });

      // The page document can reload under us (Flutter web re-inserts the
      // iframe during platform-view churn; a native WebView process can
      // recover). The package re-boots the editor and re-registers its own
      // state before this fires; the service then drops its dead document
      // handles, restores the CURRENT settings, and bumps
      // EditorStatus.reloadCount so EditorScreen re-drives content.
      _reloadSub = _controller!.onPageReloaded.listen(
        (_) => unawaited(_onEditorPageReloaded()),
        onError: (Object error, StackTrace stackTrace) {
          unawaited(_onEditorReloadRecoveryFailed(error, stackTrace));
        },
      );

      // Publish the controller before awaiting readiness: the UI mounts
      // webviewWidget in response to this emission, and on web the page can
      // only load - so whenReady can only complete - while that platform
      // view is painted in the tree.
      state = state.copyWith(message: 'Starting the editor page...');

      await _controller!.whenReady;

      state = state.copyWith(
        lifecycle: EditorLifecycle.ready,
        message: 'Editor is ready',
      );

      await _replayQueuedDocumentActivation();

      debugPrint('[MonacoService] Initialization successful');
      // An overlay may already be open while the editor finishes creating
      // (its depth change fired before the controller existed) - apply the
      // current overlay state before any focus nudging.
      await _applyOverlayInteraction();
      // Nudge both platform and DOM focus now that we're ready.
      unawaited(requestEditorFocus(attempts: 3));
      _initCompleter?.complete();
    } catch (e, st) {
      state = state.copyWith(
        lifecycle: EditorLifecycle.error,
        error: e.toString(),
      );
      debugPrint('[MonacoService] Error: $e\n$st');
      await _focusSub?.cancel();
      _focusSub = null;
      await _reloadSub?.cancel();
      _reloadSub = null;
      _controller?.dispose();
      _controller = null;
      _fileDocuments.clear();
      _openingFileDocuments.clear();
      _viewAllDocument = null;
      _openingViewAllDocument = null;
      _activeFileDocumentId = null;
      _initCompleter?.completeError(e, st);
      _initCompleter = null;
    } finally {
      // Allow re-init only after a full dispose or explicit error handling
      // Keep the completer for awaiting callers but don't reset lifecycle here.
    }
  }

  Future<void> updateContent(String content, {String? language}) async {
    _queuedFileDocumentId = null;
    _queuedViewAllDocument = false;
    if (_controller == null || !state.isReady) {
      _queuedContent = content;
      _queuedLanguage = language;
      return;
    }

    // Apply language first (if requested). This does not disturb caret/scroll.
    final lang = _safeLangFromId(language);
    if (lang != null) {
      await _controller!.document.setLanguage(lang);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    String? current;
    try {
      current = await _controller!.document.getText();
    } catch (_) {}
    if (current == content) {
      if (mounted && state.hasContent != content.isNotEmpty) {
        state = state.copyWith(hasContent: content.isNotEmpty);
      }
      return;
    }

    final epoch = ++_setEpoch;
    await _controller!.document.setText(content);

    // Ensure the hidden textarea owns DOM focus after updates.
    unawaited(requestEditorFocus(attempts: 3));
    unawaited(_stickValue(content, epoch, retries: 8));

    if (mounted) {
      state = state.copyWith(hasContent: content.isNotEmpty);
    }
  }

  Future<void> activateFileDocument({
    required String fileId,
    required String text,
    String? language,
  }) async {
    _queuedFileDocumentId = null;
    _queuedViewAllDocument = false;

    final lang = _safeLangFromId(language) ?? MonacoLanguage.plaintext;
    final epoch = ++_setEpoch;
    if (_controller == null || !state.isReady) {
      _queuedFileDocumentId = fileId;
      _queuedContent = text;
      _queuedLanguage = lang.id;
      return;
    }

    final entry = await _ensureFileDocument(fileId, text, lang);
    if (epoch != _setEpoch || _controller == null || !state.isReady) return;

    await _syncDocument(entry, text, lang);
    if (epoch != _setEpoch || _controller == null || !state.isReady) return;

    await _controller!.activateDocument(entry.document);
    _activeFileDocumentId = fileId;

    // Ensure the hidden textarea owns DOM focus after document activation.
    unawaited(requestEditorFocus(attempts: 3));

    if (mounted) {
      state = state.copyWith(hasContent: text.isNotEmpty);
    }
  }

  Future<void> activateViewAllDocument({
    required String text,
    String language = 'markdown',
  }) async {
    _queuedFileDocumentId = null;
    _queuedViewAllDocument = false;

    final lang = _safeLangFromId(language) ?? MonacoLanguage.markdown;
    final epoch = ++_setEpoch;
    if (_controller == null || !state.isReady) {
      _queuedViewAllDocument = true;
      _queuedContent = text;
      _queuedLanguage = lang.id;
      return;
    }

    final entry = await _ensureViewAllDocument(text, lang);
    if (epoch != _setEpoch || _controller == null || !state.isReady) return;

    await _syncDocument(entry, text, lang);
    if (epoch != _setEpoch || _controller == null || !state.isReady) return;

    await _controller!.activateDocument(entry.document);
    _activeFileDocumentId = null;

    unawaited(requestEditorFocus(attempts: 3));

    if (mounted) {
      state = state.copyWith(hasContent: text.isNotEmpty);
    }
  }

  Future<String?> readFileDocumentText(String fileId) async {
    final entry = _fileDocuments[fileId];
    if (entry != null) {
      return entry.document.getText();
    }
    if (_activeFileDocumentId == fileId && _controller != null) {
      return _controller!.document.getText();
    }
    return null;
  }

  Future<void> setActiveDocumentLanguage(MonacoLanguage language) async {
    if (_controller == null || !state.isReady) {
      _queuedLanguage = language.id;
      return;
    }
    await _controller!.document.setLanguage(language);
    final activeFileId = _activeFileDocumentId;
    if (activeFileId != null) {
      _fileDocuments[activeFileId]?.language = language;
    } else {
      _viewAllDocument?.language = language;
    }
  }

  Future<void> closeFileDocumentsExcept(Iterable<String> liveFileIds) async {
    final keep = liveFileIds.toSet();
    final removedIds = _fileDocuments.keys
        .where((fileId) => !keep.contains(fileId))
        .toList(growable: false);
    if (removedIds.isEmpty) return;

    final closing = <Future<void>>[];
    for (final fileId in removedIds) {
      final entry = _fileDocuments.remove(fileId);
      final pending = _openingFileDocuments.remove(fileId);
      if (_activeFileDocumentId == fileId) {
        _activeFileDocumentId = null;
      }
      if (entry != null) {
        closing.add(_closeDocument(entry));
      }
      if (pending != null) {
        closing.add(
          pending
              .then((entry) {
                if (identical(_fileDocuments[fileId], entry)) {
                  _fileDocuments.remove(fileId);
                }
                return _closeDocument(entry);
              })
              .catchError((_) {}),
        );
      }
    }
    await Future.wait(closing);
  }

  Future<void> _closeDocument(_MonacoDocumentEntry entry) async {
    try {
      await entry.document.close();
    } catch (_) {}
  }

  Future<void> _replayQueuedDocumentActivation() async {
    final content = _queuedContent;
    if (content == null) return;

    final fileId = _queuedFileDocumentId;
    final viewAll = _queuedViewAllDocument;
    final language = _queuedLanguage;
    _queuedContent = null;
    _queuedLanguage = null;
    _queuedFileDocumentId = null;
    _queuedViewAllDocument = false;

    if (fileId != null) {
      await activateFileDocument(
        fileId: fileId,
        text: content,
        language: language,
      );
      return;
    }
    if (viewAll) {
      await activateViewAllDocument(text: content, language: language ?? '');
      return;
    }
    await updateContent(content, language: language);
  }

  /// Converges service state after the package recovered from a page
  /// reload (see `MonacoController.onPageReloaded`).
  ///
  /// The reloaded page has none of the old models, so every cached document
  /// entry is dead; the re-boot also replayed the ORIGINAL boot options, so
  /// the currently persisted settings are re-applied. Content restore is
  /// EditorScreen's job (it owns selection state) - it reacts to the
  /// [EditorStatus.reloadCount] bump.
  Future<void> _onEditorPageReloaded() async {
    if (!mounted || _controller == null || !state.isReady) return;

    // Invalidate in-flight sticky writes and dead document handles.
    _setEpoch++;
    _fileDocuments.clear();
    _openingFileDocuments.clear();
    _viewAllDocument = null;
    _openingViewAllDocument = null;
    _activeFileDocumentId = null;

    try {
      final options = await EditorSettingsService.load();
      await updateOptions(options);
    } catch (e) {
      debugPrint('[MonacoService] settings re-apply after reload failed: $e');
    }
    await _applyOverlayInteraction(force: true);

    if (!mounted) return;
    state = state.copyWith(
      reloadCount: state.reloadCount + 1,
      hasContent: false,
      message: 'Editor recovered from a page reload',
    );
  }

  /// The package could not re-boot the reloaded page: the editor is dead.
  ///
  /// Mirrors the initialize() failure path so the error surface renders and
  /// its Retry button can build a fresh controller.
  Future<void> _onEditorReloadRecoveryFailed(
    Object error,
    StackTrace stackTrace,
  ) async {
    debugPrint(
      '[MonacoService] page reload recovery failed: $error\n$stackTrace',
    );
    if (!mounted) return;
    state = state.copyWith(
      lifecycle: EditorLifecycle.error,
      error: 'The editor page reloaded and could not recover: $error',
    );
    await _focusSub?.cancel();
    _focusSub = null;
    await _reloadSub?.cancel();
    _reloadSub = null;
    _controller?.dispose();
    _controller = null;
    _fileDocuments.clear();
    _openingFileDocuments.clear();
    _viewAllDocument = null;
    _openingViewAllDocument = null;
    _activeFileDocumentId = null;
    // Allow initialize() to run again from the Retry button.
    _initCompleter = null;
  }

  Future<_MonacoDocumentEntry> _ensureFileDocument(
    String fileId,
    String text,
    MonacoLanguage language,
  ) {
    final existing = _fileDocuments[fileId];
    if (existing != null) return Future.value(existing);

    final pending = _openingFileDocuments[fileId];
    if (pending != null) return pending;

    final future = () async {
      final uri = monacoDocumentUriForFileId(fileId);
      final document = await _controller!.openDocument(
        text: text,
        language: language,
        uri: uri,
      );
      final entry = _MonacoDocumentEntry(
        document: document,
        loadedText: text,
        language: language,
      );
      _fileDocuments[fileId] = entry;
      return entry;
    }();

    _openingFileDocuments[fileId] = future;
    return future.whenComplete(() {
      if (identical(_openingFileDocuments[fileId], future)) {
        _openingFileDocuments.remove(fileId);
      }
    });
  }

  Future<_MonacoDocumentEntry> _ensureViewAllDocument(
    String text,
    MonacoLanguage language,
  ) {
    final existing = _viewAllDocument;
    if (existing != null) return Future.value(existing);

    final pending = _openingViewAllDocument;
    if (pending != null) return pending;

    final future = () async {
      final document = await _controller!.openDocument(
        text: text,
        language: language,
        uri: _viewAllDocumentUri,
      );
      final entry = _MonacoDocumentEntry(
        document: document,
        loadedText: text,
        language: language,
      );
      _viewAllDocument = entry;
      return entry;
    }();

    _openingViewAllDocument = future;
    return future.whenComplete(() {
      if (identical(_openingViewAllDocument, future)) {
        _openingViewAllDocument = null;
      }
    });
  }

  Future<void> _syncDocument(
    _MonacoDocumentEntry entry,
    String text,
    MonacoLanguage language,
  ) async {
    if (entry.language?.id != language.id) {
      await entry.document.setLanguage(language);
      entry.language = language;
    }

    if (entry.loadedText == text) return;

    String? liveText;
    try {
      liveText = await entry.document.getText();
    } catch (_) {}

    if (liveText != text) {
      await entry.document.setText(text);
    }
    entry.loadedText = text;
  }

  Future<void> updateOptions(EditorOptions options) async {
    if (_controller == null || !state.isReady) return;

    await _controller!.updateOptions(options);
    final theme = options.theme;
    if (theme != null) {
      await _controller!.setTheme(theme);
    }

    // Re-layout and re-focus after option changes (theme/font/etc.).
    await layout();
    await requestEditorFocus(attempts: 2);
  }

  @override
  void dispose() {
    _overlayCoordinator?.removeListener(_onOverlayDepthChanged);
    _focusSub?.cancel();
    _reloadSub?.cancel();
    _platformViewFocus.dispose();
    _controller?.dispose();
    _fileDocuments.clear();
    _openingFileDocuments.clear();
    _viewAllDocument = null;
    _openingViewAllDocument = null;
    super.dispose();
  }

  /// Whether the editor may take the keyboard right now.
  ///
  /// True only while the keyboard is unclaimed: the editor's own platform
  /// view node owns Flutter focus, or focus rests on a bare scope along the
  /// editor's own route (nothing concrete focused). Any other focused node -
  /// a dialog's TextField, a button, a menu, a foreign route's scope - owns
  /// the keyboard, and maintenance focus paths in this service stand down.
  ///
  /// This is an allow-list by intent: maintenance work (content sync, option
  /// changes, route/lifecycle recovery) can only KEEP focus the editor
  /// already owns, never claim it from another surface. Clicking the editor
  /// goes through [MonacoFocusIntent.user], letting flutter_monaco perform
  /// package-owned input handoff before this wrapper aligns Flutter focus.
  bool _editorOwnsKeyboard() =>
      _visibleForKeyboardInput &&
      editorMayClaimKeyboard(
        FocusManager.instance.primaryFocus,
        _platformViewFocus,
      );

  bool get _tracksNativeInputReadinessStaleness {
    return editorTracksNativeInputReadinessStaleness(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
    );
  }

  bool get _editorIsFocusTargetForRestore {
    return _editorWasLastKeyboardTarget ||
        _platformViewFocus.hasFocus ||
        _editorReportsFocused;
  }

  void setVisibleForKeyboardInput(bool visible) {
    if (_visibleForKeyboardInput == visible) {
      return;
    }

    final editorWasFocusTarget = _editorIsFocusTargetForRestore;
    _visibleForKeyboardInput = visible;

    if (!_tracksNativeInputReadinessStaleness) {
      return;
    }

    if (editorWasFocusTarget) {
      _nativeInputReadinessStale = true;
    }
  }

  void _onOverlayDepthChanged() {
    unawaited(_applyOverlayInteraction());
  }

  /// Keeps the editor's interaction state in sync with floating overlays.
  ///
  /// While any dialog/menu/sheet is open above ANY navigator, the editor is
  /// made inert (`setInteractionEnabled(false)`): on web that applies
  /// `pointer-events: none` to the Monaco iframe AND hands the browser's
  /// document focus back to Flutter, so the overlay receives both clicks and
  /// keys. On native platforms `setInteractionEnabled` is a no-op, so desktop
  /// behavior is unchanged by design (desktop recovery stays click-driven).
  ///
  /// When the last overlay closes, web additionally runs the ownership-gated
  /// maintenance recovery: there is no Flutter pointer path over the iframe
  /// to recover from a click (the browser routes those clicks natively), so
  /// this is the web analog of the desktop didPopNext recovery - and like all
  /// maintenance it stands down if another surface owns the keyboard.
  Future<void> _applyOverlayInteraction({bool force = false}) async {
    final coordinator = _overlayCoordinator;
    final controller = _controller;
    if (coordinator == null || controller == null || !mounted) return;

    final shouldLock = coordinator.anyOverlayOpen;
    if (!force && shouldLock == _overlayLockApplied) return;
    _overlayLockApplied = shouldLock;

    try {
      await controller.setInteractionEnabled(!shouldLock);
    } catch (_) {}

    if (!shouldLock && kIsWeb) {
      // Let the pop finish tearing down the overlay's focus before the
      // ownership gate reads it (mirrors EditorScreen.didPopNext).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Another overlay may have opened during the frame; stay inert then.
        if (_overlayCoordinator?.anyOverlayOpen ?? false) return;
        unawaited(recoverKeyboardFocus());
      });
    }
  }

  /// Runs [action] with the editor inert, for transient overlays that are
  /// not routes (snackbars with action buttons, toasts).
  ///
  /// Prefer this over calling `controller.runWithInteractionDisabled`
  /// directly: that helper restores the interaction state it captured at its
  /// START, which would re-enable the editor even if a dialog opened while
  /// the transient overlay was up. This wrapper re-asserts the overlay
  /// coordinator's current requirement when the action completes.
  Future<T> runWithEditorInteractionDisabled<T>(
    FutureOr<T> Function() action,
  ) async {
    final controller = _controller;
    if (controller == null || !state.isReady) {
      return Future<T>.value(action());
    }
    try {
      return await controller.runWithInteractionDisabled(action);
    } finally {
      await _applyOverlayInteraction(force: true);
    }
  }

  bool _maintenanceMayUseEditorInput() {
    if (!_visibleForKeyboardInput) {
      return false;
    }
    if (!_editorOwnsKeyboard()) {
      _editorWasLastKeyboardTarget = false;
      return false;
    }
    return !_nativeInputReadinessStale;
  }

  MonacoInputReadiness get inputReadinessForFocusRestore {
    return editorInputReadinessForFocusSignals(
      editorMayClaimKeyboard: _editorOwnsKeyboard(),
      editorWasLastKeyboardTarget: _editorWasLastKeyboardTarget,
      editorHasFlutterFocus: _platformViewFocus.hasFocus,
      editorReportsFocused: _editorReportsFocused,
      nativeInputReadinessStale: _nativeInputReadinessStale,
    );
  }

  void invalidateInputReadinessAfterNativeFocusBoundary() {
    if (!_tracksNativeInputReadinessStaleness) {
      return;
    }
    if (!_visibleForKeyboardInput) {
      _nativeInputReadinessStale = _editorIsFocusTargetForRestore;
      return;
    }
    if (!_editorOwnsKeyboard()) {
      _editorWasLastKeyboardTarget = false;
      _nativeInputReadinessStale = false;
      return;
    }
    _nativeInputReadinessStale = _editorIsFocusTargetForRestore;
  }

  Future<void> recoverKeyboardFocusAfterNativeFocusBoundary({
    int attempts = 6,
  }) async {
    await recoverKeyboardFocus(
      attempts: attempts,
      intent: editorInputReadinessFocusIntent(inputReadinessForFocusRestore),
    );
  }

  Future<void> _ensureFlutterPlatformFocus() async {
    if (_platformViewFocus.canRequestFocus) {
      _platformViewFocus.requestFocus();
    }
    await Future<void>.delayed(Duration.zero);
  }

  /// Runs one cooperative v3 focus request.
  ///
  /// Stands down unless the editor already owns the keyboard (or nobody
  /// does); see [_editorOwnsKeyboard].
  Future<void> ensureNativeFocus() async {
    await requestEditorFocus(attempts: 1);
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  /// Ensures the Monaco DOM input area gets focus reliably.
  /// Uses the controller's robust helper with layout + retries.
  ///
  /// Stands down unless the editor already owns the keyboard (or nobody
  /// does); see [_editorOwnsKeyboard].
  Future<void> requestEditorFocus({
    int attempts = 3,
    MonacoFocusIntent intent = MonacoFocusIntent.maintenance,
  }) async {
    if (_controller == null || !state.isReady) return;
    await Future<void>.delayed(Duration.zero);
    if (intent == MonacoFocusIntent.user) {
      _editorWasLastKeyboardTarget = true;
      await _ensureFlutterPlatformFocus();
      await _requestPackageFocus(attempts, intent);
      _nativeInputReadinessStale = false;
      return;
    }
    if (!_maintenanceMayUseEditorInput()) return;
    await _ensureFlutterPlatformFocus();
    await _requestPackageFocus(attempts, intent);
  }

  Future<void> _requestPackageFocus(
    int attempts,
    MonacoFocusIntent intent,
  ) async {
    await _controller!.requestFocus(
      attempts: attempts,
      intent: intent,
    );
  }

  /// Explicitly triggers Monaco layout (useful after resizes or panel changes).
  Future<void> layout() async {
    if (_controller == null || !state.isReady) return;
    try {
      await _controller!.layout();
    } catch (_) {}
  }

  /// Stronger focus recovery used after dialogs with TextFields close.
  ///
  /// This is the intentional editor-return path (route popped back to the
  /// editor, tab/session activation, window re-activation). It refuses to
  /// run while another surface owns the keyboard: it is wired to events that
  /// also fire with popups still open (any route popping, every window
  /// activation). User-initiated handoff is delegated to flutter_monaco via
  /// [MonacoFocusIntent.user], so stale text-input cleanup stays package-owned.
  Future<void> recoverKeyboardFocus({
    int attempts = 6,
    MonacoFocusIntent intent = MonacoFocusIntent.maintenance,
  }) async {
    if (_controller == null || !state.isReady) return;
    await Future<void>.delayed(Duration.zero);
    await requestEditorFocus(attempts: attempts, intent: intent);
  }
}

class _MonacoDocumentEntry {
  _MonacoDocumentEntry({
    required this.document,
    required this.loadedText,
    required this.language,
  });

  final MonacoDocument document;
  String loadedText;
  MonacoLanguage? language;
}

enum EditorLifecycle {
  initial,
  ready,
  error,
}

@immutable
class EditorStatus {
  const EditorStatus({
    this.lifecycle = EditorLifecycle.initial,
    this.message = 'Initializing...',
    this.error,
    this.hasContent = false,
    this.reloadCount = 0,
  });

  final EditorLifecycle lifecycle;
  final String message;
  final String? error;
  final bool hasContent;

  /// Bumped each time the editor page reloaded and recovered (the reloaded
  /// page holds only boot-time content until EditorScreen re-drives the
  /// active selection).
  final int reloadCount;

  EditorStatus copyWith({
    EditorLifecycle? lifecycle,
    String? message,
    String? error,
    bool? hasContent,
    int? reloadCount,
  }) {
    return EditorStatus(
      lifecycle: lifecycle ?? this.lifecycle,
      message: message ?? this.message,
      error: error ?? this.error,
      hasContent: hasContent ?? this.hasContent,
      reloadCount: reloadCount ?? this.reloadCount,
    );
  }

  bool get isReady => lifecycle == EditorLifecycle.ready;

  bool get isLoading => !isReady && lifecycle != EditorLifecycle.error;

  bool get hasError => lifecycle == EditorLifecycle.error;
}
