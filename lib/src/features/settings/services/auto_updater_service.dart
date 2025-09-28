import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [AutoUpdaterService] used to bootstrap platform update hooks.
final autoUpdaterServiceProvider = Provider<AutoUpdaterService>((ref) {
  return const AutoUpdaterService();
});

/// Minimal auto update stub that keeps the analyzer happy and allows future
/// wiring into Sparkle or WinSparkle as needed.
class AutoUpdaterService {
  const AutoUpdaterService();

  Future<void> initialize() async {
    if (!Platform.isMacOS) {
      debugPrint('[AutoUpdater] Skipping initialization on non-macOS platform');
      return;
    }

    // TODO(maintainers): wire up Sparkle or your macOS updater of choice here.
    debugPrint('[AutoUpdater] Ready (no-op stub)');
  }
}
