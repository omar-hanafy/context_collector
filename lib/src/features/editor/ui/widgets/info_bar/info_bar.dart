import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import 'language_selector.dart';
import 'stats_row.dart';

/// Refactored info bar that uses MonacoController from flutter_monaco
class MonacoEditorInfoBar extends ConsumerWidget {
  const MonacoEditorInfoBar({
    required this.onCopy,
    this.onCopyFullPaths,
    this.onCopyAiPaths,
    super.key,
  });

  final VoidCallback onCopy;
  final VoidCallback? onCopyFullPaths;
  final VoidCallback? onCopyAiPaths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(monacoControllerProvider);

    if (controller == null) {
      return const _LoadingIndicator();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Stats Display
          ValueListenableBuilder<LiveStats>(
            valueListenable: controller.liveStats,
            builder: (context, stats, _) {
              return StatsRow(stats: stats);
            },
          ),
          const SizedBox(width: 12),

          // Language Selector
          ValueListenableBuilder<LiveStats>(
            valueListenable: controller.liveStats,
            builder: (context, stats, _) {
              return LanguageSelector(
                currentLanguage: stats.language ?? 'plaintext',
                onLanguageChanged: (langId) => controller.setLanguage(
                  MonacoLanguage.fromId(langId),
                ),
              );
            },
          ),

          const Spacer(),

          // Action Buttons
          ..._buildActionButtons(context, controller),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, MonacoController controller) {
    return [
      IconButton(
        icon: const Icon(EneftyIcons.arrow_circle_up_outline, size: 20),
        tooltip: 'Scroll to Top',
        onPressed: controller.scrollToTop,
      ),
      IconButton(
        icon: const Icon(EneftyIcons.arrow_circle_down_outline, size: 20),
        tooltip: 'Scroll to Bottom',
        onPressed: controller.scrollToBottom,
      ),
      const VerticalDivider(width: 1, indent: 8, endIndent: 8),
      IconButton(
        icon: const Icon(EneftyIcons.textalign_justifyleft_outline, size: 20),
        tooltip: 'Format Content',
        onPressed: controller.format,
      ),
      GestureDetector(
        onSecondaryTapUp: (details) {
          if (onCopyFullPaths != null) {
            _showCopyMenu(context, details.globalPosition);
          }
        },
        child: IconButton(
          icon: const Icon(EneftyIcons.copy_outline, size: 20),
          tooltip: 'Copy Content (Right-click for full paths)',
          onPressed: onCopy, // Left-click is the default action
        ),
      ),
    ];
  }

  void _showCopyMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry>[
        const PopupMenuItem(
          value: 'content',
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy Content'),
            dense: true,
          ),
        ),
        if (onCopyFullPaths != null)
          const PopupMenuItem(
            value: 'full_paths',
            child: ListTile(
              leading: Icon(Icons.folder_outlined),
              title: Text('Copy Full Paths'),
              dense: true,
            ),
          ),
        if (onCopyAiPaths != null)
          const PopupMenuItem(
            value: 'ai_paths',
            child: ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('Copy AI Paths'),
              dense: true,
            ),
          ),
      ],
    ).then((value) {
      if (value == 'content') onCopy();
      if (value == 'full_paths') onCopyFullPaths?.call();
      if (value == 'ai_paths') onCopyAiPaths?.call();
    });
  }
}

/// Loading indicator widget
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Initializing Monaco Editor...',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
