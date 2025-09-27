// lib/src/theme/directory_tree_theme.dart
import 'package:flutter/widgets.dart';

class DirectoryTreeThemeData {
  const DirectoryTreeThemeData({
    this.rowHeight = 28.0,
    this.indent = 16.0,
    this.indentGuides = true,
    this.hoverColor,
    this.selectionColor,
    this.focusColor,
    this.guideColor,
    this.animationDuration = const Duration(milliseconds: 120),
    this.roundedCorners = true,
  });

  final double rowHeight;
  final double indent;
  final bool indentGuides;
  final Color? hoverColor;
  final Color? selectionColor;
  final Color? focusColor;
  final Color? guideColor;
  final Duration animationDuration;
  final bool roundedCorners;

  DirectoryTreeThemeData copyWith({
    double? rowHeight,
    double? indent,
    bool? indentGuides,
    Color? hoverColor,
    Color? selectionColor,
    Color? focusColor,
    Color? guideColor,
    Duration? animationDuration,
    bool? roundedCorners,
  }) {
    return DirectoryTreeThemeData(
      rowHeight: rowHeight ?? this.rowHeight,
      indent: indent ?? this.indent,
      indentGuides: indentGuides ?? this.indentGuides,
      hoverColor: hoverColor ?? this.hoverColor,
      selectionColor: selectionColor ?? this.selectionColor,
      focusColor: focusColor ?? this.focusColor,
      guideColor: guideColor ?? this.guideColor,
      animationDuration: animationDuration ?? this.animationDuration,
      roundedCorners: roundedCorners ?? this.roundedCorners,
    );
  }
}

class DirectoryTreeTheme extends InheritedWidget {
  const DirectoryTreeTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final DirectoryTreeThemeData data;

  static DirectoryTreeThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DirectoryTreeTheme>()?.data ??
      const DirectoryTreeThemeData();

  @override
  bool updateShouldNotify(covariant DirectoryTreeTheme oldWidget) =>
      data != oldWidget.data;
}
