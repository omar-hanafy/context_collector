import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../context_collector.dart';

/// A chip that displays the estimated token count and allows changing the AI model
class TokenCountChip extends ConsumerWidget {
  const TokenCountChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get live content from the provider
    final content = ref.watch(selectionProvider.select((s) => s.combinedContent));
    final calculator = ref.watch(tokenCalculatorProvider);
    final selectedModel = ref.watch(selectedAIModelProvider);
    // Content-type hint based on current Monaco language (if available)
    final controller = ref.watch(monacoControllerProvider);
    final langId = controller?.liveStats.value.language;
    final contentTypeHint = _contentTypeFromLanguage(langId);
    final perModel = ref.watch(perModelStrategyProvider);
    final strategy = perModel ? EstimationStrategy.perModel : EstimationStrategy.average;

    final estimate = calculator.estimateTokens(
      content,
      model: selectedModel,
      contentType: contentTypeHint,
      strategy: strategy,
    );

    // Use overhead-inclusive check for conservative usage in the bar
    final limit = calculator.checkTokenLimit(
      content,
      model: selectedModel,
      contentType: contentTypeHint,
      strategy: strategy,
      includeOverhead: true,
    );
    final usage = ((limit.percentageUsed / 100).clamp(0.0, 1.0)) as double;

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
          child: _buildTooltipContent(context, selectedModel, estimate, usage),
        ),
        child: DsChip(
          label: '~${estimate.tokens.compact()} ↯',
          backgroundColor: context.primaryContainer.addOpacity(0.3),
          textColor: _getTokenColor(context, usage),
          onTap: () => _showModelMenu(context, ref, calculator),
          dense: true,
        ),
      ),
    );
  }

  Widget _buildTooltipContent(
    BuildContext context,
    AIModel selectedModel,
    TokenEstimate estimate,
    double usage,
  ) {
    return Container(
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
          context.ds.spaceHeight(DesignSystem.space8),
          Text(
            '~${estimate.tokens} tokens',
            style: context.bodySmall?.copyWith(
              color: context.onSurface,
            ),
          ),
          context.ds.spaceHeight(DesignSystem.space12),
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
          context.ds.spaceHeight(6),
          Text(
            '${(usage * 100).toStringAsFixed(1)}% of context window',
            style: context.labelSmall?.copyWith(
              color: context.onSurfaceVariant,
            ),
          ),
          context.ds.spaceHeight(DesignSystem.space12),
          Divider(
            color: context.outlineVariant,
            height: 1,
          ),
          context.ds.spaceHeight(DesignSystem.space8),
          Text(
            'Click to compare models',
            style: context.labelSmall?.copyWith(
              color: context.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showModelMenu(
    BuildContext context,
    WidgetRef ref,
    AITokenCalculator calculator,
  ) {
    // Get content once for all calculations in the menu
    final content = ref.read(selectionProvider).combinedContent;
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
      AIModel.gemini15Pro,
      AIModel.gemini15Flash,
      AIModel.grok,
    ];

    showMenu<AIModel>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: popularModels.map((model) {
        return PopupMenuItem<AIModel>(
          value: model,
          child: _buildModelMenuItem(context, ref, calculator, model, content),
        );
      }).toList(),
    ).then((selectedModel) {
      if (selectedModel != null) {
        ref.read(selectedAIModelProvider.notifier).state = selectedModel;
      }
    });
  }

  Widget _buildModelMenuItem(
    BuildContext context,
    WidgetRef ref,
    AITokenCalculator calculator,
    AIModel model,
    String content,
  ) {
    final currentSelectedModel = ref.watch(selectedAIModelProvider);
    final isSelected = model == currentSelectedModel;
    final controller = ref.read(monacoControllerProvider);
    final langId = controller?.liveStats.value.language;
    final contentTypeHint = _contentTypeFromLanguage(langId);
    final perModel = ref.read(perModelStrategyProvider);
    final strategy = perModel ? EstimationStrategy.perModel : EstimationStrategy.average;
    final estimate = calculator.estimateTokens(
      content,
      model: model,
      contentType: contentTypeHint,
      strategy: strategy,
    );
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
          '~${estimate.tokens.compact()}',
          style: context.labelSmall?.copyWith(color: context.onSurfaceVariant),
        ),
      ],
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

// Map Monaco language id to a content type hint for better accuracy
ContentType? _contentTypeFromLanguage(String? langId) {
  if (langId == null) return null;
  final l = langId.toLowerCase();

  const codeLangs = {
    'dart', 'python', 'javascript', 'typescript', 'java', 'cpp', 'c', 'csharp', 'go', 'rust',
    'ruby', 'php', 'swift', 'kotlin', 'scala', 'r', 'shell', 'bash', 'zsh', 'powershell', 'sql',
    'h', 'm'
  };
  const structuredLangs = {
    'json', 'yaml', 'yml', 'xml', 'csv', 'ini', 'toml', 'properties'
  };

  if (codeLangs.contains(l)) return ContentType.code;
  if (structuredLangs.contains(l)) return ContentType.structured;
  if (l == 'markdown') return ContentType.prose;
  return null; // let auto-detect handle it
}
