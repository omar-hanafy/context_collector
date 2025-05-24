import 'package:context_collector/extensions/theme_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/file_extensions.dart';
import '../models/extension_settings.dart';

class SettingsProvider with ChangeNotifier {
  SettingsProvider() {
    _loadSettings();
  }

  static const String _prefsKey = 'extension_settings';

  ExtensionSettings _settings = const ExtensionSettings();
  bool _isLoading = true;

  ExtensionSettings get settings => _settings;

  bool get isLoading => _isLoading;

  // Get all active extensions
  Map<String, FileCategory> get activeExtensions => _settings.activeExtensions;

  // Get all available extensions grouped by category
  Map<FileCategory, List<MapEntry<String, bool>>> get groupedExtensions {
    final result = <FileCategory, List<MapEntry<String, bool>>>{};

    // Add default extensions
    for (final entry in FileExtensionConfig.extensionCategories.entries) {
      final category = entry.value;
      final isEnabled = !_settings.disabledExtensions.contains(entry.key);

      result.putIfAbsent(category, () => []);
      result[category]!.add(MapEntry(entry.key, isEnabled));
    }

    // Add custom extensions
    for (final entry in _settings.customExtensions.entries) {
      final category = entry.value;

      result.putIfAbsent(category, () => []);
      result[category]!.add(MapEntry(entry.key, true));
    }

    // Sort extensions within each category
    for (final list in result.values) {
      list.sort((a, b) => a.key.compareTo(b.key));
    }

    return result;
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_prefsKey);

      if (settingsJson != null) {
        _settings = ExtensionSettings.fromJsonString(settingsJson);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _settings.encode());
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // Toggle extension enabled/disabled state
  Future<void> toggleExtension(String extension) async {
    final isDefault =
        FileExtensionConfig.extensionCategories.containsKey(extension);

    if (isDefault) {
      // For default extensions, add/remove from disabled list
      final newDisabled = Set<String>.from(_settings.disabledExtensions);

      if (newDisabled.contains(extension)) {
        newDisabled.remove(extension);
      } else {
        newDisabled.add(extension);
      }

      _settings = _settings.copyWith(disabledExtensions: newDisabled);
    } else {
      // For custom extensions, remove from custom list
      final newCustom =
          Map<String, FileCategory>.from(_settings.customExtensions)
            ..remove(extension);

      _settings = _settings.copyWith(customExtensions: newCustom);
    }

    await _saveSettings();
    notifyListeners();
  }

  // Add a custom extension
  Future<void> addCustomExtension(
      String extension, FileCategory category) async {
    if (extension.isEmpty || !extension.startsWith('.')) {
      throw ArgumentError('Invalid extension format');
    }

    final ext = extension.toLowerCase();

    // Check if it already exists
    if (FileExtensionConfig.extensionCategories.containsKey(ext) ||
        _settings.customExtensions.containsKey(ext)) {
      throw ArgumentError('Extension already exists');
    }

    final newCustom =
        Map<String, FileCategory>.from(_settings.customExtensions);
    newCustom[ext] = category;

    // Remove from disabled if it was there
    final newDisabled = Set<String>.from(_settings.disabledExtensions)
      ..remove(ext);

    _settings = _settings.copyWith(
      customExtensions: newCustom,
      disabledExtensions: newDisabled,
    );

    await _saveSettings();
    notifyListeners();
  }

  // Reset to default settings
  Future<void> resetToDefaults() async {
    _settings = const ExtensionSettings();
    await _saveSettings();
    notifyListeners();
  }

  // Enable all extensions
  Future<void> enableAll() async {
    _settings = _settings.copyWith(disabledExtensions: {});
    await _saveSettings();
    notifyListeners();
  }

  // Disable all extensions (except custom ones)
  Future<void> disableAll() async {
    _settings = _settings.copyWith(
      disabledExtensions: FileExtensionConfig.extensionCategories.keys.toSet(),
    );
    await _saveSettings();
    notifyListeners();
  }
}
