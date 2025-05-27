// lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'src/features/editor/assets_manager/notifier.dart';
import 'src/features/editor/services/monaco_editor_providers.dart';
import 'src/features/editor/presentation/ui/global_monaco_container.dart';
import 'src/features/editor/services/monaco_editor_state.dart';
import 'src/features/editor/utils/webview_platform_utils.dart';
import 'src/features/scan/presentation/ui/home_screen.dart';
import 'src/shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window for desktop
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1400, 850),
    minimumSize: Size(1400, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Context Collector',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Check platform compatibility first
  final platformInfo = await WebViewPlatformUtils.getPlatformInfo();
  debugPrint('WebView Platform Info: $platformInfo');

  // For Windows, check WebView2 availability
  if (Platform.isWindows && !platformInfo.isSupported) {
    runApp(
      const ProviderScope(
        child: WebView2MissingApp(),
      ),
    );
    return;
  }

  // Create ProviderScope container for early access
  final container = ProviderContainer();

  // 🤫 START MONACO ASSETS SILENTLY IN BACKGROUND
  _startMonacoAssetsSilently(container);

  // 🚀 START EDITOR PRELOADING (will wait for assets automatically)
  _startEditorPreloading(container);

  // Run the main app normally - no loading screens!
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ContextCollectorApp(),
    ),
  );
}

/// Start Monaco asset copying silently in background - no UI indication
void _startMonacoAssetsSilently(ProviderContainer container) {
  debugPrint(
      '[ContextCollector] 🤫 Starting Monaco assets SILENTLY in background...');

  // Fire and forget - completely silent, no UI changes
  container
      .read(monacoAssetManagerProvider)
      .initializeAssets()
      .then((assetPath) {
    debugPrint(
        '[ContextCollector] ✅ Monaco assets ready silently at: $assetPath');
  }).catchError((dynamic error) {
    // Silent failure - will be retried when user actually needs the editor
    debugPrint(
        '[ContextCollector] ⚠️ Silent Monaco asset initialization failed: $error');
  });
}

/// Start editor preloading - will automatically wait for assets
void _startEditorPreloading(ProviderContainer container) {
  debugPrint('[ContextCollector] 🚀 Starting editor preloading...');
  
  // The service provider will automatically listen to asset status
  // and initialize the editor when assets are ready
  container.read(monacoEditorServiceProvider);
  
  // Also listen to status for debugging
  container.listen<MonacoEditorStatus>(
    monacoEditorStatusProvider,
    (previous, next) {
      debugPrint('[ContextCollector] Editor status changed: ${previous?.state} → ${next.state}');
      debugPrint('  Progress: ${(next.progress * 100).toInt()}%');
      debugPrint('  Is Visible: ${next.isVisible}');
      debugPrint('  Has Content: ${next.hasContent}');
      if (next.error != null) {
        debugPrint('  Error: ${next.error}');
      }
    },
  );
  
  // Check initial state
  final initialStatus = container.read(monacoEditorStatusProvider);
  debugPrint('[ContextCollector] Initial editor status: ${initialStatus.state}');
}

class WebView2MissingApp extends StatelessWidget {
  const WebView2MissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Context Collector',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'WebView2 Runtime Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Context Collector requires Microsoft Edge WebView2 Runtime to function on Windows.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton.icon(
                      onPressed: () =>
                          WebViewPlatformUtils.showWebView2InstallDialog(
                              context),
                      icon: const Icon(Icons.download),
                      label: const Text('Install WebView2 Runtime'),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const TextButton(
                  onPressed: main,
                  child: Text('Recheck After Installation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContextCollectorApp extends ConsumerWidget {
  const ContextCollectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Context Collector',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: WebViewPlatformUtils.buildCompatibilityChecker(
        // Wrap with GlobalMonacoContainer to ensure editor is always present
        child: const GlobalMonacoContainer(
          child: HomeScreen(),
        ),
        fallback: const UnsupportedPlatformScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UnsupportedPlatformScreen extends ConsumerWidget {
  const UnsupportedPlatformScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Context Collector'),
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
                'Context Collector requires a supported WebView implementation.',
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
                      'Supported Platforms:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      'Windows 10/11 with WebView2 Runtime',
                      'macOS 10.13 or later',
                      'Android 5.0 or later',
                      'iOS 11.0 or later',
                    ].map(
                      (platform) => Padding(
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
                                platform,
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
                  onPressed: () =>
                      WebViewPlatformUtils.showWebView2InstallDialog(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Install WebView2 Runtime'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final newInfo =
                        await WebViewPlatformUtils.getPlatformInfo();
                    if (newInfo.isSupported && context.mounted) {
                      main();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recheck After Installation'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () {
                    // Could show more platform-specific information
                  },
                  child: const Text('Learn More'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
