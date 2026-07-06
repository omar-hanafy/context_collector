import 'package:flutter/foundation.dart';

/// Central capability flags for platform-dependent features.
///
/// UI and state layers consult these flags instead of sprinkling `kIsWeb`
/// checks around. Every flag documents WHY the capability is absent so the
/// gating stays intentional rather than accidental.
abstract final class PlatformCaps {
  /// True when running in a browser.
  static const bool isWeb = kIsWeb;

  /// Browsers expose no real filesystem paths, so features built around
  /// absolute paths (copy full paths from disk, restore files by path,
  /// re-read files from disk) are desktop-only.
  static const bool supportsAbsolutePaths = !kIsWeb;

  /// `file_selector`'s getDirectoryPath is not implemented on web; folder
  /// input on web happens through drag-and-drop instead.
  static const bool supportsDirectoryPicker = !kIsWeb;

  /// Pasting filesystem paths only makes sense where the app can read
  /// arbitrary paths from disk.
  static const bool supportsPastePaths = !kIsWeb;

  /// Native window chrome (size, focus, listeners) exists on desktop only.
  static bool get supportsWindowManager =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);
}
