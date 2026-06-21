import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  TargetPlatform? platform,
}) {
  final targetPlatform = platform ?? defaultTargetPlatform;
  if (!editorPointerMayClaimKeyboard(event)) return null;
  // Context Collector renders the package controller's raw WebView so it must
  // keep the same pointer-entry gate that MonacoEditor uses around it:
  // macOS user clicks always re-run input readiness recovery, while Windows
  // avoids replaying focus when both focus signals are already current.
  if (targetPlatform == TargetPlatform.macOS) return MonacoFocusIntent.user;
  if (!editorHasFlutterFocus || !editorReportsFocused) {
    return MonacoFocusIntent.user;
  }
  return null;
}

/// Simplified Monaco service using the flutter_monaco package
class MonacoService extends StateNotifier<EditorStatus> {
  MonacoService()
    : super(const EditorStatus(lifecycle: EditorLifecycle.initial));

  MonacoController? _controller;
  String? _queuedContent;
  String? _queuedLanguage;

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
  StreamSubscription<void>? _focusSub;
  StreamSubscription<void>? _blurSub;

  // Ensures only the latest updateContent() call wins.
  int _setEpoch = 0;

  MonacoLanguage? _safeLangFromId(String? id) {
    if (id == null) return null;
    try {
      return MonacoLanguage.fromId(id);
    } catch (_) {
      return null;
    }
  }

  /// Re-verify and re-apply value across frames; abort if a newer write arrived.
  Future<void> _stickValue(String content, int epoch, {int retries = 3}) async {
    for (var i = 0; i < retries; i++) {
      // Let any late init/model swap finish.
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (epoch != _setEpoch || _controller == null || !state.isReady) return;
      try {
        final got = await _controller!.getValue();
        if (got == content) return; // content held
      } catch (_) {}
      try {
        await _controller!.setValue(content);
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
          platform: defaultTargetPlatform,
        );
        if (intent == null) {
          return;
        }
        _platformViewFocus.requestFocus();
        unawaited(
          ensureEditorFocus(
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

      // Create controller with settings
      _controller = await MonacoController.create(
        options: options,
      );

      // Track Monaco's own focus state so a pointer-down only re-asserts focus
      // when the editor actually needs it (see editorPointerFocusIntent).
      _focusSub = _controller!.onFocus.listen((_) {
        _editorReportsFocused = true;
      });
      _blurSub = _controller!.onBlur.listen((_) {
        _editorReportsFocused = false;
      });

      // Apply queued content if any (language first; then sticky commit)
      if (_queuedContent != null) {
        final epoch = ++_setEpoch;
        final lang = _safeLangFromId(_queuedLanguage);
        if (lang != null) {
          try {
            await _controller!.setLanguage(lang);
          } catch (_) {}
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
        try {
          await _controller!.setValue(_queuedContent!);
        } catch (_) {}
        unawaited(_stickValue(_queuedContent!, epoch, retries: 8));
        _queuedContent = null;
        _queuedLanguage = null;
      }

      state = state.copyWith(
        lifecycle: EditorLifecycle.ready,
        message: 'Editor is ready',
      );

      debugPrint('[MonacoService] Initialization successful');
      // Nudge both platform and DOM focus now that we're ready.
      unawaited(ensureEditorFocus(attempts: 3));
      _initCompleter?.complete();
    } catch (e, st) {
      state = state.copyWith(
        lifecycle: EditorLifecycle.error,
        error: e.toString(),
      );
      debugPrint('[MonacoService] Error: $e\n$st');
      _initCompleter?.completeError(e, st);
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
      try {
        await _controller!.setLanguage(lang);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    String? current;
    try {
      current = await _controller!.getValue();
    } catch (_) {}
    if (current == content) {
      if (mounted && state.hasContent != content.isNotEmpty) {
        state = state.copyWith(hasContent: content.isNotEmpty);
      }
      return;
    }

    final epoch = ++_setEpoch;
    try {
      await _controller!.setValue(content);
    } catch (_) {}

    await ensureNativeFocus();
    // Ensure the hidden textarea owns DOM focus after updates.
    unawaited(ensureEditorFocus(attempts: 3));
    unawaited(_stickValue(content, epoch, retries: 8));

    if (mounted) {
      state = state.copyWith(hasContent: content.isNotEmpty);
    }
  }

  Future<void> updateOptions(EditorOptions options) async {
    if (_controller == null || !state.isReady) return;

    String? before;
    try {
      before = await _controller!.getValue();
    } catch (_) {}

    await _controller!.updateOptions(options);
    await _controller!.setTheme(options.theme);

    if (before != null) {
      try {
        await _controller!.setValue(before);
      } catch (_) {}
    }

    // Re-layout and re-focus after option changes (theme/font/etc.).
    await layout();
    await ensureEditorFocus(attempts: 2);
  }

  @override
  void dispose() {
    _focusSub?.cancel();
    _blurSub?.cancel();
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
  /// the keyboard, and every focus path in this service stands down,
  /// including [recoverKeyboardFocus]: its unfocus-first behavior is exactly
  /// how open dialogs lost their keyboard to Monaco on Windows, where
  /// focusing Monaco moves real Win32 focus into the WebView.
  ///
  /// This is an allow-list by intent: maintenance work (content sync, option
  /// changes, route/lifecycle recovery) can only KEEP focus the editor
  /// already owns, never claim it from another surface. Clicking the editor
  /// requests [_platformViewFocus] before nudging, so user-driven focus
  /// passes; the yield at each call site lets that request settle first.
  bool _editorOwnsKeyboard() => editorMayClaimKeyboard(
    FocusManager.instance.primaryFocus,
    _platformViewFocus,
  );

  Future<void> _ensureFlutterPlatformFocus() async {
    if (_platformViewFocus.canRequestFocus) {
      _platformViewFocus.requestFocus();
    }
    await Future<void>.delayed(Duration.zero);
  }

  /// Ensures the native WebView grabs platform focus (first responder),
  /// then the JS Monaco instance can accept keyboard input.
  ///
  /// Stands down unless the editor already owns the keyboard (or nobody
  /// does); see [_editorOwnsKeyboard].
  Future<void> ensureNativeFocus() async {
    if (_controller == null || !state.isReady) return;
    // Let a focus request from this same event (e.g. the editor's own
    // pointer-down handler) apply before deciding ownership.
    await Future<void>.delayed(Duration.zero);
    if (!_editorOwnsKeyboard()) return;
    // Ask Flutter to focus the platform view's FocusNode.
    await _ensureFlutterPlatformFocus();
    // Also nudge the native view to become first responder.
    try {
      await _controller!.focus();
    } catch (_) {}
    // Allow a full frame for focus to settle through both layers.
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  /// Ensures the Monaco DOM input area gets focus reliably.
  /// Uses the controller's robust helper with layout + retries.
  ///
  /// Stands down unless the editor already owns the keyboard (or nobody
  /// does); see [_editorOwnsKeyboard].
  Future<void> ensureEditorFocus({
    int attempts = 3,
    MonacoFocusIntent intent = MonacoFocusIntent.maintenance,
  }) async {
    if (_controller == null || !state.isReady) return;
    await Future<void>.delayed(Duration.zero);
    if (intent == MonacoFocusIntent.maintenance && !_editorOwnsKeyboard()) {
      return;
    }
    await _ensureFlutterPlatformFocus();
    try {
      await _controller!.ensureEditorFocus(
        attempts: attempts,
        intent: intent,
      );
    } catch (_) {
      // Fallback for older builds: best-effort focus.
      try {
        await _controller!.focus();
      } catch (_) {}
    }
  }

  /// Explicitly triggers Monaco layout (useful after resizes or panel changes).
  Future<void> layout() async {
    if (_controller == null || !state.isReady) return;
    try {
      await _controller!.layout();
    } catch (_) {}
  }

  /// Stronger focus recovery used after dialogs with TextFields close.
  /// Releases Flutter's TextInput client, then reacquires platform + DOM focus.
  ///
  /// This is the intentional editor-return path (route popped back to the
  /// editor, tab/session activation, window re-activation). It refuses to
  /// run while another surface owns the keyboard: it is wired to events that
  /// also fire with popups still open (any route popping, every window
  /// activation), and unfocusing a live dialog's TextField to claim Win32
  /// focus for Monaco was the focus-stealing bug on Windows.
  Future<void> recoverKeyboardFocus({int attempts = 6}) async {
    if (_controller == null || !state.isReady) return;
    await Future<void>.delayed(Duration.zero);
    if (!_editorOwnsKeyboard()) return;
    try {
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (_) {}
    try {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    } catch (_) {}
    // Let the dialog's focus scope tear down.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await ensureNativeFocus();
    try {
      await _controller!.ensureEditorFocus(
        attempts: attempts,
        intent: MonacoFocusIntent.maintenance,
      );
    } catch (_) {
      try {
        await _controller!.focus();
      } catch (_) {}
    }
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
