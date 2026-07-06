import 'package:context_collector/context_collector.dart';
import 'package:context_collector/src/shared/platform/app_window/app_window.dart';
import 'package:context_collector/src/shared/platform/platform_caps.dart';
import 'package:context_collector/src/shared/utils/debug_logger.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window for desktop (no-op on web)
  if (PlatformCaps.supportsWindowManager) {
    await configureDesktopWindow();
  }

  // Create ProviderScope container for early access
  final rootContainer = ProviderContainer();

  final initialSession = rootContainer
      .read(sessionManagerProvider.notifier)
      .createSession();
  rootContainer.read(activeSessionIdProvider.notifier).state =
      initialSession.id;

  // Initialize desktop_drop early and listen for global Dock/Finder drops.
  // This handler processes both files and memory-backed text dropped onto the
  // app icon (global, Offset.zero). In-window drops are handled by widget
  // DropTargets (without catchAppWideDrops).
  DesktopDrop.instance.addRawDropEventListener((event) async {
    if (event is! DropDoneEvent) return;

    logDropEvent(event, source: 'Main/GlobalListener');

    // Only treat Dock/Finder (application-level) drops here to avoid duplicate
    // handling with in-window DropTargets.
    final cameFromDockOrFinder = event.location == Offset.zero;
    if (!cameFromDockOrFinder) return;
    final split = await DropPayloadSplitter.fromRawEvent(event);

    // Handle files dropped onto the Dock/Finder globally (regardless of session state)
    if (split.hasFiles) {
      final targetContainer = _resolveActiveSessionContainer(rootContainer);
      await targetContainer
          .read(selectionProvider.notifier)
          .processDroppedItems(split.files);
    }
    // For pure text/links (no files in this drop): create a virtual file and prompt to rename.
    if (split.hasTextOnly) {
      for (final text in split.texts) {
        final targetContainer = _resolveActiveSessionContainer(rootContainer);
        targetContainer
            .read(selectionProvider.notifier)
            .createVirtualFileWithAutoName(text, promptForName: true);
      }
    }
  });

  DesktopDrop.instance.init();

  // Run the main app normally - no loading screens!
  runApp(
    UncontrolledProviderScope(
      container: rootContainer,
      child: const ContextCollectorApp(),
    ),
  );
}

ProviderContainer _resolveActiveSessionContainer(
  ProviderContainer rootContainer,
) {
  var sessions = rootContainer.read(sessionManagerProvider);
  if (sessions.isEmpty) {
    final entry = rootContainer
        .read(sessionManagerProvider.notifier)
        .createSession();
    rootContainer.read(activeSessionIdProvider.notifier).state = entry.id;
    sessions = rootContainer.read(sessionManagerProvider);
  }

  final activeId = rootContainer.read(activeSessionIdProvider);

  SessionEntry targetEntry;
  if (activeId != null) {
    targetEntry = sessions.firstWhere(
      (entry) => entry.id == activeId,
      orElse: () => sessions.last,
    );
  } else {
    targetEntry = sessions.last;
    rootContainer.read(activeSessionIdProvider.notifier).state = targetEntry.id;
  }

  return targetEntry.container;
}

// Monaco preloading removed; editor is created on the editor route

class ContextCollectorApp extends ConsumerWidget {
  const ContextCollectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    // Root-navigator instance: showDialog defaults to useRootNavigator: true,
    // so app dialogs land here. It reports into the app-wide
    // ModalOverlayCoordinator so Monaco iframes go inert on web while any
    // dialog floats above them (no-op on desktop).
    final modalOverlayObserver = ref.watch(modalOverlayObserverProvider);

    return MaterialApp(
      title: 'Context Collector',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorObservers: [modalOverlayObserver],
      home: const TabShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
