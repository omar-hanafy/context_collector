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
      
      // Minimal global app bar - only unified settings
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
          // ONLY unified settings button in global bar
          IconButton(
            onPressed: () => _showUnifiedSettings(context),
            icon: const Icon(Icons.tune),
            tooltip: 'Settings',
            style: IconButton.styleFrom(
              backgroundColor: context.primary.addOpacity(0.1),
              foregroundColor: context.primary,
            ),
          ),
          const SizedBox(width: 16),
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

              // NEW: Simplified two-panel layout
              return _buildMainContent(context, cubit);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, SelectionCubit cubit) {
    return ResizableSplitter(
      initialRatio: 0.35,
      minRatio: 0.25,
      maxRatio: 0.6,
      startPanel: _buildFileSection(context, cubit),
      endPanel: _buildEditorSection(context, cubit),
    );
  }

  Widget _buildFileSection(BuildContext context, SelectionCubit cubit) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: BorderDirectional(
          end: BorderSide(
            color: context.onSurface.addOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // NEW: File controls header - moved from global bar
          _buildFileControlsHeader(context, cubit),
          
          // File list
          const Expanded(child: FileListWidget()),
          
          // Processing indicator
          if (cubit.isProcessing)
            Container(
              height: 3,
              child: const LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildFileControlsHeader(BuildContext context, SelectionCubit cubit) {
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primary.addOpacity(0.06),
            context.primary.addOpacity(0.03),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        border: BorderDirectional(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File stats row
          Row(
            children: [
              Icon(
                Icons.folder_copy_rounded,
                size: 20,
                color: context.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Files',
                style: context.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.primary.addOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cubit.selectedFilesCount} / ${cubit.totalFilesCount}',
                  style: context.labelSmall?.copyWith(
                    color: context.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Clear all files button - moved from global bar
              IconButton(
                onPressed: cubit.hasFiles ? cubit.clearFiles : null,
                icon: const Icon(Icons.clear_all_rounded),
                tooltip: 'Clear all files',
                style: IconButton.styleFrom(
                  backgroundColor: context.error.addOpacity(0.1),
                  foregroundColor: context.error,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // File action buttons row
          Row(
            children: [
              // Select all/none buttons
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildSelectionButton(
                      context,
                      icon: Icons.done_all_rounded,
                      label: 'All',
                      onPressed: cubit.totalFilesCount > 0 ? cubit.selectAll : null,
                      isEnabled: cubit.totalFilesCount > 0,
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: context.outline.addOpacity(0.2),
                    ),
                    _buildSelectionButton(
                      context,
                      icon: Icons.remove_done_rounded,
                      label: 'None',
                      onPressed: cubit.selectedFilesCount > 0 ? cubit.deselectAll : null,
                      isEnabled: cubit.selectedFilesCount > 0,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Load content button
              FilledButton.icon(
                onPressed: cubit.hasSelectedFiles ? cubit.loadFileContents : null,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Load Content'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isEnabled
                    ? context.primary
                    : context.onSurface.addOpacity(0.3),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: context.labelMedium?.copyWith(
                  color: isEnabled
                      ? context.primary
                      : context.onSurface.addOpacity(0.3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorSection(BuildContext context, SelectionCubit cubit) {
    return Container(
      color: context.surface,
      child: const CombinedContentWidget(),
    );
  }

  Future<void> _showUnifiedSettings(BuildContext context) async {
    final preferencesCubit = context.read<PreferencesCubit>();
    
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedEditorSettingsDialog(
        settings: const EditorSettings(), // Will be unified settings
        customThemes: const [],
        customKeybindingPresets: const [],
      ),
    );
  }
}