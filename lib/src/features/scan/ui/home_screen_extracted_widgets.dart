import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

import '../state/file_list_state.dart';
import 'paste_paths_dialog.dart';

/// Extracted header widget for the home screen.
class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.isDragging, super.key});

  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.addOpacity(isDragging ? 0.2 : 0.1),
                theme.colorScheme.primary.addOpacity(isDragging ? 0.1 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: isDragging
                ? Border.all(
                    color: theme.colorScheme.primary.addOpacity(0.3),
                    width: 2,
                  )
                : null,
          ),
          child: Icon(
            Icons.folder_open_rounded,
            size: isDragging ? 64 : 56,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Drop Your Files or Directories Here',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Drag and drop, browse, paste paths, or start with an empty tree.',
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurface.addOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Extracted action buttons for the home screen.
class HomeActionButtons extends StatelessWidget {
  const HomeActionButtons({required this.selectionNotifier, super.key});

  final FileListNotifier selectionNotifier;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () => selectionNotifier.pickFiles(context),
          icon: const Icon(Icons.file_open_rounded),
          label: const Text('Browse Files'),
          style: buttonStyle,
        ),
        OutlinedButton.icon(
          onPressed: () => selectionNotifier.pickDirectory(context),
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Browse Folder'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => PastePathsDialog.show(context),
          icon: const Icon(Icons.content_paste_go),
          label: const Text('Paste Paths'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Secondary actions section with divider.
class HomeSecondaryActions extends StatelessWidget {
  const HomeSecondaryActions({
    required this.onStartEmpty,
    required this.onShowSupportedFormats,
    super.key,
  });

  final VoidCallback onStartEmpty;
  final VoidCallback onShowSupportedFormats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(child: Divider(endIndent: 16)),
            Text(
              'OR',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.addOpacity(0.5)),
            ),
            const Expanded(child: Divider(indent: 16)),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onStartEmpty,
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: const Text('Start with a New File'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onShowSupportedFormats,
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          label: const Text('Supported Formats'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Extracted feature grid for the home screen.
class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final features = [
      (
        icon: Icons.code_rounded,
        title: 'All Text Files',
        description: 'Supports any text-based file format',
        color: Colors.blue,
      ),
      (
        icon: Icons.link_rounded,
        title: 'File References',
        description: 'Includes path & metadata for AI context',
        color: Colors.green,
      ),
      (
        icon: Icons.content_copy_rounded,
        title: 'Quick Copy',
        description: 'One-click copy to clipboard',
        color: Colors.orange,
      ),
      (
        icon: Icons.edit_note_rounded,
        title: 'Code Editor',
        description: 'View and edit with Monaco editor',
        color: Colors.purple,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        final itemWidth = (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: features.map((feature) {
            return SizedBox(
              width: itemWidth,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outline.addOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: feature.color.addOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(feature.icon, color: feature.color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.title,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              feature.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.addOpacity(0.6),
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
          }).toList(),
        );
      },
    );
  }
}