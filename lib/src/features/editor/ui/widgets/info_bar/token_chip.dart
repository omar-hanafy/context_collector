import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A chip that displays the estimated token count and allows changing the AI model
class TokenCountChip extends ConsumerWidget {
  const TokenCountChip({
    required this.content,
    super.key,
  });

  final String content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculator = ref.watch(tokenCalculatorProvider);
    final selectedModel = ref.watch(selectedAIModelProvider);
    final estimate = calculator.estimateTokens(
      content,
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
          child: _buildTooltipContent(context, selectedModel, estimate, usage),
        ),
        child: InkWell(
          onTap: () => _showModelMenu(context, ref, calculator),
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
          const SizedBox(height: 8),
          Text(
            '~${_formatFullNumber((estimate as dynamic).tokens as int)} tokens',
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
    );
  }

  void _showModelMenu(
    BuildContext context,
    WidgetRef ref,
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
          child: _buildModelMenuItem(context, ref, calculator, model),
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
  ) {
    final currentSelectedModel = ref.watch(selectedAIModelProvider);
    final isSelected = model == currentSelectedModel;
    final estimate = calculator.estimateTokens(content, model: model);
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
