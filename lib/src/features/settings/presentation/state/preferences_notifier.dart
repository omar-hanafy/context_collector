import 'dart:convert';

import 'package:context_collector/src/features/settings/domain/filter_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the PreferencesNotifier
final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, FilterSettingsWithLoading>(
      (ref) => PreferencesNotifier(),
    );

// State class to include loading status
class FilterSettingsWithLoading {
  const FilterSettingsWithLoading({
    this.settings = const FilterSettings(),
    this.isLoading = true,
  });
  final FilterSettings settings;
  final bool isLoading;

  FilterSettingsWithLoading copyWith({
    FilterSettings? settings,
    bool? isLoading,
  }) {
    return FilterSettingsWithLoading(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PreferencesNotifier extends StateNotifier<FilterSettingsWithLoading> {
  PreferencesNotifier() : super(const FilterSettingsWithLoading()) {
    _loadPreferences();
  }

  static const String _prefsKey = 'filter_settings';

  Future<void> _loadPreferences() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final prefsJson = sharedPrefs.getString(_prefsKey);
      if (prefsJson != null) {
        final json = jsonDecode(prefsJson) as Map<String, dynamic>;
        state = state.copyWith(
          settings: FilterSettings.fromJson(json),
          isLoading: false,
        );
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
      final json = state.settings.toJson();
      await sharedPrefs.setString(_prefsKey, jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  Future<void> addToBlacklist(String pattern) async {
    if (pattern.isEmpty) {
      throw ArgumentError('Pattern cannot be empty.');
    }
    final newSet = Set<String>.from(state.settings.blacklistedExtensions)
      ..add(pattern.toLowerCase());
    state = state.copyWith(
      settings: state.settings.copyWith(blacklistedExtensions: newSet),
    );
    await _savePreferences();
  }

  Future<void> removeFromBlacklist(String extension) async {
    final newSet = Set<String>.from(state.settings.blacklistedExtensions)
      ..remove(extension.toLowerCase());
    state = state.copyWith(
      settings: state.settings.copyWith(blacklistedExtensions: newSet),
    );
    await _savePreferences();
  }

  Future<void> resetToDefaults() async {
    state = state.copyWith(settings: const FilterSettings());
    await _savePreferences();
  }
}
