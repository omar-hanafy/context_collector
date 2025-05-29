// lib/src/features/editor/utils/webview_platform_utils.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart' as ww;

/// Utilities for WebView platform compatibility and setup
class WebViewPlatformUtils {
  static Future<WebViewPlatformInfo> getPlatformInfo() async {
    if (Platform.isWindows) {
      try {
        final version = await ww.WebviewController.getWebViewVersion();
        return WebViewPlatformInfo(
          platform: 'Windows',
          isSupported: version != null,
          version: version,
          engine: 'WebView2',
          requirements: [
            'Windows 10 version 1809 or later',
            'Microsoft Edge WebView2 Runtime',
          ],
        );
      } catch (e) {
        return WebViewPlatformInfo(
          platform: 'Windows',
          isSupported: false,
          error: e.toString(),
          engine: 'WebView2',
          requirements: [
            'Windows 10 version 1809 or later',
            'Microsoft Edge WebView2 Runtime',
          ],
        );
      }
    } else if (Platform.isMacOS) {
      return const WebViewPlatformInfo(
        platform: 'macOS',
        isSupported: true,
        engine: 'WebKit',
        requirements: ['macOS 10.13 or later'],
      );
    } else {
      return WebViewPlatformInfo(
        platform: Platform.operatingSystem,
        isSupported: false,
        error: 'Context Collector only supports macOS and Windows',
        requirements: ['macOS 10.13+ or Windows 10/11 with WebView2'],
        engine: '',
      );
    }
  }

  static Future<void> showWebView2InstallDialog(BuildContext context) async {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.download_rounded, size: 48),
          title: const Text('WebView2 Runtime Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Context Collector requires Microsoft Edge WebView2 Runtime to function properly on Windows.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Installation Steps:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Click "Download WebView2" below\n'
                      '2. Download the installer from Microsoft\n'
                      '3. Run the installer as Administrator\n'
                      '4. Restart Context Collector',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await _launchWebView2Download();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Download WebView2'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _launchWebView2Download() async {
    const url =
        'https://developer.microsoft.com/en-us/microsoft-edge/webview2/';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      debugPrint(
          '[WebViewPlatformUtils] Error launching WebView2 download: $e');
    }
  }

  static Widget buildCompatibilityChecker({
    required Widget child,
    required Widget fallback,
  }) {
    return FutureBuilder<WebViewPlatformInfo>(
      future: getPlatformInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking platform compatibility...'),
                ],
              ),
            ),
          );
        }

        final info = snapshot.data;
        if (info?.isSupported ?? false) {
          return child;
        } else {
          return _buildUnsupportedPlatform(info);
        }
      },
    );
  }

  static Widget _buildUnsupportedPlatform(WebViewPlatformInfo? info) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Context Collector'),
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Platform.isWindows
                        ? Icons.warning_amber_rounded
                        : Icons.devices_other,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Platform.isWindows
                        ? 'WebView2 Runtime Missing'
                        : 'Platform Not Supported',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info?.error ?? 'Unknown compatibility issue',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requirements:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...?info?.requirements.map(
                          (req) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    req,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (Platform.isWindows) ...[
                    FilledButton.icon(
                      onPressed: () => showWebView2InstallDialog(context),
                      icon: const Icon(Icons.download),
                      label: const Text('Install WebView2 Runtime'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        // Restart the app check
                        final newInfo = await getPlatformInfo();
                        if (newInfo.isSupported && context.mounted) {
                          // Trigger app restart or navigation
                          await Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recheck After Installation'),
                    ),
                  ] else ...[
                    OutlinedButton(
                      onPressed: () {
                        // Maybe show more info or exit gracefully
                      },
                      child: const Text('Learn More'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Check if running in development/debug mode
  static bool get isDebugMode => kDebugMode;

  /// Get platform-specific debugging information
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final info = await getPlatformInfo();

    return {
      'platform': info.platform,
      'isSupported': info.isSupported,
      'engine': info.engine,
      'version': info.version,
      'error': info.error,
      'requirements': info.requirements,
      'isDarkMode':
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark,
      'isDebugMode': isDebugMode,
      'dartVersion': Platform.version,
    };
  }
}

/// Information about WebView platform support
class WebViewPlatformInfo {
  const WebViewPlatformInfo({
    required this.platform,
    required this.isSupported,
    required this.engine,
    this.version,
    this.error,
    this.requirements = const [],
  });

  final String platform;
  final bool isSupported;
  final String? version;
  final String? error;
  final String engine;
  final List<String> requirements;

  @override
  String toString() {
    return 'WebViewPlatformInfo('
        'platform: $platform, '
        'supported: $isSupported, '
        'version: $version, '
        'engine: $engine, '
        'error: $error'
        ')';
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'isSupported': isSupported,
      'version': version,
      'error': error,
      'engine': engine,
      'requirements': requirements,
    };
  }
}
