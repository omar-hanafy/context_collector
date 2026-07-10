import 'dart:async';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../data/settings_service.dart';
import 'copy_feedback.dart';
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

  final Future<CopyFeedback> Function() onCopy;
  final Future<CopyFeedback> Function()? onCopyFullPaths;
  final Future<CopyFeedback> Function()? onCopyAiPaths;

  @override
  ConsumerState<MonacoEditorInfoBar> createState() =>
      _MonacoEditorInfoBarState();
}

class _MonacoEditorInfoBarState extends ConsumerState<MonacoEditorInfoBar> {
  bool? _wordWrap;
  CopyFeedback? _copyFeedback;
  Timer? _copyFeedbackReset;
  bool _copyInFlight = false;

  @override
  void dispose() {
    _copyFeedbackReset?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadWordWrap();
  }

  Future<void> _loadWordWrap() async {
    final opts = await EditorSettingsService.load();
    if (mounted) {
      setState(() => _wordWrap = EditorSettingsService.wordWrapEnabled(opts));
    }
  }

  Future<void> _toggleWordWrap() async {
    final controller = ref.read(monacoControllerProvider);
    if (controller == null) return;
    final service = ref.read(monacoEditorStatusProvider.notifier);
    final current = await EditorSettingsService.load();
    final enabled = EditorSettingsService.wordWrapEnabled(current);
    final next = current.copyWith(
      wordWrap: enabled ? MonacoWordWrap.off : MonacoWordWrap.on,
    );
    await EditorSettingsService.save(next);
    await service.updateOptions(EditorOptions(wordWrap: next.wordWrap));
    if (mounted) {
      setState(() => _wordWrap = EditorSettingsService.wordWrapEnabled(next));
    }
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
          ValueListenableBuilder<MonacoLiveStats>(
            valueListenable: controller.stats,
            builder: (context, stats, _) {
              return StatsRow(
                stats: stats,
                controller: controller,
              );
            },
          ),
          const SizedBox(width: 12),

          // Language Selector
          ValueListenableBuilder<MonacoLiveStats>(
            valueListenable: controller.stats,
            builder: (context, stats, _) {
              return LanguageSelector(
                currentLanguage: stats.language?.id ?? 'plaintext',
                onLanguageChanged: (langId) => unawaited(
                  ref
                      .read(monacoEditorStatusProvider.notifier)
                      .setActiveDocumentLanguage(MonacoLanguage(langId)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (iconData, Color? color, String tooltip) = switch (_copyFeedback) {
      CopyFeedback.success => (
        Icons.check_rounded,
        colorScheme.primary,
        'Copied!',
      ),
      CopyFeedback.empty => (
        Icons.do_not_disturb_on_outlined,
        colorScheme.onSurfaceVariant,
        'Nothing to copy',
      ),
      CopyFeedback.error => (
        Icons.error_outline,
        colorScheme.error,
        'Copy failed',
      ),
      null => (
        EneftyIcons.copy_outline,
        null,
        'Copy Content (Right-click to copy paths)',
      ),
    };

    final copyButton = IconButton(
      icon: Icon(iconData, size: 20, color: color),
      tooltip: tooltip,
      onPressed: _copyInFlight ? null : () => _triggerCopy(widget.onCopy),
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
    if (_copyInFlight) return;
    if (widget.onCopyFullPaths != null) {
      _triggerCopy(widget.onCopyFullPaths!);
      return;
    }

    if (widget.onCopyAiPaths != null) {
      _triggerCopy(widget.onCopyAiPaths!);
      return;
    }

    _triggerCopy(widget.onCopy);
  }

  Future<void> _triggerCopy(Future<CopyFeedback> Function() action) async {
    _copyFeedbackReset?.cancel();
    setState(() {
      _copyInFlight = true;
      _copyFeedback = null;
    });

    CopyFeedback result;
    try {
      result = await action();
    } catch (_) {
      result = CopyFeedback.error;
    }

    if (!mounted) return;

    setState(() {
      _copyInFlight = false;
      _copyFeedback = result;
    });

    _copyFeedbackReset = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _copyFeedback = null);
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
