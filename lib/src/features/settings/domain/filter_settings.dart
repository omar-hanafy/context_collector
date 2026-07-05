import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/foundation.dart';

/// Manages a simple blacklist of file extensions to be ignored during scans.
@immutable
class FilterSettings {
  const FilterSettings({
    this.blacklistedExtensions = defaultBlacklist,
  });

  factory FilterSettings.fromJson(Map<String, dynamic> json) {
    final extensions = json.tryGetList<String>('blacklistedExtensions');
    return FilterSettings(
      blacklistedExtensions: _migrateBlacklist(extensions?.toSet()),
    );
  }

  /// A default set of extensions that are typically not useful for context collection.
  static const Set<String> defaultBlacklist = {
    // System & Editor Junk
    '.ds_store',
    'thumbs.db',

    // Logs & Temporary Files
    '.log',
    '.tmp',
    '.bak',
    '.swp',

    // Dart/Flutter Generated Files
    '.g.dart',
    '.freezed.dart',
    '.gr.dart',
    '.reflectable.dart',
    '_test.reflectable.dart',

    // Compiled Code & Artifacts
    '.exe', '.dll', '.so', '.o', '.a', // Generic binaries
    '.pyc', // Python
    '.class', '.jar', // Java/JVM
    '.map', // Source Maps
    // Common Non-Code / Media Files
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico',
    '.mp4', '.mov', '.mp3', '.wav',
    '.pdf',
    '.zip', '.rar', '.gz', '.7z',

    // Dependency Lock Files (very noisy)
    'package-lock.json',
    'yarn.lock',
    'pubspec.lock',
    'composer.lock',
    'gemfile.lock',
    'podfile.lock',
  };

  /// The set of file extensions (e.g., '.log') to ignore.
  final Set<String> blacklistedExtensions;

  static Set<String> _migrateBlacklist(Set<String>? extensions) {
    if (extensions == null) return defaultBlacklist;

    // SVG used to be grouped with binary media. It is text-based XML and is now
    // supported by default, including for users with older saved preferences.
    return {...extensions}..remove('.svg');
  }

  Map<String, dynamic> toJson() {
    return {
      'blacklistedExtensions': blacklistedExtensions.toList(),
    };
  }

  FilterSettings copyWith({
    Set<String>? blacklistedExtensions,
  }) {
    return FilterSettings(
      blacklistedExtensions:
          blacklistedExtensions ?? this.blacklistedExtensions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterSettings &&
          setEquals(other.blacklistedExtensions, blacklistedExtensions);

  @override
  int get hashCode => Object.hashAll(blacklistedExtensions);
}
