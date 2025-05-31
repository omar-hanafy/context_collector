import 'dart:async';

import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:context_collector/src/features/editor/bridge/monaco_bridge_platform.dart';
import 'package:context_collector/src/features/editor/domain/monaco_data.dart';
import 'package:context_collector/src/features/editor/services/monaco_editor_providers.dart';
import 'package:context_collector/src/shared/theme/extensions.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enhanced info bar for Monaco editor with comprehensive controls
class MonacoEditorInfoBar extends ConsumerStatefulWidget {
  const MonacoEditorInfoBar({
    required this.bridge,
    required this.onCopy,
    super.key,
  });

  final MonacoBridgePlatform bridge;
  final VoidCallback onCopy;

  @override
  ConsumerState<MonacoEditorInfoBar> createState() =>
      _MonacoEditorInfoBarState();
}

class _MonacoEditorInfoBarState extends ConsumerState<MonacoEditorInfoBar> {
  final List<Map<String, String>> _availableLanguages =
      MonacoData.availableLanguages;

  String _selectedLanguage = MonacoData.availableLanguages.isNotEmpty
      ? MonacoData.availableLanguages.first['value']!
      : 'markdown';

  @override
  void initState() {
    super.initState();
    _updateCurrentLanguage();
    widget.bridge.addListener(_updateCurrentLanguage);
  }

  @override
  void dispose() {
    widget.bridge.removeListener(_updateCurrentLanguage);
    super.dispose();
  }

  Future<void> _updateCurrentLanguage() async {
    if (!widget.bridge.isReady) return;

    try {
      final stats = await widget.bridge.getEditorStats();
      if (!mounted) return;

      final detectedLanguage = stats['language'] as String? ?? 'markdown';
      final isSupported =
          _availableLanguages.any((lang) => lang['value'] == detectedLanguage);

      setState(() {
        _selectedLanguage = isSupported
            ? detectedLanguage
            : (_availableLanguages.isNotEmpty
                ? _availableLanguages.first['value']!
                : 'markdown');
      });
    } catch (e) {
      // Handle error silently - language detection is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bridge,
      builder: (context, _) {
        if (!widget.bridge.isReady) {
          return _buildLoadingIndicator(context);
        }

        return Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              // Stats Display - takes only needed space
              _buildStatsDisplay(),

              const SizedBox(width: 12),

              // Language Selector - right after stats
              _buildDropDown<String>(
                context: context,
                icon: Icons.translate,
                value: _selectedLanguage,
                items: _availableLanguages.map(_buildLanguageMenuItem).toList(),
                onChanged: _handleLanguageChange,
                displayNameBuilder: _getLanguageDisplayName,
                tooltip: 'Select Language',
              ),

              // Flexible spacer - pushes buttons to end
              const Spacer(),

              // Action Buttons - at absolute end
              ..._buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsDisplay() {
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: widget.bridge.liveStats,
      builder: (context, stats, _) {
        final chars = stats['chars'] ?? 0;
        final parts = _formatStatsText(stats).split(' | ');

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Regular stats
              Text(
                parts[0],
                style: context.labelSmall?.copyWith(
                  color: context.onSurface.addOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (parts.length > 1 && chars > 0) ...[
                Text(
                  ' | ',
                  style: context.labelSmall?.copyWith(
                    color: context.onSurface.addOpacity(0.4),
                  ),
                ),
                // Ultra-compact token count
                _TokenCountChip(
                  content: widget.bridge.content,
                  calculator: ref.read(tokenCalculatorProvider),
                  selectedModel: ref.watch(selectedAIModelProvider),
                  onModelChanged: (model) =>
                      ref.read(selectedAIModelProvider.notifier).state = model,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatStatsText(Map<String, int> stats) {
    final lines = stats['lines'] ?? 0;
    final chars = stats['chars'] ?? 0;
    final selectedLines = stats['selLn'] ?? 0;
    final selectedChars = stats['selCh'] ?? 0;
    final cursors = stats['carets'] ?? 1;

    final selectionInfo = (selectedLines > 0 || selectedChars > 0)
        ? ' (Sel Ln: $selectedLines Ch: $selectedChars)'
        : '';

    final cursorInfo = cursors > 1 ? ' — $cursors cursors' : '';

    // Add separator for token count (will be rendered separately)
    final tokenSeparator = chars > 0 ? ' | ' : '';

    return 'Ln: $lines Ch: $chars$selectionInfo$cursorInfo$tokenSeparator';
  }

  DropdownMenuItem<String> _buildLanguageMenuItem(
      Map<String, String> language) {
    return DropdownMenuItem<String>(
      value: language['value'],
      child: Text(
        language['text']!,
        style: context.labelMedium,
      ),
    );
  }

  Future<void> _handleLanguageChange(String? newLanguage) async {
    if (newLanguage == null || newLanguage == _selectedLanguage) return;

    try {
      await widget.bridge.setLanguage(newLanguage);
      // Language update will be handled by the listener
    } catch (e) {
      // Handle error silently or show a snackbar if needed
    }
  }

  String _getLanguageDisplayName(String languageValue) {
    final language = _availableLanguages.firstWhere(
      (lang) => lang['value'] == languageValue,
      orElse: () => {'text': languageValue.toUpperCase()},
    );
    return language['text']!;
  }

  List<Widget> _buildActionButtons() {
    final buttons = [
      (EneftyIcons.copy_outline, 'Copy Content', widget.onCopy),
      (
        EneftyIcons.textalign_justifyleft_outline,
        'Format Content',
        () => widget.bridge.format()
      ),
      (
        EneftyIcons.arrow_circle_up_outline,
        'Scroll to Top',
        () => widget.bridge.scrollToTop()
      ),
      (
        EneftyIcons.arrow_circle_down_outline,
        'Scroll to Bottom',
        () => widget.bridge.scrollToBottom()
      ),
    ];

    return buttons
        .map((buttonData) => _buildActionButton(
              context,
              icon: buttonData.$1,
              tooltip: buttonData.$2,
              onPressed: buttonData.$3,
            ))
        .toList();
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: context.onSurface.addOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
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
              color: context.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Initializing Monaco Editor...',
            style: context.bodyMedium?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropDown<T>({
    required BuildContext context,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String Function(T value) displayNameBuilder,
    String? tooltip,
  }) {
    // For language dropdown specifically, use PopupMenuButton for better positioning
    if (T == String && items.length > 20) {
      return _buildLanguagePopupMenu(
        context: context,
        icon: icon,
        value: value as String,
        onChanged: onChanged as ValueChanged<String?>,
        displayNameBuilder: displayNameBuilder as String Function(String),
        tooltip: tooltip,
      );
    }

    // Default dropdown for other uses
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: context.onSurface.addOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            // This ensures the dropdown opens upward when at the bottom
            popupMenuTheme: PopupMenuThemeData(
              position: PopupMenuPosition.over,
              color: context.surface,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              icon: Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: context.onSurface.addOpacity(0.7),
              ),
              isDense: true,
              value: value,
              items: items,
              onChanged: onChanged,
              selectedItemBuilder: (context) => items
                  .map((item) => _buildDropdownSelectedItem(
                      icon, displayNameBuilder(value), context))
                  .toList(),
              hint: _buildDropdownHint(icon, context),
              // Dropdown styling
              dropdownColor: context.surface,
              menuMaxHeight: 300, // Reduced to ensure it fits better
              style: context.labelMedium,
              borderRadius: BorderRadius.circular(8),
              // Force dropdown to calculate position from bottom
              menuWidth: 250, // Set fixed width for consistency
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSelectedItem(
      IconData icon, String displayName, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: context.primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            displayName,
            style: context.labelSmall?.copyWith(
              color: context.onSurface.addOpacity(0.9),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownHint(IconData icon, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: context.onSurface.addOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'Select...',
          style: context.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: context.onSurface.addOpacity(0.7),
        padding: const EdgeInsets.all(10),
      ),
      iconSize: 20,
      splashRadius: 0.1, // Virtually removes splash
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: context.onSurface.addOpacity(0.04),
    );
  }

  Widget _buildLanguagePopupMenu({
    required BuildContext context,
    required IconData icon,
    required String value,
    required ValueChanged<String?> onChanged,
    required String Function(String) displayNameBuilder,
    String? tooltip,
  }) {
    return ThemeWithoutEffects(
      child: Tooltip(
        message: tooltip ?? '',
        child: PopupMenuButton<String>(
          tooltip: '',
          position: PopupMenuPosition.over,
          constraints: const BoxConstraints(
            maxHeight: 400,
            minWidth: 200,
            maxWidth: 250,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: context.surface,
          elevation: 8,
          offset: const Offset(0, -8),
          initialValue: value,
          onSelected: onChanged,
          splashRadius: 0.1,
          enableFeedback: false,
          itemBuilder: (BuildContext context) {
            return _availableLanguages.map((language) {
              final isSelected = language['value'] == value;
              return PopupMenuItem<String>(
                value: language['value'],
                height: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 16,
                          color: context.primary,
                        )
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          language['text']!,
                          style: context.labelMedium?.copyWith(
                            color: isSelected ? context.primary : null,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: context.onSurface.addOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: context.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    displayNameBuilder(value),
                    style: context.labelSmall?.copyWith(
                      color: context.onSurface.addOpacity(0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: context.onSurface.addOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ultra-compact token count display
class _TokenCountChip extends StatefulWidget {
  const _TokenCountChip({
    required this.content,
    required this.calculator,
    required this.selectedModel,
    required this.onModelChanged,
  });

  final String content;
  final AITokenCalculator calculator;
  final AIModel selectedModel;
  final ValueChanged<AIModel> onModelChanged;

  @override
  State<_TokenCountChip> createState() => _TokenCountChipState();
}

class _TokenCountChipState extends State<_TokenCountChip> {
  TokenEstimate? _lastEstimate;
  String _lastContent = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _calculateTokens();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _calculateTokens() {
    if (_lastContent != widget.content) {
      _lastContent = widget.content;

      // Cancel previous timer
      _debounceTimer?.cancel();

      // For small content, calculate immediately
      if (widget.content.length < 5000) {
        _lastEstimate = widget.calculator.estimateTokens(
          widget.content,
          model: widget.selectedModel,
        );
        if (mounted) setState(() {});
      } else {
        // For larger content, debounce
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _lastEstimate = widget.calculator.estimateTokens(
                widget.content,
                model: widget.selectedModel,
              );
            });
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(_TokenCountChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.selectedModel != widget.selectedModel) {
      _calculateTokens();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastEstimate == null) return const SizedBox.shrink();

    final tokens = _lastEstimate!.tokens;
    final usage = tokens /
        AITokenCalculator.modelSpecs[widget.selectedModel]!.contextWindow;

    return Theme(
      data: Theme.of(context).copyWith(
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.onSurface.addOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.addOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      child: Tooltip(
        richMessage: WidgetSpan(
          child: Container(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AITokenCalculator
                      .modelSpecs[widget.selectedModel]!.displayName,
                  style: context.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '~${_formatFullNumber(tokens)} tokens',
                  style: context.labelSmall,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: usage.clamp(0.0, 1.0),
                  backgroundColor: context.onSurface.addOpacity(0.1),
                  color: _getUsageColor(usage),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(usage * 100).toStringAsFixed(1)}% of context window',
                  style: context.labelSmall?.copyWith(
                    color: context.onSurface.addOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                const Divider(height: 16),
                Text(
                  'Click to compare models',
                  style: context.labelSmall?.copyWith(
                    color: context.primary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        child: InkWell(
          onTap: () => _showModelMenu(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: context.labelSmall?.copyWith(
                    color: _getTokenColor(context, usage),
                    fontWeight: FontWeight.w500,
                  ) ??
                  const TextStyle(),
              child: Text('~${_formatCompactNumber(tokens)}↯'),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTokenColor(BuildContext context, double usage) {
    if (usage > 0.9) return context.error;
    if (usage > 0.75) return Colors.orange;
    return context.onSurface.addOpacity(0.7);
  }

  Color _getUsageColor(double usage) {
    if (usage > 0.9) return Colors.red;
    if (usage > 0.75) return Colors.orange;
    return Colors.green;
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

  void _showModelMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final theme = Theme.of(context);
    showMenu<AIModel>(
      context: context,
      position: position,
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.addOpacity(0.2),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.onSurface.addOpacity(0.1),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 220),
      items: [
        // Popular models for quick access
        for (final model in [
          AIModel.claudeSonnet,
          AIModel.claudeOpus,
          AIModel.gpt4,
          AIModel.gpt35Turbo,
          AIModel.geminiPro,
          AIModel.grok,
        ])
          PopupMenuItem<AIModel>(
            value: model,
            height: 36,
            child: _buildModelMenuItem(context, model),
          ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<AIModel>(
          enabled: false,
          height: 32,
          child: Center(
            child: Text(
              'Estimates are ±5-10% accurate',
              style: context.labelSmall?.copyWith(
                color: context.onSurface.addOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    ).then((model) {
      if (model != null) {
        widget.onModelChanged(model);
      }
    });
  }

  Widget _buildModelMenuItem(BuildContext context, AIModel model) {
    final estimate =
        widget.calculator.estimateTokens(widget.content, model: model);
    final spec = AITokenCalculator.modelSpecs[model]!;
    final isSelected = model == widget.selectedModel;
    final usage = estimate.tokens / spec.contextWindow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (isSelected)
            Icon(Icons.check, size: 14, color: context.primary)
          else
            const SizedBox(width: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              spec.displayName,
              style: context.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getUsageColor(usage).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '~${_formatCompactNumber(estimate.tokens)}',
              style: context.labelSmall?.copyWith(
                color: _getUsageColor(usage),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
