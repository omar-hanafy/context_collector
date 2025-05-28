import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the auto updater service
final autoUpdaterServiceProvider = Provider<AutoUpdaterService>((ref) {
  return AutoUpdaterService();
});

/// Service to manage automatic updates
class AutoUpdaterService {
  // Production update feed URL - hosted on GitHub Pages
  static const String _productionFeedUrl = 'https://omar-hanafy.github.io/context_collector/appcast.xml';
  
  // Development/testing feed URL
  static const String _developmentFeedUrl = 'http://localhost:5002/appcast.xml';
  
  /// Initialize the auto updater
  Future<void> initialize() async {
    try {
      // Use development URL in debug mode, production URL in release mode
      const feedUrl = kDebugMode ? _developmentFeedUrl : _productionFeedUrl;
      
      await autoUpdater.setFeedURL(feedUrl);
      
      // Set automatic check interval to 6 hours (21600 seconds)
      await autoUpdater.setScheduledCheckInterval(21600);
      
      debugPrint('Auto updater initialized with feed URL: $feedUrl');
    } catch (e) {
      debugPrint('Failed to initialize auto updater: $e');
    }
  }
  
  /// Manually check for updates
  Future<void> checkForUpdates() async {
    try {
      await autoUpdater.checkForUpdates();
    } catch (e) {
      debugPrint('Failed to check for updates: $e');
      rethrow;
    }
  }
  
  /// Get the current feed URL
  Future<String?> getFeedURL() async {
    try {
      // Note: auto_updater doesn't provide a getter for feed URL
      // We'll return our configured URL instead
      return kDebugMode ? _developmentFeedUrl : _productionFeedUrl;
    } catch (e) {
      debugPrint('Failed to get feed URL: $e');
      return null;
    }
  }
  
  /// Set a custom feed URL
  Future<void> setFeedURL(String url) async {
    try {
      await autoUpdater.setFeedURL(url);
      debugPrint('Feed URL updated to: $url');
    } catch (e) {
      debugPrint('Failed to set feed URL: $e');
      rethrow;
    }
  }
  
  /// Set the automatic check interval in seconds
  /// Minimum: 3600 (1 hour), 0 to disable
  Future<void> setCheckInterval(int seconds) async {
    try {
      await autoUpdater.setScheduledCheckInterval(seconds);
      debugPrint('Update check interval set to: $seconds seconds');
    } catch (e) {
      debugPrint('Failed to set check interval: $e');
      rethrow;
    }
  }
}
