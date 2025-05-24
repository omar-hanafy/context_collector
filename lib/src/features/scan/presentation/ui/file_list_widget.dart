import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Enhanced file list widget with improved file display and status indicators
class FileListWidget extends StatelessWidget {
  const FileListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectionCubit, PreferencesCubit>(
      builder: (context, selectionCubit, preferencesCubit, child) {
        if (selectionCubit.allFiles.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            // File stats summary bar
            _buildFileStatsBar(context, selectionCubit),
            
            // File list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsetsDirectional.all(24),
              decoration: BoxDecoration(
                color: context.primary.addOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.primary.addOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: context.primary.addOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Files Added',
              style: context.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.onSurface.addOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drag and drop files or directories\nto get started',
              textAlign: TextAlign.center,
              style: context.bodyMedium?.copyWith(
                color: context.onSurface.addOpacity(0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileStatsBar(BuildContext context, SelectionCubit cubit) {
    final stats = cubit.getStats();
    
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primary.addOpacity(0.08),
            context.primary.addOpacity(0.04),
          ],
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.primary.addOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // File status breakdown
          Expanded(
            child: Row(
              children: [
                _buildStatChip(
                  context,
                  icon: Icons.check_circle,
                  label: 'Loaded',
                  count: stats.loadedFiles,
                  color: context.primary,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  icon: Icons.pending,
                  label: 'Pending',
                  count: stats.pendingFiles,
                  color: context.onSurface.addOpacity(0.6),
                ),
                if (stats.errorFiles > 0) ...[
                  const SizedBox(width: 8),
                  _buildStatChip(
                    context,
                    icon: Icons.error,
                    label: 'Errors',
                    count: stats.errorFiles,
                    color: context.error,
                  ),
                ],
              ],
            ),
          ),
          
          // Total size indicator
          if (stats.totalSize > 0)
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.onSurface.addOpacity(0.1),
                ),
              ),
              child: Text(
                stats.formattedSize,
                style: context.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.onSurface.addOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    if (count == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.addOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: context.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: 4,
        vertical: 3,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsetsDirectional.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                ? context.primary.addOpacity(0.08)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? context.primary.addOpacity(0.3)
                    : context.onSurface.addOpacity(0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Selection indicator and file icon
                _buildLeadingSection(context),
                
                const SizedBox(width: 12),
                
                // File info
                Expanded(
                  child: _buildFileInfo(context),
                ),
                
                const SizedBox(width: 8),
                
                // Status and actions
                _buildTrailingSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selection checkbox
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSelected ? context.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? context.primary
                  : context.onSurface.addOpacity(0.4),
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 12,
                  color: context.onPrimary,
                )
              : null,
        ),
        
        const SizedBox(width: 12),
        
        // File type icon
        _buildFileIcon(context),
      ],
    );
  }

  Widget _buildFileIcon(BuildContext context) {
    final category = file.getCategory(activeExtensions);
    final isSupported = file.supportsText(activeExtensions);

    if (!isSupported || category == null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.onSurface.addOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.insert_drive_file_outlined,
          color: context.onSurface.addOpacity(0.5),
          size: 18,
        ),
      );
    }

    // Enhanced file type specific icons and colors
    IconData iconData = category.icon;
    Color iconColor = context.primary;
    Color bgColor = context.primary.addOpacity(0.1);

    // Special cases for popular file types
    switch (file.extension.toLowerCase()) {
      case '.dart':
        iconData = Icons.flutter_dash;
        iconColor = const Color(0xFF0175C2);
        bgColor = iconColor.addOpacity(0.15);
      case '.py':
        iconData = Icons.code;
        iconColor = const Color(0xFF3776AB);
        bgColor = iconColor.addOpacity(0.15);
      case '.js':
      case '.ts':
        iconData = Icons.code;
        iconColor = const Color(0xFFF7DF1E);
        bgColor = const Color(0xFF323330);
      case '.html':
        iconData = Icons.web;
        iconColor = const Color(0xFFE34F26);
        bgColor = iconColor.addOpacity(0.15);
      case '.css':
        iconData = Icons.style;
        iconColor = const Color(0xFF1572B6);
        bgColor = iconColor.addOpacity(0.15);
      case '.json':
        iconData = Icons.data_object;
        iconColor = const Color(0xFF000000);
        bgColor = iconColor.addOpacity(0.1);
      case '.md':
        iconData = Icons.article;
        iconColor = const Color(0xFF083fa1);
        bgColor = iconColor.addOpacity(0.15);
      case '.yaml':
      case '.yml':
        iconData = Icons.settings;
        iconColor = const Color(0xFFcc1829);
        bgColor = iconColor.addOpacity(0.15);
      case '.sql':
        iconData = Icons.storage;
        iconColor = const Color(0xFF336791);
        bgColor = iconColor.addOpacity(0.15);
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildFileInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File name
        Text(
          file.name,
          style: context.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // File path
        Text(
          file.fullPath,
          style: context.labelSmall?.copyWith(
            color: context.onSurface.addOpacity(0.6),
            fontFamily: 'monospace',
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 6),
        
        // File metadata row
        Row(
          children: [
            // Status chip
            _buildStatusChip(context),
            
            const SizedBox(width: 8),
            
            // File size
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.onSurface.addOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                file.sizeFormatted,
                style: context.labelSmall?.copyWith(
                  fontSize: 10,
                  color: context.onSurface.addOpacity(0.7),
                ),
              ),
            ),
            
            // Extension chip
            if (file.getCategory(activeExtensions) != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.primary.addOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  file.extension,
                  style: context.labelSmall?.copyWith(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: context.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    if (file.error != null) {
      return Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: context.error.addOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error,
              size: 10,
              color: context.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Error',
              style: context.labelSmall?.copyWith(
                fontSize: 10,
                color: context.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (file.content != null) {
      return Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: context.primary.addOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 10,
              color: context.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Loaded',
              style: context.labelSmall?.copyWith(
                fontSize: 10,
                color: context.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (!file.supportsText(activeExtensions)) {
      return Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: context.onSurface.addOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Unsupported',
          style: context.labelSmall?.copyWith(
            fontSize: 10,
            color: context.onSurface.addOpacity(0.6),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.onSurface.addOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.onSurface.addOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        'Ready',
        style: context.labelSmall?.copyWith(
          fontSize: 10,
          color: context.onSurface.addOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildTrailingSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Content loaded indicator
        if (file.content != null)
          Container(
            padding: const EdgeInsetsDirectional.all(6),
            decoration: BoxDecoration(
              color: context.primary.addOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: context.primary,
              size: 14,
            ),
          )
        else if (file.error != null)
          // Error indicator with tooltip
          Tooltip(
            message: file.error,
            child: Container(
              padding: const EdgeInsetsDirectional.all(6),
              decoration: BoxDecoration(
                color: context.error.addOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: context.error,
                size: 14,
              ),
            ),
          ),
        
        const SizedBox(width: 8),
        
        // Remove button
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close),
          iconSize: 16,
          tooltip: 'Remove file',
          style: IconButton.styleFrom(
            foregroundColor: context.error.addOpacity(0.8),
            backgroundColor: context.error.addOpacity(0.1),
            minimumSize: const Size(28, 28),
            padding: EdgeInsetsDirectional.zero,
          ),
        ),
      ],
    );
  }
}