import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../context_collector.dart';
import 'route_observers.dart';

/// Declarative 2-page navigator:
/// - Home screen is always the base page
/// - Editor screen appears when a session has files
class SessionNavigator extends ConsumerWidget {
  const SessionNavigator({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(selectionProvider);
    final inSession = state.hasFiles;

    final pages = <Page<void>>[
      _desktopTransitionPage(
        key: const ValueKey('home'),
        child: const HomeScreenWithDrop(),
      ),
      if (inSession)
        _desktopTransitionPage(
          key: const ValueKey('editor'),
          child: const EditorScreen(),
        ),
    ];

    final routeObserver = ref.watch(routeObserverProvider);
    // Session-scoped instance: reports this navigator's floating overlays
    // (menus, dropdowns - showMenu defaults to the NEAREST navigator) into
    // the app-wide ModalOverlayCoordinator so Monaco iframes go inert on web.
    final modalOverlayObserver = ref.watch(modalOverlayObserverProvider);

    return Navigator(
      key: navigatorKey,
      pages: pages,
      observers: [routeObserver, modalOverlayObserver],
      onDidRemovePage: (page) {
        if (page.key != const ValueKey('editor')) {
          return;
        }

        final notifier = ref.read(selectionProvider.notifier);
        final shouldClear = ref.read(selectionProvider).hasFiles;
        if (!shouldClear) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!notifier.mounted) return;
          notifier.clearFiles();
        });
      },
    );
  }
}

const _desktopTransitionDuration = Duration(milliseconds: 260);
const _desktopReverseTransitionDuration = Duration(milliseconds: 200);
const _desktopSlideBegin = Offset(0, 0.018);
const _desktopScaleBegin = 0.98;

Page<void> _desktopTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return _DesktopTransitionPage(
    key: key,
    child: child,
  );
}

class _DesktopTransitionPage extends Page<void> {
  const _DesktopTransitionPage({
    required super.key,
    required this.child,
  });

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: _desktopTransitionDuration,
      reverseTransitionDuration: _desktopReverseTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder:
          (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: _desktopSlideBegin,
                  end: Offset.zero,
                ).animate(curved),
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: _desktopScaleBegin,
                    end: 1,
                  ).animate(curved),
                  child: child,
                ),
              ),
            );
          },
    );
  }
}
