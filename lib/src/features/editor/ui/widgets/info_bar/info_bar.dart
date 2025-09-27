import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../data/settings_service.dart';
import 'language_selector.dart';
import 'stats_row.dart';

/// Refactored info bar that uses MonacoController from flutter_monaco
class MonacoEditorInfoBar extends ConsumerStatefulWidget {
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
  ConsumerState<MonacoEditorInfoBar> createState() => _MonacoEditorInfoBarState();
}

class _MonacoEditorInfoBarState extends ConsumerState<MonacoEditorInfoBar> {
  bool? _wordWrap;

  @override
  void initState() {
    super.initState();
    _loadWordWrap();
  }

  Future<void> _loadWordWrap() async {
    final opts = await EditorSettingsService.load();
    if (mounted) setState(() => _wordWrap = opts.wordWrap);
  }

  Future<void> _toggleWordWrap() async {
    final controller = ref.read(monacoControllerProvider);
    if (controller == null) return;
    final service = ref.read(monacoEditorStatusProvider.notifier);
    final current = await EditorSettingsService.load();
    final next = current.copyWith(wordWrap: !current.wordWrap);
    await EditorSettingsService.save(next);
    await service.updateOptions(next);
    if (mounted) setState(() => _wordWrap = next.wordWrap);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(monacoControllerProvider);

    if (controller == null) {
      return const _LoadingIndicator();
    }

    final wrapOn = _wordWrap ?? true; // default to true until loaded

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
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
          ..._buildActionButtons(context, controller, wrapOn),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    MonacoController controller,
    bool wrapOn,
  ) {
    final onColor = Theme.of(context).colorScheme.primary;
    final offColor = Theme.of(context).colorScheme.onSurfaceVariant;
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
        icon: Icon(
          Icons.wrap_text,
          size: 20,
          color: wrapOn ? onColor : offColor,
        ),
        tooltip: wrapOn ? 'Word Wrap: On' : 'Word Wrap: Off',
        onPressed: _toggleWordWrap,
      ),
      _buildCopyButton(),
    ];
  }

  Widget _buildCopyButton() {
    final copyButton = IconButton(
      icon: const Icon(EneftyIcons.copy_outline, size: 20),
      tooltip: 'Copy Content (Right-click to copy paths)',
      onPressed: widget.onCopy,
    );

    final hasAltActions =
        widget.onCopyFullPaths != null || widget.onCopyAiPaths != null;
    if (!hasAltActions) {
      return copyButton;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (_) => _handleSecondaryCopy(),
      child: copyButton,
    );
  }

  void _handleSecondaryCopy() {
    if (widget.onCopyFullPaths != null) {
      widget.onCopyFullPaths!.call();
      return;
    }

    if (widget.onCopyAiPaths != null) {
      widget.onCopyAiPaths!.call();
      return;
    }

    widget.onCopy();
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
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
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
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
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
