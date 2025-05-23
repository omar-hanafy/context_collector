import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/cupertino.dart';

import '../config/file_extensions.dart';

@immutable
class ExtensionSettings {
  const ExtensionSettings({
    this.customExtensions = const {},
    this.disabledExtensions = const {},
  });

  factory ExtensionSettings.fromJson(Map<String, dynamic> json) {
    return ExtensionSettings(
      customExtensions: _parseCustomExtensions(json),
      disabledExtensions: _parseDisabledExtensions(json),
    );
  }

  factory ExtensionSettings.fromJsonString(String jsonString) {
    try {
      final decoded = jsonString.tryDecode();
      if (decoded == null) return const ExtensionSettings();

      return ExtensionSettings.fromJson(toMap<String, dynamic>(decoded));
    } catch (e) {
      return const ExtensionSettings();
    }
  }

  final Map<String, FileCategory> customExtensions;
  final Set<String> disabledExtensions;

  // Helper method to parse custom extensions using dart_helper_utils
  static Map<String, FileCategory> _parseCustomExtensions(
    Map<String, dynamic> json,
  ) {
    final customMap = json.tryGetMap<String, dynamic>('customExtensions');
    if (customMap == null) return const {};

    final result = <String, FileCategory>{};

    for (final entry in customMap.entries) {
      final categoryName = entry.value.toString();
      final category =
          FileCategory.values.firstWhereOrNull((c) => c.name == categoryName) ??
              FileCategory.other;

      result[entry.key] = category;
    }

    return result;
  }

  // Helper method to parse disabled extensions using dart_helper_utils
  static Set<String> _parseDisabledExtensions(Map<String, dynamic> json) {
    final disabledList = json.tryGetList<String>('disabledExtensions');
    return disabledList?.toSet() ?? const <String>{};
  }

  Map<String, dynamic> toJson() {
    return {
      'customExtensions': customExtensions.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'disabledExtensions': disabledExtensions.toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  ExtensionSettings copyWith({
    Map<String, FileCategory>? customExtensions,
    Set<String>? disabledExtensions,
  }) {
    return ExtensionSettings(
      customExtensions: customExtensions ?? this.customExtensions,
      disabledExtensions: disabledExtensions ?? this.disabledExtensions,
    );
  }

  // Get all active extensions (default + custom - disabled)
  Map<String, FileCategory> get activeExtensions {
    final result = Map<String, FileCategory>.from(
      FileExtensionConfig.extensionCategories,
    );

    // Remove disabled extensions
    for (final ext in disabledExtensions) {
      result.remove(ext);
    }

    // Add custom extensions (these override defaults)
    result.addAll(customExtensions);

    return result;
  }

  // Check if an extension is supported
  bool isSupported(String extension) {
    final ext = extension.toLowerCase();
    return activeExtensions.containsKey(ext);
  }

  // Get category for an extension
  FileCategory? getCategory(String extension) {
    final ext = extension.toLowerCase();
    return activeExtensions[ext];
  }

  // Additional utility methods

  /// Add a custom extension mapping
  ExtensionSettings addCustomExtension(
      String extension, FileCategory category) {
    final newCustom = Map<String, FileCategory>.from(customExtensions);
    newCustom[extension.toLowerCase()] = category;
    return copyWith(customExtensions: newCustom);
  }

  /// Remove a custom extension mapping
  ExtensionSettings removeCustomExtension(String extension) {
    final newCustom = Map<String, FileCategory>.from(customExtensions)
      ..remove(extension.toLowerCase());
    return copyWith(customExtensions: newCustom);
  }

  /// Disable an extension
  ExtensionSettings disableExtension(String extension) {
    final newDisabled = Set<String>.from(disabledExtensions)
      ..add(extension.toLowerCase());
    return copyWith(disabledExtensions: newDisabled);
  }

  /// Enable a previously disabled extension
  ExtensionSettings enableExtension(String extension) {
    final newDisabled = Set<String>.from(disabledExtensions)
      ..remove(extension.toLowerCase());
    return copyWith(disabledExtensions: newDisabled);
  }

  /// Get all extensions for a specific category
  Set<String> getExtensionsForCategory(FileCategory category) {
    return activeExtensions.entries
        .where((entry) => entry.value == category)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Check if any extensions are configured for a category
  bool hasCategorySupport(FileCategory category) {
    return activeExtensions.values.contains(category);
  }

  /// Get statistics about the configuration
  Map<String, int> get statistics {
    final stats = <String, int>{};

    // Count by category
    for (final category in FileCategory.values) {
      final count =
          activeExtensions.values.where((cat) => cat == category).length;
      if (count > 0) {
        stats[category.name] = count;
      }
    }

    stats['total'] = activeExtensions.length;
    stats['custom'] = customExtensions.length;
    stats['disabled'] = disabledExtensions.length;

    return stats;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExtensionSettings &&
        other.customExtensions.length == customExtensions.length &&
        other.disabledExtensions.length == disabledExtensions.length &&
        other.customExtensions.entries.every(
          (entry) => customExtensions[entry.key] == entry.value,
        ) &&
        other.disabledExtensions.every(disabledExtensions.contains);
  }

  @override
  int get hashCode {
    return Object.hash(
      customExtensions.entries
          .map((e) => Object.hash(e.key, e.value))
          .fold(0, (a, b) => a is num ? a.toInt() ^ b : 0),
      disabledExtensions.fold(
          0, (a, b) => a is num ? a.toInt() ^ b.hashCode : 0),
    );
  }

  @override
  String toString() {
    return 'ExtensionSettings('
        'customExtensions: ${customExtensions.length}, '
        'disabledExtensions: ${disabledExtensions.length}, '
        'totalActive: ${activeExtensions.length}'
        ')';
  }
}
