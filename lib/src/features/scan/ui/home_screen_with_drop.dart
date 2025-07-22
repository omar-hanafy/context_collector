import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/consts.dart';
import '../../settings/presentation/ui/settings_screen.dart';
import '../../virtual_tree/ui/virtual_tree_view.dart';
import '../state/file_list_state.dart';
import 'paste_paths_dialog.dart';

/// Beautiful home screen with drop zone functionality
class HomeScreenWithDrop extends ConsumerStatefulWidget {
  const HomeScreenWithDrop({super.key});

  @override
  ConsumerState<HomeScreenWithDrop> createState() => _HomeScreenWithDropState();
}

class _HomeScreenWithDropState extends ConsumerState<HomeScreenWithDrop> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final selectionNotifier = ref.read(selectionProvider.notifier);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          await selectionNotifier.processDroppedItems(
            details.files,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isDragging
              ? Theme.of(context).colorScheme.primary.addOpacity(0.05)
              : null,
          border: _isDragging
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.addOpacity(0.3),
                  width: 2,
                )
              : null,
        ),
        child: HomeScreenContent(isDragging: _isDragging),
      ),
    );
  }
}

/// Beautiful home screen that serves as the landing page
class HomeScreenContent extends ConsumerWidget {
  const HomeScreenContent({this.isDragging = false, super.key});

  final bool isDragging;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.addOpacity(0.8),
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
          // GitHub button
          IconButton(
            onPressed: () async {
              final githubUrl = Uri.parse(
                'https://github.com/omar-hanafy/context_collector',
              );
              if (!await launchUrl(githubUrl)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open GitHub')),
                  );
                }
              }
            },
            icon: SvgPicture.asset(
              isDark ? AppAssets.githubLight : AppAssets.githubDark,
              width: 20,
              height: 20,
            ),
            tooltip: 'View on GitHub',
          ),
          // Buy Me a Coffee button
          IconButton(
            onPressed: () async {
              final coffeeUrl = Uri.parse(
                'https://www.buymeacoffee.com/omar.hanafy',
              );
              if (!await launchUrl(coffeeUrl)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open Buy Me a Coffee'),
                    ),
                  );
                }
              }
            },
            icon: SvgPicture.asset(
              isDark ? AppAssets.logoLight : AppAssets.logoDark,
              width: 20,
              height: 20,
            ),
            tooltip: 'Buy Me a Coffee',
          ),
          // Settings button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main icon with drag indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.addOpacity(
                              isDragging ? 0.2 : 0.1,
                            ),
                            theme.colorScheme.primary.addOpacity(
                              isDragging ? 0.1 : 0.05,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: isDragging
                            ? Border.all(
                                color: theme.colorScheme.primary.addOpacity(
                                  0.3,
                                ),
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

                    // Title
                    Text(
                      'Drop Your Files or Directories Here',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Drag and drop, browse, paste paths, or start with an empty tree.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.addOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Action buttons row
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        // Browse Files button
                        FilledButton.icon(
                          onPressed: () => selectionNotifier.pickFiles(context),
                          icon: const Icon(Icons.file_open_rounded),
                          label: const Text('Browse Files'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Browse Folder button
                        OutlinedButton.icon(
                          onPressed: () =>
                              selectionNotifier.pickDirectory(context),
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Browse Folder'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Paste Paths button
                        OutlinedButton.icon(
                          onPressed: () => PastePathsDialog.show(context),
                          icon: const Icon(Icons.content_paste_go),
                          label: const Text('Paste Paths'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Or divider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Expanded(child: Divider(endIndent: 16)),
                        Text(
                          'OR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.addOpacity(0.5),
                          ),
                        ),
                        const Expanded(child: Divider(indent: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // New "Start Empty" button
                    TextButton.icon(
                      onPressed: () =>
                          VirtualTreeView.showCreateVirtualFileFlow(context, ref),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: const Text('Start with a New File'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Supported Formats button
                    TextButton.icon(
                      onPressed: () => _showSupportedFormats(context),
                      icon: const Icon(Icons.help_outline_rounded, size: 18),
                      label: const Text('Supported Formats'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Features grid
                    _buildFeatureGrid(context),
                  ],
                ),
              ),
            ),
          ),

          // Dragging overlay
          if (isDragging)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: theme.colorScheme.primary.addOpacity(0.05),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.addOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.file_download_outlined,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Drop to add files',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
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
        final itemWidth =
            (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount;

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
                  side: BorderSide(
                    color: theme.colorScheme.outline.addOpacity(0.2),
                  ),
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
                        child: Icon(
                          feature.icon,
                          color: feature.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              feature.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.addOpacity(
                                  0.6,
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
          }).toList(),
        );
      },
    );
  }

  Future<void> _showSupportedFormats(BuildContext context) async {
    final theme = Theme.of(context);

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
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.addOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.file_present_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Supported File Formats',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Context Collector supports all text-based files. '
                        'Simply drop any file and it will try to read it as text. '
                        'Binary files will be automatically skipped.\n\n'
                        'You can blacklist specific extensions in Settings to exclude them from scanning.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Common Examples:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  '.dart',
                                  '.py',
                                  '.js',
                                  '.ts',
                                  '.java',
                                  '.cpp',
                                  '.go',
                                  '.html',
                                  '.css',
                                  '.json',
                                  '.yaml',
                                  '.xml',
                                  '.md',
                                  '.txt',
                                  '.sh',
                                  '.sql',
                                  '.rs',
                                  '.swift',
                                  '.kt',
                                ]
                                .map(
                                  (ext) => Chip(
                                    label: Text(
                                      ext,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    backgroundColor: theme.colorScheme.primary
                                        .addOpacity(0.1),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.addOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All text files are supported',
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
  }
}
