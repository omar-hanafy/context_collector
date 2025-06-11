import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.all(32),
      padding: const EdgeInsetsDirectional.all(64),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsEmptyState(
                icon: Icons.folder_open_rounded,
                title: 'Drop Your Files or Directories Here',
                subtitle:
                    'Drag and drop files or directories to combine their content\ninto a single, organized collection',
                customIcon: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.primary.addOpacity(0.1),
                        context.primary.addOpacity(0.05),
                      ],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    size: 56,
                    color: context.primary,
                  ),
                ),
                actions: [
                  _buildSecondaryButton(context),
                  const SizedBox(height: 48),
                  _buildFeatureGrid(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showSupportedFormats(context),
      icon: const Icon(Icons.help_outline_rounded),
      label: const Text('Supported Formats'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      (
        icon: Icons.code_rounded,
        title: 'All Text Files',
        description:
            'Support for ${ExtensionCatalog.supportedExtensions.length}+ file types',
      ),
      (
        icon: Icons.link_rounded,
        title: 'File References',
        description: 'Includes path & metadata',
      ),
      (
        icon: Icons.content_copy_rounded,
        title: 'Quick Copy',
        description: 'One-click clipboard copy',
      ),
      (
        icon: Icons.edit_note_rounded,
        title: 'Code Editor',
        description: 'View and edit content in real-time',
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: features
          .map(
            (feature) => SizedBox(
              width: 280,
              child: Row(
                children: [
                  DsIconContainer(
                    icon: feature.icon,
                    backgroundColor: context.primary.addOpacity(0.08),
                    iconColor: context.primary,
                    size: 24,
                    padding: 12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: context.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          feature.description,
                          style: context.bodySmall?.copyWith(
                            color: context.onSurface.addOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _showSupportedFormats(BuildContext context) async {
    final groupedExtensions = ExtensionCatalog.getGroupedExtensions();
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(24),
                decoration: BoxDecoration(
                  color: context.primary.addOpacity(0.05),
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(20),
                    topEnd: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.file_present_rounded,
                      color: context.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Supported File Formats',
                      style: context.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.onSurface.addOpacity(0.6),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: context.surface,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in groupedExtensions.entries) ...[
                        _buildFormatCategory(
                          context,
                          entry.key,
                          entry.value,
                        ),
                        if (entry.key != groupedExtensions.keys.last)
                          const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: const BorderRadiusDirectional.only(
                    bottomStart: Radius.circular(20),
                    bottomEnd: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: context.onSurface.addOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ExtensionCatalog.supportedExtensions.length} file types supported',
                        style: context.bodySmall?.copyWith(
                          color: context.onSurface.addOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatCategory(
    BuildContext context,
    FileCategory category,
    List<String> extensions,
  ) {
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.outline.addOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(8),
                decoration: BoxDecoration(
                  color: context.primary.addOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.icon,
                  size: 20,
                  color: context.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.displayName,
                style: context.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.onSurface,
                ),
              ),
              const Spacer(),
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
                  '${extensions.length}',
                  style: context.labelSmall?.copyWith(
                    color: context.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: extensions
                .map(
                  (ext) => Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ext,
                      style: context.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
