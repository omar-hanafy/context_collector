import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// On web, the Monaco iframe only loads while its platform view is attached
/// to the DOM, and the platform view is only attached while the webview
/// widget is mounted AND painted. `MonacoService.initialize()` awaits
/// `whenReady`, so the widget must be in the tree (painted, possibly under
/// an opaque overlay) BEFORE readiness - anything that gates the webview on
/// `state.isReady` deadlocks the boot: readiness waits for the widget, the
/// widget waits for readiness, and the user gets a silent 2x20s timeout.
///
/// These are source invariants because the deadlock only reproduces in a
/// real browser (VM widget tests cannot attach an iframe).
void main() {
  String serviceSource() => File(
    'lib/src/features/editor/data/monaco_service.dart',
  ).readAsStringSync();
  String viewSource() => File(
    'lib/src/features/editor/ui/widgets/monaco_editor_integrated.dart',
  ).readAsStringSync();

  group('web boot mount invariants', () {
    test('webviewWidget mounts as soon as the controller exists', () {
      final source = serviceSource();
      final getterStart = source.indexOf('Widget get webviewWidget {');
      expect(getterStart, isNonNegative);
      final getterEnd = source.indexOf('Future<void> initialize', getterStart);
      expect(getterEnd, greaterThan(getterStart));
      final getter = source.substring(getterStart, getterEnd);

      // Gating the widget on readiness recreates the boot deadlock.
      expect(getter, isNot(contains('state.isReady')));
      expect(getter, contains('_controller == null'));
    });

    test('initialize() publishes the controller to the UI before awaiting '
        'readiness', () {
      final source = serviceSource();
      final initStart = source.indexOf('Future<void> initialize() async {');
      expect(initStart, isNonNegative);
      final createIdx = source.indexOf(
        '_controller = await MonacoController.create',
        initStart,
      );
      expect(createIdx, isNonNegative);
      final emitIdx = source.indexOf('state = state.copyWith', createIdx);
      expect(emitIdx, isNonNegative);
      final whenReadyIdx = source.indexOf(
        'await _controller!.whenReady',
        initStart,
      );
      expect(whenReadyIdx, isNonNegative);

      // The UI mounts webviewWidget in response to a state emission; without
      // one between create() and whenReady the tree never rebuilds, the
      // iframe never attaches, and a web boot cannot complete.
      expect(
        whenReadyIdx,
        greaterThan(emitIdx),
        reason:
            'initialize() must emit a state after the controller exists '
            'and before awaiting whenReady, so the webview mounts in time',
      );
    });

    test('initialize() visibly restarts after an error (Retry feedback)', () {
      final source = serviceSource();
      final initStart = source.indexOf('Future<void> initialize() async {');
      expect(initStart, isNonNegative);
      final entryEmit = source.indexOf(
        'lifecycle: EditorLifecycle.initial',
        initStart,
      );
      final createIdx = source.indexOf(
        '_controller = await MonacoController.create',
        initStart,
      );
      expect(createIdx, isNonNegative);

      // Retry re-enters initialize() from the error lifecycle; without an
      // entry emission the error panel stays frozen on screen for the whole
      // boot ("pressing retry does nothing").
      expect(entryEmit, isNonNegative);
      expect(entryEmit, lessThan(createIdx));
    });

    test('the startup prewarm never boots a surfaceless editor on web', () {
      final source = File(
        'lib/src/features/editor/ui/widgets/prewarm_monaco.dart',
      ).readAsStringSync();

      // PrewarmMonaco renders SizedBox.shrink(), so on web no platform view
      // can ever be painted for it: a full initialize() from here burns the
      // whole ready timeout and parks the session in an error state. Web
      // may only warm the HTTP cache; the boot belongs to the screen that
      // owns an editor surface.
      expect(source, contains('kIsWeb'));
      expect(source, contains('MonacoAssets.precache()'));
      expect(source, contains('.initialize()'));
    });

    test('the editor view paints the webview underneath the loading and '
        'error chrome', () {
      final source = viewSource();

      // Offstage (and Visibility(visible: false)) skip painting, so the
      // platform view slot is never composited and the iframe stays
      // detached - the same deadlock enforced at the widget layer. The
      // webview must stay painted, covered by opaque overlays instead.
      expect(source, isNot(contains('Offstage(')));
      expect(source, isNot(contains('Visibility(')));
      expect(source, contains('service.webviewWidget'));

      // Overlays must actually cover the webview: both chrome views paint
      // an opaque surface background.
      expect(source, contains('ColoredBox'));
    });
  });
}
