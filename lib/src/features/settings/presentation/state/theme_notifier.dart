import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../editor/data/settings_service.dart';
import '../../services/appearance_sync.dart';

/// Provides the Flutter ThemeMode for the whole app.
/// - First run: ThemeMode.system
/// - After user chooses a Monaco theme: light/dark based on that theme
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _init();
  }

  Future<void> _init() async {
    try {
      if (await EditorSettingsService.hasSavedOptions()) {
        final options = await EditorSettingsService.load();
        state = AppearanceSync.themeModeFromMonaco(options.theme);
      } else {
        state = ThemeMode.system; // default on fresh install
      }
    } catch (e) {
      // On any error, stay with system to avoid surprises
      state = ThemeMode.system;
    }
  }

  /// Preferred path: call this after saving Monaco options.
  Future<void> setThemeFromMonaco(MonacoTheme monacoTheme) async {
    state = AppearanceSync.themeModeFromMonaco(monacoTheme);
  }
}
