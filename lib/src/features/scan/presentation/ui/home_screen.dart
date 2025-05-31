// lib/src/features/scan/presentation/ui/home_screen.dart
import 'package:context_collector/context_collector.dart';
import 'package:context_collector/src/shared/consts.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Home screen overlay that shows when no files are selected
/// This is the top layer in the layered architecture
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Initial setup for supported extensions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final selectionNotifier = ref.read(selectionProvider.notifier);
        final prefsState = ref.read(preferencesProvider);
        selectionNotifier
            .setSupportedExtensions(prefsState.prefs.activeExtensions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for preference changes
    ref
      ..listen<ExtensionPrefsWithLoading>(preferencesProvider,
          (previous, next) {
        if (previous?.prefs.activeExtensions != next.prefs.activeExtensions) {
          ref
              .read(selectionProvider.notifier)
              .setSupportedExtensions(next.prefs.activeExtensions);
        }
      })

      // Listen for errors
      ..listen<SelectionState>(selectionProvider, (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: context.error,
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () =>
                    ref.read(selectionProvider.notifier).clearError(),
                textColor: context.onError,
              ),
            ),
          );
        }
      });

    final selectionNotifier = ref.read(selectionProvider.notifier);

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primary,
                    context.primary.addOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Context Collector'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final githubUrl =
                  Uri.parse('https://github.com/omar-hanafy/context_collector');
              if (!await launchUrl(githubUrl)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open GitHub')),
                  );
                }
              }
            },
            icon: SvgPicture.asset(
              context.isDark ? AppAssets.githubLight : AppAssets.githubDark,
              width: 20,
              height: 20,
            ),
            tooltip: 'View on GitHub',
          ),
          IconButton(
            onPressed: () async {
              final coffeeUrl =
                  Uri.parse('https://www.buymeacoffee.com/omar.hanafy');
              if (!await launchUrl(coffeeUrl)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Could not open Buy Me a Coffee')),
                  );
                }
              }
            },
            icon: SvgPicture.asset(
              context.isDark ? AppAssets.logoLight : AppAssets.logoDark,
              width: 20,
              height: 20,
            ),
            tooltip: 'Buy Me a Coffee',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DropTarget(
        onDragEntered: (details) {
          setState(() => _isDragging = true);
        },
        onDragExited: (details) {
          setState(() => _isDragging = false);
        },
        onDragDone: (details) async {
          setState(() => _isDragging = false);

          if (details.files.isEmpty) return;

          // Use the new batch processor for all dropped items
          await selectionNotifier.processDroppedItems(details.files);
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isDragging
                  ? context.primary.addOpacity(0.1)
                  : Colors.transparent,
              border: _isDragging
                  ? Border.all(
                      color: context.primary.addOpacity(0.5),
                      width: 2,
                    )
                  : null,
            ),
            child: const DropZoneWidget(),
          ),
        ),
      ),
    );
  }
}
