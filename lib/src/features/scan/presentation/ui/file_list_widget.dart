import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FileListWidget extends StatelessWidget {
  const FileListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectionCubit, PreferencesCubit>(
      builder: (context, selectionCubit, preferencesCubit, child) {
        if (selectionCubit.allFiles.isEmpty) {
          return const Center(
            child: Text('No files added yet'),
          );
        }

        return ListView.builder(
          itemCount: selectionCubit.allFiles.length,
          itemBuilder: (context, index) {
            final file = selectionCubit.allFiles[index];
            return _FileListItem(
              file: file,
              isSelected: selectionCubit.isFileSelected(file),
              activeExtensions: preferencesCubit.activeExtensions,
              onToggle: () => selectionCubit.toggleFileSelection(file),
              onRemove: () => selectionCubit.removeFile(file),
            );
          },
        );
      },
    );
  }
}

class _FileListItem extends StatelessWidget {
  const _FileListItem({
    required this.file,
    required this.isSelected,
    required this.activeExtensions,
    required this.onToggle,
    required this.onRemove,
  });

  final ScannedFile file;
  final bool isSelected;
  final Map<String, FileCategory> activeExtensions;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSelected ? context.primary.addOpacity(0.05) : context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? context.primary.addOpacity(0.3)
              : context.outline.addOpacity(0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Row(
              children: [
                _buildLeading(context),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContent(context),
                ),
                const SizedBox(width: 12),
                _buildTrailing(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? context.primary : context.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? context.primary
                  : context.outline.addOpacity(0.5),
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        _buildFileIcon(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          file.name,
          style: context.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          file.fullPath,
          style: context.bodySmall?.copyWith(
            color: context.onSurface.addOpacity(0.5),
            fontFamily: 'monospace',
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatusChip(context),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  file.sizeFormatted,
                  style: context.labelSmall?.copyWith(
                    fontSize: 11,
                    color: context.onSurface.addOpacity(0.6),
                  ),
                ),
              ),
              if (file.getCategory(activeExtensions) != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.primary.addOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    file.extension,
                    style: context.labelSmall?.copyWith(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: context.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (file.error != null)
          IconButton(
            icon: Icon(
              Icons.error_outline_rounded,
              color: context.error,
            ),
            onPressed: () => _showErrorDialog(context),
            tooltip: 'Show error',
            style: IconButton.styleFrom(
              backgroundColor: context.error.addOpacity(0.1),
            ),
          )
        else if (file.content != null)
          Container(
            padding: const EdgeInsetsDirectional.all(6),
            decoration: BoxDecoration(
              color: context.primary.addOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.primary,
              size: 20,
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onRemove,
          tooltip: 'Remove file',
          style: IconButton.styleFrom(
            foregroundColor: context.error,
            backgroundColor: context.error.addOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildFileIcon(BuildContext context) {
    final category = file.getCategory(activeExtensions);
    final isSupported = file.supportsText(activeExtensions);

    if (!isSupported || category == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.insert_drive_file_outlined,
          color: context.onSurface.addOpacity(0.5),
          size: 20,
        ),
      );
    }

    // Get specific icon and color based on extension
    IconData iconData = category.icon;
    Color iconColor = context.primary;
    Color bgColor = context.primary.addOpacity(0.1);

    // Special cases for popular extensions
    switch (file.extension.toLowerCase()) {
      case '.dart':
        iconData = Icons.flutter_dash;
        iconColor = const Color(0xFF0175C2);
        bgColor = iconColor.addOpacity(0.1);
      case '.py':
        iconColor = const Color(0xFF3776AB);
        bgColor = iconColor.addOpacity(0.1);
      case '.js':
      case '.ts':
        iconColor = const Color(0xFFF7DF1E);
        bgColor = const Color(0xFF323330);
      case '.html':
        iconColor = const Color(0xFFE34F26);
        bgColor = iconColor.addOpacity(0.1);
      case '.css':
        iconColor = const Color(0xFF1572B6);
        bgColor = iconColor.addOpacity(0.1);
      case '.json':
        iconData = Icons.data_object_rounded;
      case '.md':
        iconData = Icons.article_rounded;
      case '.yaml':
      case '.yml':
        iconData = Icons.settings_rounded;
      case '.sql':
        iconData = Icons.storage_rounded;
      case '.dockerfile':
        iconData = Icons.directions_boat_rounded;
        iconColor = const Color(0xFF2496ED);
        bgColor = iconColor.addOpacity(0.1);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 22,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    if (file.error != null) {
      return Chip(
        label: const Text('Error'),
        labelStyle: context.labelSmall?.copyWith(
          color: context.error,
        ),
        backgroundColor: context.error.addOpacity(0.1),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    if (file.content != null) {
      return Chip(
        label: const Text('Loaded'),
        labelStyle: context.labelSmall?.copyWith(
          color: context.primary,
        ),
        backgroundColor: context.primary.addOpacity(0.1),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    if (!file.supportsText(activeExtensions)) {
      return Chip(
        label: const Text('Not Supported'),
        labelStyle: context.labelSmall?.copyWith(
          color: context.onSurface.addOpacity(0.6),
        ),
        backgroundColor: context.onSurface.addOpacity(0.1),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    return Chip(
      label: const Text('Ready'),
      labelStyle: context.labelSmall,
      backgroundColor: context.surface,
      side: BorderSide(
        color: context.onSurface.addOpacity(0.2),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _showErrorDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: context.error),
            const SizedBox(width: 8),
            const Text('File Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${file.name}',
              style: context.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${file.error}',
              style: context.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
