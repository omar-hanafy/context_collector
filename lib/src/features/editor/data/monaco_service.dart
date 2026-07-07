import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/modal_overlay_coordinator.dart';
import 'settings_service.dart';

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

  Widget get webviewWidget {
    if (_controller == null || !state.isReady) {
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

      await _controller!.whenReady;

      // Apply queued content if any (language first; then sticky commit)
      if (_queuedContent != null) {
        final epoch = ++_setEpoch;
        final lang = _safeLangFromId(_queuedLanguage);
        if (lang != null) {
          await _controller!.document.setLanguage(lang);
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
        await _controller!.document.setText(_queuedContent!);
        unawaited(_stickValue(_queuedContent!, epoch, retries: 8));
        _queuedContent = null;
        _queuedLanguage = null;
      }

      state = state.copyWith(
        lifecycle: EditorLifecycle.ready,
        message: 'Editor is ready',
      );

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
      _controller?.dispose();
      _controller = null;
      _initCompleter?.completeError(e, st);
      _initCompleter = null;
    } finally {
      // Allow re-init only after a full dispose or explicit error handling
      // Keep the completer for awaiting callers but don't reset lifecycle here.
    }
  }

  Future<void> updateContent(String content, {String? language}) async {
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
    _platformViewFocus.dispose();
    _controller?.dispose();
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
  });

  final EditorLifecycle lifecycle;
  final String message;
  final String? error;
  final bool hasContent;

  EditorStatus copyWith({
    EditorLifecycle? lifecycle,
    String? message,
    String? error,
    bool? hasContent,
  }) {
    return EditorStatus(
      lifecycle: lifecycle ?? this.lifecycle,
      message: message ?? this.message,
      error: error ?? this.error,
      hasContent: hasContent ?? this.hasContent,
    );
  }

  bool get isReady => lifecycle == EditorLifecycle.ready;

  bool get isLoading => !isReady && lifecycle != EditorLifecycle.error;

  bool get hasError => lifecycle == EditorLifecycle.error;
}
