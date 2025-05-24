import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';

class EnhancedTextEditor extends StatefulWidget {
  const EnhancedTextEditor({
    super.key,
    required this.content,
    this.onCopy,
    this.onScrollToTop,
    this.showLineNumbers = true,
    this.fontSize = 13,
    this.wordWrap = false,
  });

  final String content;
  final VoidCallback? onCopy;
  final VoidCallback? onScrollToTop;
  final bool showLineNumbers;
  final double fontSize;
  final bool wordWrap;

  @override
  State<EnhancedTextEditor> createState() => _EnhancedTextEditorState();
}

class _EnhancedTextEditorState extends State<EnhancedTextEditor>
    with SingleTickerProviderStateMixin {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _lineNumberController = ScrollController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<String> _lines = [];
  int _totalLines = 0;
  int _totalCharacters = 0;

  @override
  void initState() {
    super.initState();
    _updateTextMetrics();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Sync line numbers scroll with content scroll
    _verticalController.addListener(() {
      if (_lineNumberController.hasClients) {
        _lineNumberController.jumpTo(_verticalController.offset);
      }
    });
  }

  @override
  void didUpdateWidget(EnhancedTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _updateTextMetrics();
      // Trigger fade animation on content change
      _fadeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _lineNumberController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateTextMetrics() {
    _lines = widget.content.split('\n');
    _totalLines = _lines.length;
    _totalCharacters = widget.content.length;
  }

  @override
  Widget build(BuildContext context) {
    final lineNumberWidth = _calculateLineNumberWidth();

    return Column(
      children: [
        // Main content area
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.black.addOpacity(0.3)
                    : Colors.grey.shade50,
                border: Border.all(
                  color: context.onSurface.addOpacity(0.1),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line numbers
                    if (widget.showLineNumbers) ...[
                      Container(
                        width: lineNumberWidth,
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.black.addOpacity(0.5)
                              : Colors.grey.shade100,
                          border: BorderDirectional(
                            end: BorderSide(
                              color: context.onSurface.addOpacity(0.1),
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: _lineNumberController,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: 12,
                              bottom: 12,
                              end: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                _totalLines,
                                (index) => SizedBox(
                                  height: widget.fontSize * 1.4,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: widget.fontSize * 0.9,
                                      height: 1.4,
                                      color: context.onSurface.addOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Text content
                    Expanded(
                      child: widget.wordWrap
                          ? Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _verticalController,
                                padding: const EdgeInsetsDirectional.all(12),
                                child: SelectableText(
                                  widget.content,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: widget.fontSize,
                                    height: 1.4,
                                    color: context.onBackground,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            )
                          : Scrollbar(
                              controller: _horizontalController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _horizontalController,
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: _calculateTextWidth(),
                                  child: Scrollbar(
                                    controller: _verticalController,
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _verticalController,
                                      padding:
                                          const EdgeInsetsDirectional.all(12),
                                      child: SelectableText(
                                        widget.content,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: widget.fontSize,
                                          height: 1.4,
                                          color: context.onBackground,
                                        ),
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Info bar
        Container(
          margin: const EdgeInsetsDirectional.only(top: 8),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.black.addOpacity(0.3)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: context.onSurface.addOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              _buildInfoItem(
                context,
                icon: Icons.format_list_numbered,
                label: 'Lines',
                value: _totalLines.toString(),
              ),
              const SizedBox(width: 24),
              _buildInfoItem(
                context,
                icon: Icons.text_fields,
                label: 'Characters',
                value: _formatNumber(_totalCharacters),
              ),
              const Spacer(),
              // Action buttons
              if (widget.content.isNotEmpty) ...[
                _buildActionButton(
                  context,
                  icon: Icons.vertical_align_top,
                  tooltip: 'Scroll to top',
                  onPressed: () {
                    _verticalController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    widget.onScrollToTop?.call();
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  context,
                  icon: Icons.copy,
                  tooltip: 'Copy to clipboard (⌘+C after selecting)',
                  onPressed: widget.onCopy,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: context.onSurface.addOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: context.labelSmall?.copyWith(
            color: context.onSurface.addOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: context.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.onSurface.addOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 18,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: context.primary.addOpacity(0.1),
        foregroundColor: context.primary,
        padding: const EdgeInsetsDirectional.all(6),
        minimumSize: const Size(32, 32),
      ),
    );
  }

  double _calculateLineNumberWidth() {
    if (!widget.showLineNumbers) return 0;

    final maxDigits = _totalLines.toString().length;
    // Calculate width based on number of digits + padding
    return (maxDigits * 10.0) + 24.0;
  }

  double _calculateTextWidth() {
    // Calculate the maximum line length to determine horizontal scroll width
    double maxLineWidth = 0;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final line in _lines) {
      textPainter
        ..text = TextSpan(
          text: line,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: widget.fontSize,
            height: 1.4,
          ),
        )
        ..layout();
      maxLineWidth =
          maxLineWidth > textPainter.width ? maxLineWidth : textPainter.width;
    }

    // Add padding and minimum width
    return (maxLineWidth + 48).clamp(500, double.infinity);
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}
