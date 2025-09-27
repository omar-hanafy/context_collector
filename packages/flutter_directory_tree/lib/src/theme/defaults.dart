import 'package:flutter/material.dart';
import 'package:flutter_directory_tree/src/theme/directory_tree_theme.dart';

class DirectoryTreeDefaults {
  const DirectoryTreeDefaults._();

  static DirectoryTreeThemeData themed(BuildContext context,
      {DirectoryTreeThemeData? base}) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final hover = base?.hoverColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x11000000));
    final sel = base?.selectionColor ??
        (isDark ? const Color(0x332196F3) : const Color(0x2A2196F3));
    final focus = base?.focusColor ??
        (isDark ? const Color(0x332196F3) : const Color(0x332196F3));
    final guide = base?.guideColor ??
        (isDark ? const Color(0x22FFFFFF) : const Color(0x22000000));

    return (base ?? const DirectoryTreeThemeData()).copyWith(
      hoverColor: hover,
      selectionColor: sel,
      focusColor: focus,
      guideColor: guide,
    );
  }
}
