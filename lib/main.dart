// lib/main.dart
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window for desktop
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
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

  // Create ProviderScope container for early access
  final container = ProviderContainer();

  // 🤫 START MONACO ASSETS SILENTLY IN BACKGROUND
  _startMonacoAssetsSilently(container);

  // 🚀 START EDITOR PRELOADING (will wait for assets automatically)
  _startEditorPreloading(container);

  // 🔄 INITIALIZE AUTO UPDATER
  _initializeAutoUpdater(container);

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
    '[ContextCollector] 🤫 Starting Monaco assets SILENTLY in background...',
  );

  // Fire and forget - completely silent, no UI changes
  container
      .read(monacoProvider.notifier)
      .initialize()
      .then((_) {
        debugPrint('[ContextCollector] ✅ Monaco assets ready silently');
      })
      .catchError((dynamic error) {
        // Silent failure - will be retried when user actually needs the editor
        debugPrint(
          '[ContextCollector] ⚠️ Silent Monaco asset initialization failed: $error',
        );
      });
}

/// Start editor preloading - will automatically wait for assets
void _startEditorPreloading(ProviderContainer container) {
  debugPrint('[ContextCollector] 🚀 Starting editor preloading...');

  // The service provider will automatically listen to asset status
  // and initialize the editor when assets are ready
  container
    ..read(monacoEditorServiceProvider)
    // Also listen to status for debugging
    ..listen<EditorStatus>(
      monacoEditorStatusProvider,
      (previous, next) {
        debugPrint(
          '[ContextCollector] Editor status changed: ${previous?.lifecycle} → ${next.lifecycle}',
        );
        debugPrint('  Has Content: ${next.hasContent}');
        if (next.error != null) {
          debugPrint('  Error: ${next.error}');
        }
      },
    );

  // Check initial state
  final initialStatus = container.read(monacoEditorStatusProvider);
  debugPrint(
    '[ContextCollector] Initial editor status: ${initialStatus.lifecycle}',
  );
}

/// Initialize auto updater for automatic updates
void _initializeAutoUpdater(ProviderContainer container) {
  // Only initialize on supported platforms
  if (!Platform.isMacOS && !Platform.isWindows) {
    debugPrint(
      '[ContextCollector] Auto updater not supported on this platform',
    );
    return;
  }

  debugPrint('[ContextCollector] 🔄 Initializing auto updater...');

  // Initialize auto updater service
  container
      .read(autoUpdaterServiceProvider)
      .initialize()
      .then((_) {
        debugPrint(
          '[ContextCollector] ✅ Auto updater initialized successfully',
        );
      })
      .catchError((dynamic error) {
        debugPrint(
          '[ContextCollector] ⚠️ Auto updater initialization failed: $error',
        );
      });
}

class ContextCollectorApp extends ConsumerWidget {
  const ContextCollectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Context Collector',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: WebViewPlatformUtils.buildCompatibilityChecker(
        // Wrap with GlobalMonacoContainer to ensure editor is always present
        child: const GlobalMonacoContainer(
          child: HomeScreenWithDrop(),
        ),
        // The fallback is handled by buildCompatibilityChecker itself
        fallback: const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
