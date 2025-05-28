// lib/src/features/scan/presentation/ui/home_screen.dart
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:context_collector/src/shared/consts.dart';
import 'package:context_collector/src/shared/utils/drop_file_resolver.dart';
import 'package:context_collector/src/shared/utils/vscode_drop_detector.dart';
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
  
  // Helper method to process children of DropItemDirectory recursively
  Future<void> _processDropItemChildren(
    List<DropItem> children,
    List<String> files,
    List<String> directories,
  ) async {
    for (final child in children) {
      if (child is DropItemDirectory) {
        directories.add(child.path);
        await _processDropItemChildren(child.children, files, directories);
      } else if (child is DropItemFile) {
        files.add(child.path);
      }
    }
  }
  

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

          final files = <String>[];
          final directories = <String>[];

          for (final item in details.files) {
            final filePath = item.path;
            
            // Check if this is a VS Code directory drop
            if (filePath.contains('/tmp/Drops/')) {
              try {
                // Try to read as VS Code directory listing
                final content = await File(filePath).readAsString();
                final directoryPath = VSCodeDropDetector.extractDirectoryPath(content);
                
                if (directoryPath != null) {
                  // Just add the directory path and let normal error handling deal with permissions
                  directories.add(directoryPath);
                  continue;
                }
              } catch (_) {
                // Not a VS Code directory listing, process normally
              }
            }
            
            // Handle typed drops (desktop_drop 0.6.0+)
            if (item is DropItemDirectory) {
              directories.add(filePath);
              await _processDropItemChildren(item.children, files, directories);
            } else if (item is DropItemFile) {
              files.add(filePath);
            } else {
              // Fallback for regular XFile - use filesystem check
              final entity = FileSystemEntity.typeSync(filePath);
              if (entity == FileSystemEntityType.directory) {
                directories.add(filePath);
              } else if (entity == FileSystemEntityType.file) {
                files.add(filePath);
              } else if (DropFileResolver.isTemporaryDropFile(filePath)) {
                // Handle other temporary drop files
                try {
                  final testFile = File(filePath);
                  if (testFile.existsSync() && testFile.statSync().type == FileSystemEntityType.file) {
                    files.add(filePath);
                  }
                } catch (_) {
                  // Skip files that can't be accessed
                }
              }
            }
          }

          if (files.isNotEmpty) {
            await selectionNotifier.addFiles(files);
          }

          for (final directory in directories) {
            await selectionNotifier.addDirectory(directory);
          }
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
