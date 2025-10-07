// Path: lib/src/features/editor/ui/widgets/info_bar/stats_row.dart
import 'package:context_collector/src/features/editor/data/token_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/token_count_provider.dart';

/// Row displaying editor statistics
class StatsRow extends ConsumerStatefulWidget {
  const StatsRow({
    required this.stats,
    required this.controller,
    super.key,
  });

  final LiveStats stats;
  final MonacoController controller;

  @override
  ConsumerState<StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends ConsumerState<StatsRow> {
  int _lastCharCount = -1;
  int _lastLineCount = -1;

  @override
  void initState() {
    super.initState();
    // Kick a first compute (provider will calculate base + delta).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tokenCountProvider.notifier).notifyUserTyped();
    });
  }

  @override
  void didUpdateWidget(covariant StatsRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    final charCount = widget.stats.charCount.value;
    final lineCount = widget.stats.lineCount.value;

    final charChanged = charCount != _lastCharCount;
    final lineChanged = lineCount != _lastLineCount;
    final controllerChanged = widget.controller != oldWidget.controller;

    if (controllerChanged || charChanged || lineChanged) {
      _lastCharCount = charCount;
      _lastLineCount = lineCount;
      // Tell the service the user edited; it will debounce and update smoothly.
      ref.read(tokenCountProvider.notifier).notifyUserTyped();
    }
  }

  String _tokenTooltipMessage(int? tokens) {
    if (tokens == null) {
      return 'Calculating tokens…';
    }
    return [
      '- GPT 5 Instant: 128k total.',
      '- GPT 5 Thinking/mini/Pro: 196k total.',
      'Input and output share the window—leave a safety margin.',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(tokenCountProvider);
    final tokens = svc.totalTokens;
    final tokenDisplay = tokens == null
        ? '—'
        : prettyTokens(tokens, includeUnit: false);

    final stats = widget.stats;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatItem(label: 'Ln', value: stats.lineCount.value),
        StatItem(label: 'Ch', value: stats.charCount.value),
        StatItem(
          label: 'Tokens',
          value: tokens,
          formattedValue: tokenDisplay,
          tooltip: _tokenTooltipMessage(tokens),
        ),
        if (stats.selectedCharacters.value > 0) ...[
          StatItem(label: 'Sel Ln', value: stats.selectedLines.value),
          StatItem(label: 'Sel Ch', value: stats.selectedCharacters.value),
        ],
        if (stats.caretCount.value > 1)
          StatItem(label: 'Cursors', value: stats.caretCount.value),
      ],
    );
  }
}

/// Individual stat item widget (unchanged)
class StatItem extends StatelessWidget {
  const StatItem({
    required this.label,
    this.value,
    this.formattedValue,
    this.tooltip,
    super.key,
  });

  final String label;
  final int? value;
  final String? formattedValue;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final display = formattedValue ?? value?.toString() ?? '—';

    Widget child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '$label: $display',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      child = Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 250),
        child: child,
      );
    }

    return Semantics(label: '$label $display', child: child);
  }
}
