import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a RouteObserver scoped to the current ProviderContainer.
final routeObserverProvider = Provider<RouteObserver<PageRoute<dynamic>>>(
  (_) => RouteObserver<PageRoute<dynamic>>(),
);
