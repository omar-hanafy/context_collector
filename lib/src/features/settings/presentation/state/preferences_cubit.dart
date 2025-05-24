import 'package:context_collector/context_collector.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State management for user preferences
/// Renamed from SettingsProvider for clarity about its purpose
class PreferencesCubit with ChangeNotifier {
  PreferencesCubit() {
    _loadPreferences();
  }

  static const String _prefsKey = 'extension_preferences';

  ExtensionPrefs _prefs = const ExtensionPrefs();
  bool _isLoading = true;

  ExtensionPrefs get preferences => _prefs;
  bool get isLoading => _isLoading;

  /// Get all active extensions
  Map<String, FileCategory> get activeExtensions => _prefs.activeExtensions;

  /// Get all available extensions grouped by category
  Map<FileCategory, List<MapEntry<String, bool>>> get groupedExtensions {
    final result = <FileCategory, List<MapEntry<String, bool>>>{};

    // Add default extensions from catalog
    for (final entry in ExtensionCatalog.extensionCategories.entries) {
      final category = entry.value;
      final isEnabled = !_prefs.disabledExtensions.contains(entry.key);

      result.putIfAbsent(category, () => []);
      result[category]!.add(MapEntry(entry.key, isEnabled));
    }

    // Add custom extensions
    for (final entry in _prefs.customExtensions.entries) {
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

  Future<void> _loadPreferences() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final prefsJson = sharedPrefs.getString(_prefsKey);

      if (prefsJson != null) {
        _prefs = ExtensionPrefs.fromJsonString(prefsJson);
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _savePreferences() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setString(_prefsKey, _prefs.encode());
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  /// Toggle extension enabled/disabled state
  Future<void> toggleExtension(String extension) async {
    final isDefault =
        ExtensionCatalog.extensionCategories.containsKey(extension);

    if (isDefault) {
      // For default extensions, add/remove from disabled list
      if (_prefs.disabledExtensions.contains(extension)) {
        _prefs = _prefs.enableExtension(extension);
      } else {
        _prefs = _prefs.disableExtension(extension);
      }
    } else {
      // For custom extensions, remove from custom list
      _prefs = _prefs.removeCustomExtension(extension);
    }

    await _savePreferences();
    notifyListeners();
  }

  /// Add a custom extension
  Future<void> addCustomExtension(
      String extension, FileCategory category) async {
    if (extension.isEmpty || !extension.startsWith('.')) {
      throw ArgumentError('Invalid extension format');
    }

    final ext = extension.toLowerCase();

    // Check if it already exists
    if (ExtensionCatalog.extensionCategories.containsKey(ext) ||
        _prefs.customExtensions.containsKey(ext)) {
      throw ArgumentError('Extension already exists');
    }

    _prefs = _prefs.addCustomExtension(ext, category);

    // Remove from disabled if it was there
    if (_prefs.disabledExtensions.contains(ext)) {
      _prefs = _prefs.enableExtension(ext);
    }

    await _savePreferences();
    notifyListeners();
  }

  /// Reset to default preferences
  Future<void> resetToDefaults() async {
    _prefs = const ExtensionPrefs();
    await _savePreferences();
    notifyListeners();
  }

  /// Enable all extensions
  Future<void> enableAll() async {
    _prefs = _prefs.copyWith(disabledExtensions: {});
    await _savePreferences();
    notifyListeners();
  }

  /// Disable all default extensions (except custom ones)
  Future<void> disableAll() async {
    _prefs = _prefs.copyWith(
      disabledExtensions: ExtensionCatalog.extensionCategories.keys.toSet(),
    );
    await _savePreferences();
    notifyListeners();
  }
}
