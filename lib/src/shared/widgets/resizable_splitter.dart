// ignore_for_file: use_setters_to_change_properties

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

// Re-export for clean imports
export 'package:flutter/material.dart' show Axis;

/// Axis helpers to eliminate H/V duplication.
extension _AxisHelpers on Axis {
  bool get isH => this == Axis.horizontal;

  double pos(Offset o) => isH ? o.dx : o.dy;

  double size(Size s) => isH ? s.width : s.height;

  SystemMouseCursor get cursor =>
      isH ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow;
}

/// A controller for managing splitter position.
///
/// The controller maintains the split ratio (0.0 to 1.0) and provides
/// methods for programmatic control. It uses a global pointer router to
/// prevent stuck drags.
class SplitterController extends ValueNotifier<double> {
  /// Creates a splitter controller with the given initial ratio.
  SplitterController({double initialRatio = 0.5})
    : assert(
        initialRatio >= 0.0 && initialRatio <= 1.0,
        'initialRatio must be between 0.0 and 1.0',
      ),
      super(initialRatio) {
    _globalRouter.register(this);
  }

  static final _globalRouter = _GlobalPointerRouter();

  @override
  void dispose() {
    _globalRouter.unregister(this);
    super.dispose();
  }

  /// Updates the ratio with an optional threshold to prevent chatty updates.
  void updateRatio(double newRatio, {double threshold = 0.002}) {
    final clamped = newRatio.clamp(0.0, 1.0);
    if ((clamped - value).abs() > threshold) {
      value = clamped;
    }
  }

  /// Resets the splitter to the specified position, defaulting to center.
  void reset([double to = 0.5]) {
    assert(to >= 0.0 && to <= 1.0, 'to must be between 0.0 and 1.0');
    value = to;
  }

  // Internal methods for global router
  void _stopDrag() {
    _dragCallback?.call();
    _dragCallback = null;
  }

  void _setDragCallback(VoidCallback? cb) => _dragCallback = cb;
  VoidCallback? _dragCallback;

  /// Resets the global pointer router. For testing only.
  @visibleForTesting
  static void resetGlobalRouter() => _globalRouter.dispose();
}

/// Singleton global pointer router to handle drag completion events.
class _GlobalPointerRouter {
  factory _GlobalPointerRouter() => _instance;

  _GlobalPointerRouter._() {
    _initialize();
  }

  static final _instance = _GlobalPointerRouter._();

  final _controllers = <SplitterController>{};
  SplitterController? _currentlyDragging;
  bool _initialized = false;

  void _initialize() {
    if (!_initialized) {
      WidgetsBinding.instance.pointerRouter.addGlobalRoute(_handleGlobal);
      _initialized = true;
    }
  }

  void register(SplitterController c) {
    _initialize();
    _controllers.add(c);
  }

  void unregister(SplitterController c) {
    _controllers.remove(c);
    if (c == _currentlyDragging) {
      _currentlyDragging = null;
    }
  }

  void setDragging(SplitterController? c) {
    _currentlyDragging = c;
  }

  void _handleGlobal(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _currentlyDragging?._stopDrag();
      _currentlyDragging = null;
    }
  }

  void dispose() {
    if (_initialized) {
      WidgetsBinding.instance.pointerRouter.removeGlobalRoute(_handleGlobal);
      _initialized = false;
      _controllers.clear();
      _currentlyDragging = null;
    }
  }
}

/// A high-performance resizable splitter widget with robust pointer handling.
///
/// This splitter supports smooth dragging, keyboard navigation, and works
/// correctly with embedded platform views (like WebViews) that can steal
/// pointer events.
class ResizableSplitter extends StatefulWidget {
  /// Creates a resizable splitter widget.
  const ResizableSplitter({
    required this.startPanel,
    required this.endPanel,
    super.key,
    this.controller,
    this.axis = Axis.horizontal,
    this.initialRatio = 0.5,
    this.minRatio = 0.1,
    this.maxRatio = 0.9,
    this.minPanelSize = 100.0,
    this.dividerThickness = 6.0,
    this.dividerColor,
    this.dividerHoverColor,
    this.dividerActiveColor,
    this.onRatioChanged,
    this.enableKeyboard = true,
    this.semanticsLabel,
  }) : assert(
         initialRatio >= 0.0 && initialRatio <= 1.0,
         'initialRatio must be between 0.0 and 1.0',
       ),
       assert(
         minRatio >= 0.0 && minRatio <= 1.0,
         'minRatio must be between 0.0 and 1.0',
       ),
       assert(
         maxRatio >= 0.0 && maxRatio <= 1.0,
         'maxRatio must be between 0.0 and 1.0',
       ),
       assert(minRatio < maxRatio, 'minRatio must be less than maxRatio');

  /// The widget to display in the start position (left/top).
  final Widget startPanel;

  /// The widget to display in the end position (right/bottom).
  final Widget endPanel;

  /// Optional controller for programmatic control and persistence.
  final SplitterController? controller;

  /// The axis along which to split (horizontal or vertical).
  final Axis axis;

  /// Initial split ratio if no controller is provided.
  final double initialRatio;

  /// Minimum allowed ratio (0.0 to 1.0).
  final double minRatio;

  /// Maximum allowed ratio (0.0 to 1.0).
  final double maxRatio;

  /// Minimum size in pixels for either panel.
  final double minPanelSize;

  /// Thickness of the divider handle in pixels.
  final double dividerThickness;

  /// Color of the divider in its idle state.
  final Color? dividerColor;

  /// Color of the divider when hovered.
  final Color? dividerHoverColor;

  /// Color of the divider when being dragged.
  final Color? dividerActiveColor;

  /// Called when the split ratio changes.
  final ValueChanged<double>? onRatioChanged;

  /// Whether to enable keyboard navigation with arrow keys.
  final bool enableKeyboard;

  /// Accessibility label for the divider.
  final String? semanticsLabel;

  @override
  State<ResizableSplitter> createState() => _ResizableSplitterState();
}

class _ResizableSplitterState extends State<ResizableSplitter> {
  late final FocusNode _focusNode;
  SplitterController? _internalController;

  SplitterController get _effectiveController =>
      widget.controller ??
      (_internalController ??= SplitterController(
        initialRatio: widget.initialRatio,
      ));

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ResizableSplitter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == null && widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = widget.axis.size(constraints.biggest);

        if (!maxSize.isFinite || maxSize <= 0) {
          return Flex(
            direction: widget.axis,
            children: [
              Expanded(child: widget.startPanel),
              Expanded(child: widget.endPanel),
            ],
          );
        }

        return ValueListenableBuilder<double>(
          valueListenable: _effectiveController,
          builder: (_, ratio, _) {
            final availableSize = maxSize - widget.dividerThickness;

            var first = availableSize * ratio;
            var second = availableSize - first;

            final effectiveMinPanelSize = widget.minPanelSize.clamp(
              0.0,
              availableSize / 2,
            );

            if (first < effectiveMinPanelSize) {
              first = effectiveMinPanelSize;
              second = availableSize - first;
            } else if (second < effectiveMinPanelSize) {
              second = effectiveMinPanelSize;
              first = availableSize - second;
            }

            return Flex(
              direction: widget.axis,
              children: [
                SizedBox(
                  width: widget.axis.isH ? first : null,
                  height: widget.axis.isH ? null : first,
                  child: widget.startPanel,
                ),
                _DividerHandle(
                  axis: widget.axis,
                  controller: _effectiveController,
                  thickness: widget.dividerThickness,
                  minRatio: widget.minRatio,
                  maxRatio: widget.maxRatio,
                  minPanelSize: widget.minPanelSize,
                  maxSize: availableSize,
                  dividerColor: widget.dividerColor,
                  dividerHoverColor: widget.dividerHoverColor,
                  dividerActiveColor: widget.dividerActiveColor,
                  onRatioChanged: widget.onRatioChanged,
                  enableKeyboard: widget.enableKeyboard,
                  focusNode: _focusNode,
                  semanticsLabel: widget.semanticsLabel,
                ),
                SizedBox(
                  width: widget.axis.isH ? second : null,
                  height: widget.axis.isH ? null : second,
                  child: widget.endPanel,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Internal widget for the draggable divider handle.
class _DividerHandle extends StatefulWidget {
  const _DividerHandle({
    required this.axis,
    required this.controller,
    required this.thickness,
    required this.minRatio,
    required this.maxRatio,
    required this.minPanelSize,
    required this.maxSize,
    required this.dividerColor,
    required this.dividerHoverColor,
    required this.dividerActiveColor,
    required this.onRatioChanged,
    required this.enableKeyboard,
    required this.focusNode,
    required this.semanticsLabel,
  });

  final Axis axis;
  final SplitterController controller;
  final double thickness;
  final double minRatio;
  final double maxRatio;
  final double minPanelSize;
  final double maxSize;
  final Color? dividerColor;
  final Color? dividerHoverColor;
  final Color? dividerActiveColor;
  final ValueChanged<double>? onRatioChanged;
  final bool enableKeyboard;
  final FocusNode focusNode;
  final String? semanticsLabel;

  @override
  State<_DividerHandle> createState() => _DividerHandleState();
}

class _DividerHandleState extends State<_DividerHandle> {
  bool _isDragging = false;
  bool _isHovering = false;
  double? _dragStartPosition;
  double? _dragStartRatio;
  OverlayEntry? _dragOverlay;

  late BoxDecoration _idleDecoration;
  late BoxDecoration _hoverDecoration;
  late BoxDecoration _activeDecoration;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDecorations();
  }

  @override
  void didUpdateWidget(_DividerHandle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dividerColor != widget.dividerColor ||
        oldWidget.dividerHoverColor != widget.dividerHoverColor ||
        oldWidget.dividerActiveColor != widget.dividerActiveColor) {
      _updateDecorations();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _updateDecorations() {
    final theme = Theme.of(context);

    final baseColor = widget.dividerColor ?? theme.primaryColor.addOpacity(0.6);
    final hoverColor =
        widget.dividerHoverColor ?? theme.primaryColor.addOpacity(0.8);
    final activeColor = widget.dividerActiveColor ?? theme.primaryColor;

    _idleDecoration = BoxDecoration(color: baseColor);
    _hoverDecoration = BoxDecoration(color: hoverColor);
    _activeDecoration = BoxDecoration(
      color: activeColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.addOpacity(0.1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ],
    );
  }

  void _startDrag(Offset globalPosition) {
    if (_isDragging) return;

    setState(() => _isDragging = true);
    _dragStartRatio = widget.controller.value;
    _dragStartPosition = widget.axis.pos(globalPosition);

    SplitterController._globalRouter.setDragging(widget.controller);
    widget.controller._setDragCallback(_stopDrag);

    _insertOverlay();
    HapticFeedback.selectionClick();
    widget.focusNode.requestFocus();
  }

  void _stopDrag() {
    if (!mounted) return;

    setState(() => _isDragging = false);
    _removeOverlay();

    _dragStartPosition = null;
    _dragStartRatio = null;
  }

  void _insertOverlay() {
    if (_dragOverlay != null) return;

    _dragOverlay = OverlayEntry(
      builder: (context) => _DragOverlay(axis: widget.axis),
    );

    // Use the root overlay to ensure the shield is rendered on top of
    // platform views, which may have their own rendering surface.
    Overlay.of(context, rootOverlay: true).insert(_dragOverlay!);
  }

  void _removeOverlay() {
    if (_dragOverlay?.mounted ?? false) {
      _dragOverlay?.remove();
    }
    _dragOverlay = null;
  }

  void _updateDrag(Offset globalPosition) {
    if (!_isDragging || _dragStartPosition == null || _dragStartRatio == null) {
      return;
    }

    final currentPos = widget.axis.pos(globalPosition);
    final delta = currentPos - _dragStartPosition!;
    final deltaRatio = delta / widget.maxSize;

    var newRatio = _dragStartRatio! + deltaRatio;

    final minSizeRatio = widget.minPanelSize / widget.maxSize;
    final maxSizeRatio = 1.0 - minSizeRatio;

    newRatio = newRatio.clamp(
      widget.minRatio.clamp(minSizeRatio, maxSizeRatio),
      widget.maxRatio.clamp(minSizeRatio, maxSizeRatio),
    );

    widget.controller.updateRatio(newRatio);
    widget.onRatioChanged?.call(widget.controller.value);
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration currentDecoration;
    if (_isDragging) {
      currentDecoration = _activeDecoration;
    } else if (_isHovering) {
      currentDecoration = _hoverDecoration;
    } else {
      currentDecoration = _idleDecoration;
    }

    Widget divider = MouseRegion(
      cursor: widget.axis.cursor,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (details) => _startDrag(details.position),
        onPointerMove: (details) {
          if (_isDragging) {
            _updateDrag(details.position);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.axis.isH ? widget.thickness : null,
          height: !widget.axis.isH ? widget.thickness : null,
          decoration: currentDecoration,
          child: _isDragging || _isHovering
              ? Center(
                  child: Container(
                    width: widget.axis.isH ? 2 : 24,
                    height: !widget.axis.isH ? 2 : 24,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.addOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );

    divider = Semantics(
      label:
          widget.semanticsLabel ??
          'Drag to resize panels. Use arrow keys to adjust.',
      child: divider,
    );

    if (widget.enableKeyboard) {
      divider = FocusableActionDetector(
        focusNode: widget.focusNode,
        shortcuts: {
          LogicalKeySet(
            widget.axis.isH
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowUp,
          ): const _AdjustIntent(
            -0.01,
          ),
          LogicalKeySet(
            widget.axis.isH
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowDown,
          ): const _AdjustIntent(
            0.01,
          ),
        },
        actions: {
          _AdjustIntent: CallbackAction<_AdjustIntent>(
            onInvoke: (intent) {
              final newRatio = (widget.controller.value + intent.delta).clamp(
                widget.minRatio,
                widget.maxRatio,
              );
              widget.controller.value = newRatio;
              widget.onRatioChanged?.call(newRatio);
              HapticFeedback.selectionClick();
              return null;
            },
          ),
        },
        child: divider,
      );
    }

    return divider;
  }
}

/// An invisible overlay that acts as a shield to block pointer events
/// from reaching platform views during a drag operation.
class _DragOverlay extends StatelessWidget {
  const _DragOverlay({required this.axis});

  final Axis axis;

  /// For debugging: set to true to visualize the overlay.
  static const bool _debugShowOverlay = false;

  @override
  Widget build(BuildContext context) {
    // This color is critical. A completely transparent color can be ignored
    // by the renderer in some cases. A near-invisible color forces it to
    // be rendered, ensuring it can block pointer events.
    final blockerColor = _debugShowOverlay
        ? context.themeData.primaryColor.addOpacity(0.2) // Visible debug color
        : Colors.black.addOpacity(0.01); // Near-invisible but effective blocker

    return Positioned.fill(
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: axis.cursor,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            // This Listener greedily consumes all pointer events.
            // No callbacks are needed because its only purpose is to act
            // as a shield, allowing the handle's Listener to receive
            // the uninterrupted event stream.
            child: Container(color: blockerColor),
          ),
        ),
      ),
    );
  }
}

/// Intent for keyboard-based splitter adjustment.
class _AdjustIntent extends Intent {
  const _AdjustIntent(this.delta);

  final double delta;
}
