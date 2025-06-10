import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/model/editor_settings.dart';

/// Service responsible for persisting and loading editor settings
class EditorSettingsServiceHelper {
  static const String _storageKey = 'editor_settings';

  /// Save settings to SharedPreferences as a single JSON string
  static Future<void> save(EditorSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = settings.toJson();
    await prefs.setString(_storageKey, json.encode());
  }

  /// Load settings from SharedPreferences
  static Future<EditorSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      return const EditorSettings();
    }

    try {
      final json = jsonString.decode();
      final jsonMap = ConvertObject.toMap<String, dynamic>(json);
      return EditorSettings.fromJson(jsonMap);
    } catch (e) {
      // If parsing fails, return default settings
      return const EditorSettings();
    }
  }

  /// Clear all saved settings
  static Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_storageKey);
  }
}
