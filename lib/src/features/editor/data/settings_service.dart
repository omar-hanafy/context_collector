import 'dart:convert';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple service for persisting EditorOptions
class EditorSettingsService {
  static const String _storageKey = 'editor_options';

  /// Save EditorOptions to SharedPreferences
  static Future<void> save(EditorOptions options) async {
    final prefs = await SharedPreferences.getInstance();
    // Use the built-in toMonacoOptions method for robustness
    await prefs.setString(_storageKey, jsonEncode(options.toMonacoOptions()));
  }

  /// Load EditorOptions from SharedPreferences
  static Future<EditorOptions> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      // Return default options from MonacoConstants
      return MonacoConstants.defaultOptions;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      // Use EditorOptions.fromJson factory
      return EditorOptions.fromJson(json);
    } catch (e) {
      // Return defaults on error
      return MonacoConstants.defaultOptions;
    }
  }

  /// Clear saved settings
  static Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_storageKey);
  }

  /// True if there are persisted editor options (used to detect first run)
  static Future<bool> hasSavedOptions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_storageKey);
  }
}
