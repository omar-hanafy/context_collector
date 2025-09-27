// lib/main.dart
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

// RouteObserver no longer used; editor is presented via push/pop

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

  // Wire Selection → DirectoryTree before any drops or navigation occur.
  // This eliminates a race where a very-early drop happens before the
  // tree is connected, leaving the initial scan invisible.
  container
      .read(selectionProvider.notifier)
      .initializeDirectoryTree(
        container.read(directoryTreeAdapterProvider),
      );

  // Initialize desktop_drop early and listen for global Dock/Finder drops.
  // This handler processes both files and memory-backed text dropped onto the
  // app icon (global, Offset.zero). In-window drops are handled by widget
  // DropTargets (without catchAppWideDrops).
  DesktopDrop.instance.addRawDropEventListener((event) async {
    if (event is! DropDoneEvent) return;
    // Only treat Dock/Finder (application-level) drops here to avoid duplicate
    // handling with in-window DropTargets.
    final cameFromDockOrFinder = event.location == Offset.zero;
    if (!cameFromDockOrFinder) return;

    final fileItems = <XFile>[];
    final textPayloads = <String>{};

    for (final item in event.files) {
      if (item.isMemoryBacked && item.isTextLike) {
        try {
          final text = await item.readAsText();
          final normalized = text?.trim();
          if (normalized != null && normalized.isNotEmpty) {
            textPayloads.add(normalized);
          }
        } catch (_) {}
        continue;
      }
      fileItems.add(item);
    }

    // Handle files dropped onto the Dock/Finder globally (regardless of session state)
    if (fileItems.isNotEmpty) {
      await container
          .read(selectionProvider.notifier)
          .processDroppedItems(fileItems);
    }
    // For pure text/links (no files in this drop): create a virtual file and prompt to rename.
    if (fileItems.isEmpty) {
      for (final text in textPayloads) {
        container
            .read(selectionProvider.notifier)
            .createVirtualFileWithAutoName(text, promptForName: true);
      }
    }
  });

  DesktopDrop.instance.init();

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

// Monaco preloading removed; editor is created on the editor route

/// Initialize auto updater for automatic updates
void _initializeAutoUpdater(ProviderContainer container) {
  // Enable only on macOS. For Windows Store builds, updates are handled by the Store.
  if (!Platform.isMacOS) {
    debugPrint('[ContextCollector] Auto updater disabled on this platform');
    return;
  }

  debugPrint('[ContextCollector] 🔄 Initializing auto updater...');

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
      home: const SessionNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}
