import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Context Collector delegates Monaco TextInput handoff to flutter_monaco',
    () {
      final appSource = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');

      expect(appSource, isNot(contains('TextInput.hide')));
      expect(appSource, isNot(contains('SystemChannels.textInput')));
      expect(appSource, isNot(contains('primaryFocusIsFlutterTextInput')));
    },
  );

  test('Context Collector does not depend directly on WebView plugins', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    // 3.0.0 keeps the macOS native first-responder handoff (per-click user
    // intent stays cheap), the web two-sided focus handoff in
    // setInteractionEnabled(false) that the modal overlay coordination
    // depends on (keyboard returns to Flutter when the iframe goes inert),
    // and exposes the v3 document/requestFocus API used by the app.
    // flutter_monaco is the sole editor dependency; hosted (released) and
    // the local sibling checkout (development) are both valid shapes.
    expect(
      pubspec,
      anyOf(
        contains('flutter_monaco: ^'),
        contains('path: ../flutter_monaco'),
      ),
    );
    expect(pubspec, isNot(contains('webview_flutter:')));
    expect(pubspec, isNot(contains('webview_flutter_windows:')));
    expect(pubspec, isNot(contains('webview_windows:')));
  });

  test('tab switching is treated as a native input-readiness boundary', () {
    final tabShell = File('lib/src/app/tab_shell.dart').readAsStringSync();

    expect(tabShell, contains('setVisibleForKeyboardInput'));
    expect(tabShell, contains('afterNativeFocusBoundary: true'));
    expect(
      tabShell,
      contains('recoverKeyboardFocusAfterNativeFocusBoundary'),
    );
  });

  test(
    'every navigator that can host overlays reports into the modal '
    'overlay coordinator (web: iframes must go inert under dialogs/menus)',
    () {
      // Root navigator: showDialog defaults to useRootNavigator: true, so app
      // dialogs land here. Without this observer, a dialog over the editor on
      // web is visible but unreachable (browser DOM hit-testing gives the
      // iframe every pointer event; iframe events never reach Flutter).
      final mainSource = File('lib/main.dart').readAsStringSync();
      expect(mainSource, contains('navigatorObservers:'));
      expect(mainSource, contains('modalOverlayObserverProvider'));

      // Session navigators: showMenu/DropdownButton default to the NEAREST
      // navigator, so per-session overlays are invisible to the root observer.
      final sessionNavigator = File(
        'lib/src/app/session_navigator.dart',
      ).readAsStringSync();
      expect(sessionNavigator, contains('modalOverlayObserverProvider'));
      expect(sessionNavigator, contains('modalOverlayObserver]'));

      // Each session must get its OWN observer instance (one observer per
      // navigator) that detaches on session close so an overlay open at close
      // time cannot strand every editor inert.
      final sessionManager = File(
        'lib/src/app/session_manager.dart',
      ).readAsStringSync();
      expect(
        sessionManager,
        contains('modalOverlayObserverProvider.overrideWith'),
      );
      expect(
        sessionManager,
        contains('overrideRef.onDispose(observer.detach)'),
      );
    },
  );

  test('MonacoService owns the overlay reaction: inert while any overlay is '
      'open, ownership-gated recovery on close (web only)', () {
    final service = File(
      'lib/src/features/editor/data/monaco_service.dart',
    ).readAsStringSync();

    // Both MonacoService construction sites inject the coordinator.
    final providers = File(
      'lib/src/features/editor/data/providers.dart',
    ).readAsStringSync();
    final sessionManager = File(
      'lib/src/app/session_manager.dart',
    ).readAsStringSync();
    expect(providers, contains('overlayCoordinator:'));
    expect(sessionManager, contains('overlayCoordinator:'));

    // The service listens and toggles the fm interaction flag (pointer AND
    // keyboard handoff on web; verified no-op on native platforms).
    expect(service, contains('_overlayCoordinator?.addListener'));
    expect(service, contains('setInteractionEnabled(!shouldLock)'));
    expect(
      service,
      contains('_overlayCoordinator?.removeListener'),
      reason: 'dispose must unsubscribe or closed sessions leak listeners',
    );

    // Recovery after the last overlay closes is web-only (desktop recovery
    // stays click-driven by design - F01/F05) and goes through the
    // ownership-gated maintenance path (F02: never steal from a TextField).
    expect(service, contains('if (!shouldLock && kIsWeb)'));
    expect(service, contains('unawaited(recoverKeyboardFocus())'));
  });

  test('web pointer clicks never nudge Flutter-side editor focus', () {
    final service = File(
      'lib/src/features/editor/data/monaco_service.dart',
    ).readAsStringSync();

    // The browser owns click-to-focus on web; clicks over the iframe never
    // reach the Flutter Listener at all. The explicit branch keeps
    // web-on-macOS out of the host-OS macOS user-intent branch.
    expect(service, contains('if (isWeb) return null;'));
  });
}
