import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// Maps Monaco theme choice to a Flutter ThemeMode.
/// Heuristic: ids containing 'dark' or 'black' → Dark; ids with 'light' → Light.
/// Fallback is Light (Monaco's default light theme is 'vs').
class AppearanceSync {
  static ThemeMode themeModeFromMonaco(MonacoTheme theme) {
    final id = theme.id.toLowerCase().replaceAll('_', '-');
    if (id.contains('light')) return ThemeMode.light;
    if (id.contains('dark') || id.contains('black') || id.contains('night')) {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }
}

