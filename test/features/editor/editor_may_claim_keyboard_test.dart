import 'dart:async';

import 'package:context_collector/src/features/editor/data/monaco_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  group('editorPointerShouldNudgeFocus', () {
    test('allows primary clicks to enter focus when fully unfocused', () {
      expect(
        editorPointerShouldNudgeFocus(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          ),
          editorHasFlutterFocus: false,
          editorReportsFocused: false,
        ),
        isTrue,
      );
    });

    test('does not replay focus when the editor is already fully focused', () {
      expect(
        editorPointerShouldNudgeFocus(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          ),
          editorHasFlutterFocus: true,
          editorReportsFocused: true,
        ),
        isFalse,
      );
    });

    test(
        're-asserts focus when Monaco reports unfocused despite Flutter focus '
        '(alt-tab/dialog desync)', () {
      expect(
        editorPointerShouldNudgeFocus(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          ),
          editorHasFlutterFocus: true,
          editorReportsFocused: false,
        ),
        isTrue,
      );
    });

    test('re-asserts focus when Flutter focus is missing despite Monaco focus',
        () {
      expect(
        editorPointerShouldNudgeFocus(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          ),
          editorHasFlutterFocus: false,
          editorReportsFocused: true,
        ),
        isTrue,
      );
    });

    test('never nudges for secondary clicks, even when fully unfocused', () {
      expect(
        editorPointerShouldNudgeFocus(
          const PointerDownEvent(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          ),
          editorHasFlutterFocus: false,
          editorReportsFocused: false,
        ),
        isFalse,
      );
    });
  });
}
