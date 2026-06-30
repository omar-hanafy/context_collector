import 'dart:async';

import 'package:context_collector/src/features/editor/data/monaco_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locks the single invariant that makes Windows focus-stealing impossible:
/// the Monaco editor may only claim the OS keyboard when nobody else owns it.
/// On Windows, claiming focus moves real Win32 keyboard focus into the
/// WebView, so a maintenance nudge (content sync, option change, route or
/// lifecycle recovery) firing while a popup is open must read "may not
/// claim" and stand down.
void main() {
  group('editorMayClaimKeyboard', () {
    testWidgets('may claim when the editor platform view owns focus', (
      tester,
    ) async {
      final platformView = FocusNode(debugLabel: 'platformView');
      addTearDown(platformView.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Focus(focusNode: platformView, child: const SizedBox.expand()),
        ),
      );
      platformView.requestFocus();
      await tester.pump();

      expect(
        editorMayClaimKeyboard(
          FocusManager.instance.primaryFocus,
          platformView,
        ),
        isTrue,
      );
    });

    testWidgets('may NOT claim while a dialog TextField owns focus', (
      tester,
    ) async {
      final platformView = FocusNode(debugLabel: 'platformView');
      final dialogField = FocusNode(debugLabel: 'dialogField');
      addTearDown(platformView.dispose);
      addTearDown(dialogField.dispose);

      // Editor mounted and focused (the page had the keyboard)...
      late BuildContext homeContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              homeContext = context;
              return Focus(
                focusNode: platformView,
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      platformView.requestFocus();
      await tester.pump();

      // ...then a dialog opens and autofocuses its TextField. This is the
      // exact app shape that stole the keyboard on Windows: a content sync
      // or focus-recovery nudge scheduled around the same time must NOT
      // claim focus.
      unawaited(
        showDialog<void>(
          context: homeContext,
          builder: (_) => Material(
            child: TextField(focusNode: dialogField, autofocus: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(dialogField.hasPrimaryFocus, isTrue);

      expect(
        editorMayClaimKeyboard(
          FocusManager.instance.primaryFocus,
          platformView,
        ),
        isFalse,
      );
    });

    testWidgets('may claim at startup before the editor is mounted', (
      tester,
    ) async {
      // No context yet: nobody has claimed the keyboard, so the first
      // focus on init is allowed.
      final platformView = FocusNode(debugLabel: 'platformView');
      addTearDown(platformView.dispose);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.expand()));

      expect(platformView.context, isNull);
      expect(
        editorMayClaimKeyboard(
          FocusManager.instance.primaryFocus,
          platformView,
        ),
        isTrue,
      );
    });

    test('may claim when nothing is focused', () {
      final platformView = FocusNode(debugLabel: 'platformView');
      addTearDown(platformView.dispose);

      expect(editorMayClaimKeyboard(null, platformView), isTrue);
    });

    testWidgets('may NOT claim while a non-text button owns focus', (
      tester,
    ) async {
      final platformView = FocusNode(debugLabel: 'platformView');
      final buttonFocus = FocusNode(debugLabel: 'button');
      addTearDown(platformView.dispose);
      addTearDown(buttonFocus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Focus(focusNode: platformView, child: const SizedBox(height: 10)),
              Focus(focusNode: buttonFocus, child: const SizedBox(height: 10)),
            ],
          ),
        ),
      );
      buttonFocus.requestFocus();
      await tester.pump();

      expect(
        editorMayClaimKeyboard(
          FocusManager.instance.primaryFocus,
          platformView,
        ),
        isFalse,
      );
    });
  });

  group('editorPointerMayClaimKeyboard', () {
    test('allows primary mouse clicks to claim typing focus', () {
      expect(
        editorPointerMayClaimKeyboard(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          ),
        ),
        isTrue,
      );
    });

    test(
      'does not turn secondary or middle mouse clicks into focus nudges',
      () {
        expect(
          editorPointerMayClaimKeyboard(
            const PointerDownEvent(
              kind: PointerDeviceKind.mouse,
              buttons: kSecondaryMouseButton,
            ),
          ),
          isFalse,
        );
        expect(
          editorPointerMayClaimKeyboard(
            const PointerDownEvent(
              kind: PointerDeviceKind.mouse,
              buttons: kMiddleMouseButton,
            ),
          ),
          isFalse,
        );
      },
    );

    test('keeps touch taps eligible for editor focus', () {
      expect(
        editorPointerMayClaimKeyboard(
          const PointerDownEvent(
            kind: PointerDeviceKind.touch,
            buttons: kPrimaryButton,
          ),
        ),
        isTrue,
      );
    });
  });

  group('editorPointerFocusIntent', () {
    test('marks primary clicks as user focus when fully unfocused', () {
      expect(
        editorPointerFocusIntent(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          ),
          editorHasFlutterFocus: false,
          editorReportsFocused: false,
          nativeInputReadinessStale: false,
          platform: TargetPlatform.windows,
        ),
        MonacoFocusIntent.user,
      );
    });

    test(
      'does not replay user focus on Windows when the editor is fully focused',
      () {
        expect(
          editorPointerFocusIntent(
            const PointerDownEvent(
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            ),
            editorHasFlutterFocus: true,
            editorReportsFocused: true,
            nativeInputReadinessStale: false,
            platform: TargetPlatform.windows,
          ),
          isNull,
        );
      },
    );

    test('uses user intent on macOS even when focus signals are stale', () {
      expect(
        editorPointerFocusIntent(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          ),
          editorHasFlutterFocus: true,
          editorReportsFocused: true,
          nativeInputReadinessStale: false,
          platform: TargetPlatform.macOS,
        ),
        MonacoFocusIntent.user,
      );
    });

    test('uses user intent when Monaco reports unfocused despite Flutter focus '
        '(alt-tab/dialog desync)', () {
      expect(
        editorPointerFocusIntent(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          ),
          editorHasFlutterFocus: true,
          editorReportsFocused: false,
          nativeInputReadinessStale: false,
          platform: TargetPlatform.windows,
        ),
        MonacoFocusIntent.user,
      );
    });

    test(
      'uses user intent when Flutter focus is missing despite Monaco focus',
      () {
        expect(
          editorPointerFocusIntent(
            const PointerDownEvent(
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            ),
            editorHasFlutterFocus: false,
            editorReportsFocused: true,
            nativeInputReadinessStale: false,
            platform: TargetPlatform.windows,
          ),
          MonacoFocusIntent.user,
        );
      },
    );

    test(
      'replays user focus on Windows after a stale tab visibility boundary',
      () {
        expect(
          editorPointerFocusIntent(
            const PointerDownEvent(
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            ),
            editorHasFlutterFocus: true,
            editorReportsFocused: true,
            nativeInputReadinessStale: true,
            platform: TargetPlatform.windows,
          ),
          MonacoFocusIntent.user,
        );
      },
    );

    test('never creates focus intent for secondary clicks', () {
      expect(
        editorPointerFocusIntent(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          ),
          editorHasFlutterFocus: false,
          editorReportsFocused: false,
          nativeInputReadinessStale: true,
          platform: TargetPlatform.macOS,
        ),
        isNull,
      );
    });
  });

  group('editorInputReadinessForFocusSignals', () {
    test(
      'treats stale native readiness as not ready even if focus says yes',
      () {
        expect(
          editorInputReadinessForFocusSignals(
            editorMayClaimKeyboard: true,
            editorWasLastKeyboardTarget: true,
            editorHasFlutterFocus: true,
            editorReportsFocused: true,
            nativeInputReadinessStale: true,
          ),
          MonacoInputReadiness.stale,
        );
      },
    );

    test('foreign Flutter focus wins over stale editor signals', () {
      expect(
        editorInputReadinessForFocusSignals(
          editorMayClaimKeyboard: false,
          editorWasLastKeyboardTarget: true,
          editorHasFlutterFocus: true,
          editorReportsFocused: true,
          nativeInputReadinessStale: true,
        ),
        MonacoInputReadiness.foreignKeyboardOwner,
      );
    });

    test(
      'reports ready only when editor is the target and readiness is fresh',
      () {
        expect(
          editorInputReadinessForFocusSignals(
            editorMayClaimKeyboard: true,
            editorWasLastKeyboardTarget: false,
            editorHasFlutterFocus: true,
            editorReportsFocused: false,
            nativeInputReadinessStale: false,
          ),
          MonacoInputReadiness.ready,
        );
      },
    );

    test('reports no target when nobody points at Monaco', () {
      expect(
        editorInputReadinessForFocusSignals(
          editorMayClaimKeyboard: true,
          editorWasLastKeyboardTarget: false,
          editorHasFlutterFocus: false,
          editorReportsFocused: false,
          nativeInputReadinessStale: false,
        ),
        MonacoInputReadiness.noEditorTarget,
      );
    });
  });

  group('editorInputReadinessFocusIntent', () {
    test('uses user intent only when native input readiness is stale', () {
      expect(
        editorInputReadinessFocusIntent(MonacoInputReadiness.stale),
        MonacoFocusIntent.user,
      );
    });

    test('keeps maintenance intent when editor input is fresh', () {
      expect(
        editorInputReadinessFocusIntent(MonacoInputReadiness.ready),
        MonacoFocusIntent.maintenance,
      );
    });

    test('keeps maintenance intent when another surface owns the keyboard', () {
      expect(
        editorInputReadinessFocusIntent(
          MonacoInputReadiness.foreignKeyboardOwner,
        ),
        MonacoFocusIntent.maintenance,
      );
    });

    test('keeps maintenance intent when Monaco was not the focus target', () {
      expect(
        editorInputReadinessFocusIntent(MonacoInputReadiness.noEditorTarget),
        MonacoFocusIntent.maintenance,
      );
    });
  });

  group('editorTracksNativeInputReadinessStaleness', () {
    test('tracks desktop platform-view boundaries', () {
      expect(
        editorTracksNativeInputReadinessStaleness(
          isWeb: false,
          platform: TargetPlatform.macOS,
        ),
        isTrue,
      );
      expect(
        editorTracksNativeInputReadinessStaleness(
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
        isTrue,
      );
      expect(
        editorTracksNativeInputReadinessStaleness(
          isWeb: false,
          platform: TargetPlatform.linux,
        ),
        isTrue,
      );
    });

    test('does not track web or mobile as desktop native input boundaries', () {
      expect(
        editorTracksNativeInputReadinessStaleness(
          isWeb: true,
          platform: TargetPlatform.windows,
        ),
        isFalse,
      );
      expect(
        editorTracksNativeInputReadinessStaleness(
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
      expect(
        editorTracksNativeInputReadinessStaleness(
          isWeb: false,
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
    });
  });
}
