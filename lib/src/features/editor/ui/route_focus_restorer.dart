import 'dart:async';

import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Restores Monaco focus when a route above this widget is popped.
///
/// We subscribe to the global [routeObserver] and trigger focus restoration
/// in [didPopNext], which runs after the pop animation finishes and
/// after the platform view is reattached.
class MonacoRouteFocusRestorer extends ConsumerStatefulWidget {
  const MonacoRouteFocusRestorer({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MonacoRouteFocusRestorer> createState() =>
      _MonacoRouteFocusRestorerState();
}

class _MonacoRouteFocusRestorerState
    extends ConsumerState<MonacoRouteFocusRestorer> with RouteAware {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      if (_route != null) routeObserver.unsubscribe(this);
      _route = route;
      if (_route != null) routeObserver.subscribe(this, _route!);
    }
  }

  @override
  void dispose() {
    if (_route != null) routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Dialog/sheet/page above was popped.
    Future.microtask(() async {
      // Ensure platform view has reattached.
      await WidgetsBinding.instance.endOfFrame;
      await EditorFocusHelper.restoreFocus(ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

