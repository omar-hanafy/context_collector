import 'dart:async';

import 'package:context_collector/src/app/modal_overlay_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The coordinator is the web overlay contract: while ANY floating overlay
/// route (dialog, menu, sheet) is open above ANY observed navigator, every
/// Monaco iframe must be inert or the overlay is visible but unreachable
/// (browser DOM hit-testing runs before Flutter's). These tests drive REAL
/// routes through real navigators and assert the tracked state is exact -
/// including the cases that silently corrupt a naive depth counter
/// (didRemove, didReplace, navigator disposal with routes still open).
void main() {
  late ModalOverlayCoordinator coordinator;
  late ModalOverlayObserver rootObserver;

  setUp(() {
    coordinator = ModalOverlayCoordinator();
    rootObserver = ModalOverlayObserver(coordinator);
  });

  Widget app(Widget home) => MaterialApp(
    navigatorObservers: [rootObserver],
    home: home,
  );

  testWidgets('dialog opens -> overlay tracked; closes -> cleared', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(title: Text('alert')),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    expect(coordinator.anyOverlayOpen, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(coordinator.anyOverlayOpen, isTrue);
    expect(coordinator.overlayRouteCount, 1);

    await tester.tapAt(const Offset(5, 5)); // barrier dismiss
    await tester.pumpAndSettle();
    expect(coordinator.anyOverlayOpen, isFalse);
    expect(coordinator.overlayRouteCount, 0);
  });

  testWidgets('stacked overlays stay tracked until the LAST one closes', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showDialog<void>(
        context: capturedContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('first'),
          actions: [
            TextButton(
              onPressed: () => showDialog<void>(
                context: dialogContext,
                builder: (_) => const AlertDialog(title: Text('second')),
              ),
              child: const Text('more'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('more'));
    await tester.pumpAndSettle();
    expect(coordinator.overlayRouteCount, 2);

    Navigator.of(capturedContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    expect(coordinator.anyOverlayOpen, isTrue);
    expect(coordinator.overlayRouteCount, 1);

    Navigator.of(capturedContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    expect(coordinator.anyOverlayOpen, isFalse);
  });

  testWidgets('popup menus count as floating overlays', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showMenu<int>(
              context: context,
              position: const RelativeRect.fromLTRB(0, 0, 100, 100),
              items: const [PopupMenuItem<int>(value: 1, child: Text('one'))],
            ),
            child: const Text('menu'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('menu'));
    await tester.pumpAndSettle();
    expect(coordinator.anyOverlayOpen, isTrue);

    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();
    expect(coordinator.anyOverlayOpen, isFalse);
  });

  testWidgets('opaque page routes do NOT count (a covering page removes the '
      'editor from the scene by itself)', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('page')),
              ),
            ),
            child: const Text('push'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(coordinator.anyOverlayOpen, isFalse);
  });

  testWidgets('an overlay on a NESTED navigator with its own observer is '
      'tracked in the same coordinator', (tester) async {
    final innerObserver = ModalOverlayObserver(coordinator);
    await tester.pumpWidget(
      app(
        Navigator(
          observers: [innerObserver],
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => TextButton(
              onPressed: () => showMenu<int>(
                context: context,
                useRootNavigator: false,
                position: const RelativeRect.fromLTRB(0, 0, 100, 100),
                items: const [
                  PopupMenuItem<int>(value: 1, child: Text('inner')),
                ],
              ),
              child: const Text('inner-menu'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('inner-menu'));
    await tester.pumpAndSettle();
    expect(coordinator.anyOverlayOpen, isTrue);

    // The session-close leak guard: a disposed navigator never fires
    // didRemove for the routes it takes down, so detach() must clear them
    // or every editor stays inert forever.
    innerObserver.detach();
    expect(coordinator.anyOverlayOpen, isFalse);
  });

  testWidgets('notifies exactly on open/closed flips', (tester) async {
    final flips = <bool>[];
    coordinator.addListener(() => flips.add(coordinator.anyOverlayOpen));

    late BuildContext capturedContext;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showDialog<void>(
        context: capturedContext,
        builder: (_) => const AlertDialog(title: Text('a')),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      showDialog<void>(
        context: capturedContext,
        builder: (_) => const AlertDialog(title: Text('b')),
      ),
    );
    await tester.pumpAndSettle();
    // Second overlay does not flip the aggregate state again.
    expect(flips, [true]);

    Navigator.of(capturedContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    expect(flips, [true]);

    Navigator.of(capturedContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    expect(flips, [true, false]);
  });
}
