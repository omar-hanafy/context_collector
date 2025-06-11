// ignore_for_file: use_setters_to_change_properties
// Production-ready Flutter splitter with bulletproof pointer handling
// Version: 1.0.0

import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Re-export for clean imports
export 'package:flutter/material.dart' show Axis;

/// Axis helpers to eliminate H/V duplication
extension _AxisHelpers on Axis {
  bool get isH => this == Axis.horizontal;

  double pos(Offset o) => isH ? o.dx : o.dy;

  double size(Size s) => isH ? s.width : s.height;

  SystemMouseCursor get cursor =>
      isH ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow;
}

/// A controller for managing splitter position with automatic persistence support.
///
/// The controller maintains the split ratio (0.0 to 1.0) and provides
/// methods for programmatic control. It automatically handles global
/// pointer events to prevent stuck drags.
///
/// Example:
/// ```dart
/// final controller = SplitterController(initialRatio: 0.3);
/// // Later...
/// controller.reset(); // Returns to default position
/// ```
class SplitterController extends ValueNotifier<double> {
  /// Creates a splitter controller with the given initial ratio.
  ///
  /// The [initialRatio] must be between 0.0 and 1.0.
  SplitterController({double initialRatio = 0.5})
    : assert(
        initialRatio >= 0.0 && initialRatio <= 1.0,
        'initialRatio >= 0.0 && initialRatio <= 1.0',
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

  /// Updates the ratio with optional threshold to prevent chatty updates.
  ///
  /// Only notifies listeners if the change exceeds [threshold].
  void updateRatio(double newRatio, {double threshold = 0.002}) {
    final clamped = newRatio.clamp(0.0, 1.0);
    if ((clamped - value).abs() > threshold) {
      value = clamped;
    }
  }

  /// Resets the splitter to the specified position.
  ///
  /// If [to] is not provided, defaults to 0.5 (center).
  void reset([double to = 0.5]) {
    assert(to >= 0.0 && to <= 1.0, 'to >= 0.0 && to <= 1.0');
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

/// Singleton global pointer router with drag throttling.
/// Handles pointer events globally to prevent stuck drags.
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
    // Note: Firefox may send PointerCancel without PointerUp
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      // Throttled: only notify the currently dragging controller
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

/// A high-performance resizable splitter widget with native-like behavior.
///
/// This splitter provides smooth dragging, keyboard navigation, and proper
/// handling of edge cases like stuck drags. It works correctly inside
/// scrollable widgets and supports both mouse and touch input.
///
/// Example:
/// ```dart
/// ResizableSplitter(
///   startPanel: LeftPanel(),
///   endPanel: RightPanel(),
///   onRatioChanged: (ratio) => savePreference('split_ratio', ratio),
/// )
/// ```
class ResizableSplitter extends StatefulWidget {
  /// Creates a resizable splitter widget.
  ///
  /// The [startPanel] and [endPanel] are required and represent the
  /// two panels being split.
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
         'initialRatio >= 0.0 && initialRatio <= 1.0',
       ),
       assert(
         minRatio >= 0.0 && minRatio <= 1.0,
         'minRatio >= 0.0 && minRatio <= 1.0',
       ),
       assert(
         maxRatio >= 0.0 && maxRatio <= 1.0,
         'maxRatio >= 0.0 && maxRatio <= 1.0',
       ),
       assert(minRatio < maxRatio, 'minRatio < maxRatio');

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

  /// Color of the divider in idle state.
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

    // Clean up focus node if widget is being replaced
    if (oldWidget.controller != widget.controller && !mounted) {
      _focusNode.dispose();
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
          builder: (_, ratio, __) {
            // Account for divider thickness to prevent overflow
            final availableSize = maxSize - widget.dividerThickness;
            
            // Calculate panel sizes based on available space
            var first = availableSize * ratio;
            var second = availableSize - first;
            
            // Ensure minimum panel sizes are respected
            final effectiveMinPanelSize = widget.minPanelSize.clamp(0.0, availableSize / 2);
            
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
                  maxSize: availableSize, // Pass available size, not total
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

/// Internal divider handle widget
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
  double? _dragStartPosition;
  double? _dragStartRatio;

  // Cached decorations
  late BoxDecoration _idleDecoration;
  late BoxDecoration _activeDecoration;

  @override
  void initState() {
    super.initState();
    // Decorations will be initialized in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Safe to access Theme here
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor =
        widget.dividerColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final activeColor = widget.dividerActiveColor ?? theme.primaryColor;

    _idleDecoration = BoxDecoration(color: baseColor);
    _activeDecoration = BoxDecoration(
      color: activeColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 2,
        ),
      ],
    );
  }

  void _startDrag(Offset globalPosition) {
    setState(() => _isDragging = true);
    _dragStartRatio = widget.controller.value;
    _dragStartPosition = widget.axis.pos(globalPosition);

    // Register as currently dragging for throttling
    SplitterController._globalRouter.setDragging(widget.controller);

    widget.controller._setDragCallback(() {
      if (mounted) setState(() => _isDragging = false);
    });

    HapticFeedback.selectionClick();
    widget.focusNode.requestFocus();
  }

  void _updateDrag(Offset globalPosition) {
    if (_dragStartPosition == null || _dragStartRatio == null) return;

    final currentPos = widget.axis.pos(globalPosition);
    final delta = currentPos - _dragStartPosition!;
    // Use the available size (excluding divider) for ratio calculation
    final deltaRatio = delta / widget.maxSize;

    var newRatio = _dragStartRatio! + deltaRatio;

    // Apply constraints with proper min panel size calculation
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
    final theme = Theme.of(context);
    final hoverColor =
        widget.dividerHoverColor ?? theme.primaryColor.withOpacity(0.6);

    Widget divider = MouseRegion(
      cursor: widget.axis.cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Use onPan for better scroll compatibility
        onPanStart: (details) => _startDrag(details.globalPosition),
        onPanUpdate: (details) => _updateDrag(details.globalPosition),
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 120),
          tween: ColorTween(
            begin: _idleDecoration.color,
            end: _isDragging ? _activeDecoration.color : hoverColor,
          ),
          builder: (context, color, _) {
            return Container(
              width: widget.axis.isH ? widget.thickness : null,
              height: !widget.axis.isH ? widget.thickness : null,
              decoration: _isDragging
                  ? _activeDecoration
                  : BoxDecoration(
                      color: color,
                    ),
              child: _isDragging || color != _idleDecoration.color
                  ? Center(
                      child: Container(
                        width: widget.axis.isH ? 2 : 24,
                        height: !widget.axis.isH ? 2 : 24,
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );

    // Wrap with semantics (without focused parameter)
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

class _AdjustIntent extends Intent {
  const _AdjustIntent(this.delta);

  final double delta;
}
