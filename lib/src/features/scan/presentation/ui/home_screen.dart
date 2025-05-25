import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    // Connect the preferences to the selection cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectionCubit = context.read<SelectionCubit>();
      final preferencesCubit = context.read<PreferencesCubit>();

      // Listen to preferences changes and update selection cubit
      preferencesCubit.addListener(() {
        selectionCubit
            .setSupportedExtensions(preferencesCubit.activeExtensions);
      });

      // Set initial extensions
      selectionCubit.setSupportedExtensions(preferencesCubit.activeExtensions);
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
          Consumer<SelectionCubit>(
            builder: (context, cubit, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: cubit.hasFiles ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: cubit.hasFiles ? cubit.clearFiles : null,
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
          final cubit = context.read<SelectionCubit>();

          final files = <String>[];
          final directories = <String>[];

          // Separate files and directories
          for (final file in details.files) {
            final entity = FileSystemEntity.typeSync(file.path);
            if (entity == FileSystemEntityType.file) {
              files.add(file.path);
            } else if (entity == FileSystemEntityType.directory) {
              directories.add(file.path);
            }
          }

          // Add files first
          if (files.isNotEmpty) {
            cubit.addFiles(files);
          }

          // Add directories
          for (final directory in directories) {
            await cubit.addDirectory(directory);
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
          child: Consumer<SelectionCubit>(
            builder: (context, cubit, child) {
              // Show error messages
              if (cubit.error != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(cubit.error!),
                      backgroundColor: context.error,
                      action: SnackBarAction(
                        label: 'Dismiss',
                        onPressed: cubit.clearError,
                        textColor: context.onError,
                      ),
                    ),
                  );
                  cubit.clearError();
                });
              }

              if (!cubit.hasFiles) {
                return const DropZoneWidget();
              }

              return ResizableSplitter(
                initialRatio: 0.35,
                minRatio: 0.2,
                maxRatio: 0.6,
                startPanel: Column(
                  children: [
                    const ActionButtonsWidget(),
                    const Expanded(child: FileListWidget()),
                    if (cubit.isProcessing) const LinearProgressIndicator(),
                  ],
                ),
                endPanel: const CombinedContentWidget(),
              );
            },
          ),
        ),
      ),
    );
  }
}
