import 'package:context_collector/context_collector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the PreferencesNotifier
final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, ExtensionPrefsWithLoading>(
  (ref) => PreferencesNotifier(),
);

// State class to include loading status
class ExtensionPrefsWithLoading {
  const ExtensionPrefsWithLoading({
    this.prefs = const ExtensionPrefs(),
    this.isLoading = true,
  });
  final ExtensionPrefs prefs;
  final bool isLoading;

  ExtensionPrefsWithLoading copyWith({
    ExtensionPrefs? prefs,
    bool? isLoading,
  }) {
    return ExtensionPrefsWithLoading(
      prefs: prefs ?? this.prefs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PreferencesNotifier extends StateNotifier<ExtensionPrefsWithLoading> {
  PreferencesNotifier() : super(const ExtensionPrefsWithLoading()) {
    _loadPreferences();
  }

  static const String _prefsKey = 'extension_preferences';

  // Getters for convenience, accessing prefs from the state object
  ExtensionPrefs get _prefs => state.prefs;
  Map<String, FileCategory> get activeExtensions => _prefs.activeExtensions;

  Map<FileCategory, List<MapEntry<String, bool>>> get groupedExtensions {
    final result = <FileCategory, List<MapEntry<String, bool>>>{};

    for (final entry in ExtensionCatalog.extensionCategories.entries) {
      final category = entry.value;
      final isEnabled = !_prefs.disabledExtensions.contains(entry.key);
      result.putIfAbsent(category, () => []);
      result[category]!.add(MapEntry(entry.key, isEnabled));
    }

    for (final entry in _prefs.customExtensions.entries) {
      final category = entry.value;
      result.putIfAbsent(category, () => []);
      result[category]!.add(MapEntry(entry.key, true));
    }

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
        state = state.copyWith(
            prefs: ExtensionPrefs.fromJsonString(prefsJson), isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setString(_prefsKey, state.prefs.encode());
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  Future<void> toggleExtension(String extension) async {
    ExtensionPrefs newPrefs;
    final isDefault =
        ExtensionCatalog.extensionCategories.containsKey(extension);

    if (isDefault) {
      if (_prefs.disabledExtensions.contains(extension)) {
        newPrefs = _prefs.enableExtension(extension);
      } else {
        newPrefs = _prefs.disableExtension(extension);
      }
    } else {
      newPrefs = _prefs.removeCustomExtension(extension);
    }
    state = state.copyWith(prefs: newPrefs);
    await _savePreferences();
  }

  Future<void> addCustomExtension(
      String extension, FileCategory category) async {
    if (extension.isEmpty || !extension.startsWith('.')) {
      throw ArgumentError('Invalid extension format');
    }
    final ext = extension.toLowerCase();
    if (ExtensionCatalog.extensionCategories.containsKey(ext) ||
        _prefs.customExtensions.containsKey(ext)) {
      throw ArgumentError('Extension already exists');
    }

    var newPrefs = _prefs.addCustomExtension(ext, category);
    if (newPrefs.disabledExtensions.contains(ext)) {
      newPrefs = newPrefs.enableExtension(ext);
    }
    state = state.copyWith(prefs: newPrefs);
    await _savePreferences();
  }

  Future<void> resetToDefaults() async {
    state = state.copyWith(prefs: const ExtensionPrefs());
    await _savePreferences();
  }

  Future<void> enableAll() async {
    state = state.copyWith(prefs: _prefs.copyWith(disabledExtensions: {}));
    await _savePreferences();
  }

  Future<void> disableAll() async {
    state = state.copyWith(
        prefs: _prefs.copyWith(
      disabledExtensions: ExtensionCatalog.extensionCategories.keys.toSet(),
    ));
    await _savePreferences();
  }
}
