import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../context_collector.dart';
import 'route_observers.dart';

/// Declarative 2-page navigator:
/// - Home screen is always the base page
/// - Editor screen appears when a session has files
class SessionNavigator extends ConsumerWidget {
  const SessionNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(selectionProvider);
    final inSession = state.hasFiles;

    final pages = <Page<void>>[
      const MaterialPage<void>(
        key: ValueKey('home'),
        child: HomeScreenWithDrop(),
      ),
      if (inSession)
        const MaterialPage<void>(
          key: ValueKey('editor'),
          child: EditorScreen(),
        ),
    ];

    return Navigator(
      pages: pages,
      observers: [appRouteObserver],
      onDidRemovePage: (page) {
        // Only react to the Editor page being removed
        if (page.key == const ValueKey('editor')) {
          // Defer provider mutation until after this build frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(selectionProvider).hasFiles) {
              ref.read(selectionProvider.notifier).clearFiles();
            }
          });
        }
      },
    );
  }
}
