import 'dart:developer';

import 'package:context_collector/src/shared/theme/extensions.dart';
import 'package:flutter/material.dart';

/// A widget that allows resizing two panels with a draggable divider
class ResizableSplitter extends StatefulWidget {
  const ResizableSplitter({
    required this.startPanel,
    required this.endPanel,
    super.key,
    this.initialRatio = 0.4,
    this.minRatio = 0.2,
    this.maxRatio = 0.8,
    this.dividerThickness = 8,
    this.onRatioChanged,
  });

  final Widget startPanel;
  final Widget endPanel;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;
  final double dividerThickness;
  final ValueChanged<double>? onRatioChanged;

  @override
  State<ResizableSplitter> createState() => _ResizableSplitterState();
}

class _ResizableSplitterState extends State<ResizableSplitter> {
  late double _ratio;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    RenderBox? box;
    try {
      box = context.findRenderObject() as RenderBox?;
    } catch (e, s) {
      log('Error finding render object: $e', error: e, stackTrace: s);
    }

    final width = box?.size.width ?? 0;

    setState(() {
      _ratio += details.delta.dx / width;
      _ratio = _ratio.clamp(widget.minRatio, widget.maxRatio);
    });

    widget.onRatioChanged?.call(_ratio);
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final startWidth =
            constraints.maxWidth * _ratio - widget.dividerThickness / 2;
        final endWidth =
            constraints.maxWidth * (1 - _ratio) - widget.dividerThickness / 2;

        return Row(
          children: [
            // Start panel
            SizedBox(
              width: startWidth,
              child: widget.startPanel,
            ),

            // Draggable divider
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: Container(
                  width: widget.dividerThickness,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: _isDragging ? 3 : 1,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? context.primary
                            : context.onSurface.addOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // End panel
            SizedBox(
              width: endWidth,
              child: widget.endPanel,
            ),
          ],
        );
      },
    );
  }
}
