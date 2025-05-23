import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/theme_extensions.dart';
import '../providers/file_collector_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/combined_content_widget.dart';
import '../widgets/drop_zone_widget.dart';
import '../widgets/file_list_widget.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Connect the settings provider to file collector provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fileProvider = context.read<FileCollectorProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      fileProvider.settingsProvider = settingsProvider;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsetsDirectional.all(8),
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
        actions: [
          Consumer<FileCollectorProvider>(
            builder: (context, provider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: provider.hasFiles
                        ? const EdgeInsetsDirectional.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          )
                        : EdgeInsetsDirectional.zero,
                    decoration: BoxDecoration(
                      color: provider.hasFiles
                          ? context.primary.addOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: provider.hasFiles
                        ? Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: context.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${provider.selectedFilesCount}',
                                style: context.titleSmall?.copyWith(
                                  color: context.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ' / ${provider.totalFilesCount}',
                                style: context.titleSmall?.copyWith(
                                  color: context.onSurface.addOpacity(0.6),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (provider.hasFiles) const SizedBox(width: 8),
                  AnimatedScale(
                    scale: provider.hasFiles ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: provider.hasFiles ? provider.clearFiles : null,
                      icon: const Icon(Icons.clear_all_rounded),
                      tooltip: 'Clear all files',
                      style: IconButton.styleFrom(
                        backgroundColor: context.error.addOpacity(0.1),
                        foregroundColor: context.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
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
          final provider = context.read<FileCollectorProvider>();

          final files = <String>[];
          final directories = <String>[];

          // Separate files and directories
          for (final file in details.files) {
            // final entity = await FileSystemEntity.type(file.path);
            final entity = FileSystemEntity.typeSync(file.path);
            if (entity == FileSystemEntityType.file) {
              files.add(file.path);
            } else if (entity == FileSystemEntityType.directory) {
              directories.add(file.path);
            }
          }

          // Add files first
          if (files.isNotEmpty) {
            provider.addFiles(files);
          }

          // Add directories
          for (final directory in directories) {
            await provider.addDirectory(directory);
          }
        },
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
          child: Consumer<FileCollectorProvider>(
            builder: (context, provider, child) {
              if (provider.error != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error!),
                      backgroundColor: context.error,
                      action: SnackBarAction(
                        label: 'Dismiss',
                        onPressed: provider.clearError,
                        textColor: context.onError,
                      ),
                    ),
                  );
                  provider.clearError();
                });
              }

              if (!provider.hasFiles) {
                return const DropZoneWidget();
              }

              return Row(
                children: [
                  // Left panel - File list
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        const ActionButtonsWidget(),
                        const Expanded(child: FileListWidget()),
                        if (provider.isProcessing)
                          const LinearProgressIndicator(),
                      ],
                    ),
                  ),

                  // Divider
                  const VerticalDivider(width: 1),

                  // Right panel - Combined content
                  const Expanded(
                    flex: 3,
                    child: CombinedContentWidget(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
