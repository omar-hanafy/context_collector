import 'package:context_collector/context_collector.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Refactored info bar with extracted components
class MonacoEditorInfoBar extends ConsumerWidget {
  const MonacoEditorInfoBar({
    required this.bridge,
    required this.onCopy,
    super.key,
  });

  final MonacoBridgePlatform bridge;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListenableBuilder(
      listenable: bridge,
      builder: (context, _) {
        return FutureBuilder<void>(
          future: bridge.onReady.future,
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                snapshot.connectionState != ConnectionState.done) {
              return _LoadingIndicator();
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.outline.addOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  // Stats Display
                  ValueListenableBuilder<LiveStats>(
                    valueListenable: bridge.liveStats,
                    builder: (context, stats, _) {
                      return StatsRow(
                        stats: stats,
                        content: bridge.content,
                      );
                    },
                  ),
                  const SizedBox(width: 12),

                  // Language Selector
                  LanguageSelector(
                    currentLanguage: bridge.language,
                    onLanguageChanged: bridge.setLanguage,
                  ),

                  const Spacer(),

                  // Action Buttons
                  ..._buildActionButtons(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(EneftyIcons.arrow_circle_up_outline, size: 20),
        tooltip: 'Scroll to Top',
        onPressed: bridge.scrollToTop,
      ),
      IconButton(
        icon: const Icon(EneftyIcons.arrow_circle_down_outline, size: 20),
        tooltip: 'Scroll to Bottom',
        onPressed: bridge.scrollToBottom,
      ),
      const VerticalDivider(width: 1, indent: 8, endIndent: 8),
      IconButton(
        icon: const Icon(EneftyIcons.textalign_justifyleft_outline, size: 20),
        tooltip: 'Format Content',
        onPressed: bridge.format,
      ),
      IconButton(
        icon: const Icon(EneftyIcons.copy_outline, size: 20),
        tooltip: 'Copy Content',
        onPressed: onCopy,
      ),
    ];
  }
}

/// Loading indicator widget
class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: context.outline.addOpacity(0.2)),
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
              valueColor: AlwaysStoppedAnimation<Color>(context.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Initializing Monaco Editor...',
            style: context.labelMedium?.copyWith(
              color: context.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
