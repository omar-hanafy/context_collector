import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:context_collector/context_collector.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A stateless, reactive info bar that displays editor status and actions.
/// It listens directly to the MonacoBridgePlatform for updates.
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
    // We use a ListenableBuilder to react to any state changes on the bridge,
    // like content or language updates.
    return ListenableBuilder(
      listenable: bridge,
      builder: (context, _) {
        return FutureBuilder<void>(
          future: bridge.onReady.future,
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                snapshot.connectionState != ConnectionState.done) {
              return _buildLoadingIndicator(context);
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
                  _buildStatsDisplay(context, bridge, ref),
                  const SizedBox(width: 12),
                  _buildLanguageSelector(context, bridge),
                  const Spacer(),
                  ..._buildActionButtons(context, bridge, onCopy),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsDisplay(
    BuildContext context,
    MonacoBridgePlatform bridge,
    WidgetRef ref,
  ) {
    return ValueListenableBuilder<LiveStats>(
      valueListenable: bridge.liveStats,
      builder: (context, stats, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatItem(
              label: stats.lineCount.label,
              value: stats.lineCount.value,
            ),
            _StatItem(
              label: stats.charCount.label,
              value: stats.charCount.value,
            ),
            if (stats.hasSelection) ...[
              _StatItem(
                label: stats.selectedLines.label,
                value: stats.selectedLines.value,
              ),
              _StatItem(
                label: stats.selectedCharacters.label,
                value: stats.selectedCharacters.value,
              ),
            ],
            if (stats.caretCount.value > 1)
              _StatItem(
                label: stats.caretCount.label,
                value: stats.caretCount.value,
              ),
            if (stats.charCount.value > 0) _TokenCountChip(bridge: bridge),
          ],
        );
      },
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    MonacoBridgePlatform bridge,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Select Language',
      onSelected: (lang) => bridge.setLanguage(lang),
      offset: const Offset(0, -300),
      itemBuilder: (_) => EditorConstants.languages.entries.map((entry) {
        final isSelected = bridge.language == entry.key;
        return PopupMenuItem<String>(
          value: entry.key,
          child: Row(
            children: [
              Icon(
                Icons.check,
                size: 16,
                color: isSelected ? context.primary : Colors.transparent,
              ),
              const SizedBox(width: 8),
              Text(entry.value),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: context.outlineVariant.addOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.translate, size: 16, color: context.primary),
            const SizedBox(width: 6),
            Text(
              EditorConstants.languages[bridge.language] ??
                  bridge.language.toUpperCase(),
              style: context.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: context.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    MonacoBridgePlatform bridge,
    VoidCallback onCopy,
  ) {
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

Widget _buildLoadingIndicator(BuildContext context) {
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

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '$label: $value',
        style: context.labelSmall?.copyWith(color: context.onSurfaceVariant),
      ),
    );
  }
}

/// A chip that displays the estimated token count and allows changing the AI model.
class _TokenCountChip extends ConsumerWidget {
  const _TokenCountChip({required this.bridge});

  final MonacoBridgePlatform bridge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculator = ref.watch(tokenCalculatorProvider);
    final selectedModel = ref.watch(selectedAIModelProvider);
    final estimate = calculator.estimateTokens(
      bridge.content,
      model: selectedModel,
    );

    final usage =
        estimate.tokens /
        AITokenCalculator.modelSpecs[selectedModel]!.contextWindow;

    return Theme(
      data: Theme.of(context).copyWith(
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: context.brightness == Brightness.dark
                ? context.surface
                : context.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.outlineVariant.addOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.addOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          textStyle: context.labelMedium,
        ),
      ),
      child: Tooltip(
        richMessage: WidgetSpan(
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 250),
            decoration: BoxDecoration(
              color: context.brightness == Brightness.dark
                  ? context.surface
                  : context.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AITokenCalculator.modelSpecs[selectedModel]!.displayName,
                  style: context.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '~${_formatFullNumber(estimate.tokens)} tokens',
                  style: context.bodySmall?.copyWith(
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usage.clamp(0.0, 1.0),
                    backgroundColor: context.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getUsageColor(usage),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(usage * 100).toStringAsFixed(1)}% of context window',
                  style: context.labelSmall?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  color: context.outlineVariant,
                  height: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  'Click to compare models',
                  style: context.labelSmall?.copyWith(
                    color: context.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        child: InkWell(
          onTap: () => _showModelMenu(context, ref, bridge, calculator),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.primaryContainer.addOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '~${_formatCompactNumber(estimate.tokens)} ↯',
              style: context.labelSmall?.copyWith(
                color: _getTokenColor(context, usage),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// --- FIX: Added back the method to show the model selection menu ---
  void _showModelMenu(
    BuildContext context,
    WidgetRef ref,
    MonacoBridgePlatform bridge,
    AITokenCalculator calculator,
  ) {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final popularModels = [
      AIModel.claudeSonnet,
      AIModel.claudeOpus,
      AIModel.gpt4,
      AIModel.gpt35Turbo,
      AIModel.geminiPro,
      AIModel.grok,
    ];

    showMenu<AIModel>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: popularModels.map((model) {
        return PopupMenuItem<AIModel>(
          value: model,
          child: _buildModelMenuItem(context, ref, bridge, calculator, model),
        );
      }).toList(),
    ).then((selectedModel) {
      if (selectedModel != null) {
        ref.read(selectedAIModelProvider.notifier).state = selectedModel;
      }
    });
  }

  /// --- FIX: Added back the helper to build each item in the menu ---
  Widget _buildModelMenuItem(
    BuildContext context,
    WidgetRef ref,
    MonacoBridgePlatform bridge,
    AITokenCalculator calculator,
    AIModel model,
  ) {
    final currentSelectedModel = ref.watch(selectedAIModelProvider);
    final isSelected = model == currentSelectedModel;
    final estimate = calculator.estimateTokens(bridge.content, model: model);
    final spec = AITokenCalculator.modelSpecs[model]!;

    return Row(
      children: [
        Icon(
          Icons.check,
          size: 16,
          color: isSelected ? context.primary : Colors.transparent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            spec.displayName,
            style: context.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '~${_formatCompactNumber(estimate.tokens)}',
          style: context.labelSmall?.copyWith(color: context.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatCompactNumber(int number) {
    if (number < 1000) return '$number';
    if (number < 10000) return '${(number / 1000).toStringAsFixed(1)}k';
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(0)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  String _formatFullNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Color _getUsageColor(double usage) {
    if (usage > 0.9) return Colors.red;
    if (usage > 0.75) return Colors.orange;
    return Colors.green;
  }

  Color _getTokenColor(BuildContext context, double usage) {
    if (usage > 0.9) return context.error;
    if (usage > 0.75) return Colors.orange;
    return context.primary;
  }
}
