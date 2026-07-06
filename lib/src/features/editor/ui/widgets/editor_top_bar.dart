import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/platform/platform_caps.dart';

class EditorTopBar extends StatelessWidget {
  const EditorTopBar({
    super.key,
    required this.hasFiles,
    required this.hasSelectedFiles,
    required this.isViewingAll,
    this.onClearFiles,
    required this.onReload,
    required this.onCreateNewFile,
    required this.onPasteClipboardContent,
    required this.onPastePaths,
    required this.onAddFiles,
    required this.onAddFolder,
    this.onSave,
    required this.onOpenSettings,
    required this.onToggleViewAll,
  });

  final bool hasFiles;
  final bool hasSelectedFiles;
  final bool isViewingAll;
  final VoidCallback? onClearFiles;
  final VoidCallback onReload;
  final Future<void> Function(BuildContext context) onCreateNewFile;
  final Future<void> Function() onPasteClipboardContent;
  final Future<void> Function(BuildContext context) onPastePaths;
  final Future<void> Function(BuildContext context) onAddFiles;
  final Future<void> Function(BuildContext context) onAddFolder;
  final Future<void> Function()? onSave;
  final Future<void> Function(BuildContext context) onOpenSettings;
  final Future<void> Function() onToggleViewAll;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      height: 40,
      color: surface,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _toolbarButton(
                    context,
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onPressed: hasFiles ? onClearFiles : null,
                  ),
                  const SizedBox(width: 8),
                  _toolbarButton(
                    context,
                    icon: Icons.refresh,
                    label: 'Reload',
                    onPressed: onReload,
                  ),
                  _toolbarButton(
                    context,
                    icon: Icons.note_add_outlined,
                    label: 'New file',
                    onPressed: () => unawaited(onCreateNewFile(context)),
                  ),
                  _toolbarButton(
                    context,
                    icon: Icons.content_paste_outlined,
                    label: 'Paste',
                    onPressed: () => unawaited(onPasteClipboardContent()),
                  ),
                  if (PlatformCaps.supportsPastePaths)
                    _toolbarButton(
                      context,
                      icon: Icons.content_paste_go_rounded,
                      label: 'Paste paths',
                      onPressed: () => unawaited(onPastePaths(context)),
                    ),
                  _toolbarButton(
                    context,
                    icon: Icons.file_open_outlined,
                    label: 'Add files',
                    onPressed: () => unawaited(onAddFiles(context)),
                  ),
                  if (PlatformCaps.supportsDirectoryPicker)
                    _toolbarButton(
                      context,
                      icon: Icons.folder_open_outlined,
                      label: 'Add folder',
                      onPressed: () => unawaited(onAddFolder(context)),
                    ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toolbarButton(
                context,
                icon: Icons.save_outlined,
                label: 'Save',
                onPressed: hasSelectedFiles && onSave != null
                    ? () => unawaited(onSave!())
                    : null,
              ),
              _toolbarButton(
                context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                onPressed: () => unawaited(onOpenSettings(context)),
              ),
              _toolbarButton(
                context,
                icon: Icons.view_agenda_outlined,
                label: isViewingAll ? 'Exit view all' : 'View all',
                onPressed: () => unawaited(onToggleViewAll()),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurfaceColor = colorScheme.onSurface;
    final disabledColor = onSurfaceColor.withValues(
      alpha: onSurfaceColor.a * 0.38,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return disabledColor;
            }
            return onSurfaceColor;
          }),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
