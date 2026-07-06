import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide count of floating overlay routes (dialogs, menus, sheets) that
/// are open above ANY of the app's navigators.
///
/// Why this exists (web layer 0): on Flutter Web the Monaco editor is an
/// iframe, and the browser's DOM hit test picks the event target BEFORE
/// Flutter's hit testing runs. Flutter paints into `pointer-events: none`
/// canvases, so over the editor's rect the topmost interactive DOM element
/// is the iframe - and events dispatched inside an iframe never bubble to
/// the parent document. A dialog painted above the editor is visible but
/// unreachable: its buttons get no clicks, its barrier absorbs nothing, and
/// keyboard input keeps dispatching inside the iframe's document.
///
/// The only available shape (FOCUS_HANDLING hard limit: a Flutter-painted
/// overlay can NEVER intercept iframe events) is to make the iframe inert
/// while an overlay floats above it: `MonacoController.setInteractionEnabled`
/// applies `pointer-events: none` and hands the browser's document focus
/// back to Flutter. [MonacoService] listens to this coordinator and toggles
/// exactly that. On native platforms `setInteractionEnabled` is a no-op, so
/// this coordination changes nothing on desktop.
///
/// Why per-navigator observers feed ONE coordinator: `showDialog` defaults
/// to the ROOT navigator while `showMenu`/`DropdownButton` use the NEAREST
/// (per-session) navigator, and a `NavigatorObserver` instance can only be
/// attached to a single navigator. `flutter_monaco`'s `MonacoFocusGuard`
/// cannot bridge navigators (an observer on one navigator never notifies a
/// guard subscribed to a route of another), which is why the app owns this
/// wiring instead of using the package guard.
class ModalOverlayCoordinator extends ChangeNotifier {
  final Map<ModalOverlayObserver, Set<Route<dynamic>>> _routesByObserver =
      <ModalOverlayObserver, Set<Route<dynamic>>>{};

  /// Whether any floating overlay route is currently open anywhere.
  bool get anyOverlayOpen {
    for (final routes in _routesByObserver.values) {
      if (routes.isNotEmpty) return true;
    }
    return false;
  }

  /// Total floating overlay routes currently tracked (for tests/debugging).
  @visibleForTesting
  int get overlayRouteCount =>
      _routesByObserver.values.fold(0, (sum, routes) => sum + routes.length);

  void _track(ModalOverlayObserver observer, Route<dynamic> route) {
    final wasOpen = anyOverlayOpen;
    _routesByObserver
        .putIfAbsent(observer, () => <Route<dynamic>>{})
        .add(route);
    if (wasOpen != anyOverlayOpen) notifyListeners();
  }

  void _untrack(ModalOverlayObserver observer, Route<dynamic> route) {
    final wasOpen = anyOverlayOpen;
    final routes = _routesByObserver[observer];
    if (routes == null) return;
    routes.remove(route);
    if (routes.isEmpty) _routesByObserver.remove(observer);
    if (wasOpen != anyOverlayOpen) notifyListeners();
  }

  /// Forget everything an observer tracked.
  ///
  /// Called when the observer's navigator goes away (session tab closed): a
  /// disposed `Navigator` does NOT fire `didRemove` for the routes it takes
  /// down with it, so without this hook a menu open at close time would
  /// leave every editor inert forever.
  void _detach(ModalOverlayObserver observer) {
    final wasOpen = anyOverlayOpen;
    _routesByObserver.remove(observer);
    if (wasOpen != anyOverlayOpen) notifyListeners();
  }
}

/// Reports floating overlay routes of ONE navigator into a shared
/// [ModalOverlayCoordinator].
///
/// A route counts while it is a [ModalRoute] with `opaque == false`: dialogs,
/// popup/context menus, dropdowns, and modal bottom sheets all match, and the
/// editor stays visible (and therefore hit-testable in the DOM) beneath them.
/// Opaque page routes deliberately do NOT count: a fully covering page
/// removes the editor from the scene, which removes the iframe from DOM hit
/// testing by itself.
class ModalOverlayObserver extends NavigatorObserver {
  ModalOverlayObserver(this._coordinator);

  final ModalOverlayCoordinator _coordinator;

  static bool _isFloatingOverlay(Route<dynamic>? route) =>
      route is ModalRoute<dynamic> && !route.opaque;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isFloatingOverlay(route)) _coordinator._track(this, route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _coordinator._untrack(this, route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _coordinator._untrack(this, route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _coordinator._untrack(this, oldRoute);
    if (_isFloatingOverlay(newRoute)) _coordinator._track(this, newRoute!);
  }

  /// Release everything this observer tracked. Wire to the owning provider's
  /// `onDispose` so a closed session cannot strand overlay locks.
  void detach() => _coordinator._detach(this);
}

/// Single app-wide coordinator. Session containers resolve this through
/// their parent (root) container - do NOT override it per session.
final modalOverlayCoordinatorProvider = Provider<ModalOverlayCoordinator>(
  (_) => ModalOverlayCoordinator(),
);

/// One observer per navigator. The root container's instance goes on the
/// root `MaterialApp` navigator; each session container overrides this with
/// its own instance for its session `Navigator` (an observer instance can
/// only be attached to one navigator).
final modalOverlayObserverProvider = Provider<ModalOverlayObserver>((ref) {
  final observer = ModalOverlayObserver(
    ref.watch(modalOverlayCoordinatorProvider),
  );
  ref.onDispose(observer.detach);
  return observer;
});
