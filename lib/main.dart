// lib/main.dart
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

// Global RouteObserver for tracking navigation events
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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

  // 🚀 START EDITOR PRELOADING
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

/// Start editor preloading
void _startEditorPreloading(ProviderContainer container) {
  debugPrint('[ContextCollector] 🚀 Starting editor preloading...');

  // Initialize the Monaco service
  container.read(monacoEditorStatusProvider.notifier).initialize();

  // Listen to status for debugging
  container.listen<EditorStatus>(
    monacoEditorStatusProvider,
    (previous, next) {
      debugPrint(
        '[ContextCollector] Editor status changed: ${previous?.lifecycle} → ${next.lifecycle}',
      );
      if (next.error != null) {
        debugPrint('  Error: ${next.error}');
      }
    },
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
      // Register the route observer for navigation tracking
      navigatorObservers: [routeObserver],
      home: const GlobalMonacoContainer(
        child: HomeScreenWithDrop(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
