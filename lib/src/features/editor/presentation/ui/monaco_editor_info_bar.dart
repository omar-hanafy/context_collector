import 'package:context_collector/src/features/editor/bridge/monaco_bridge_platform.dart';
import 'package:context_collector/src/features/editor/domain/monaco_data.dart';
import 'package:context_collector/src/shared/theme/extensions.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';

/// Enhanced info bar for Monaco editor with comprehensive controls
class MonacoEditorInfoBar extends StatefulWidget {
  const MonacoEditorInfoBar({
    super.key,
    required this.bridge,
    required this.onCopy,
  });

  final MonacoBridgePlatform bridge;
  final VoidCallback onCopy;

  @override
  State<MonacoEditorInfoBar> createState() => _MonacoEditorInfoBarState();
}

class _MonacoEditorInfoBarState extends State<MonacoEditorInfoBar> {
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
        final statsText = _formatStatsText(stats);

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          // Prevent excessive width
          child: Text(
            statsText,
            style: context.labelSmall?.copyWith(
              color: context.onSurface.addOpacity(0.7),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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

    return 'Ln: $lines Ch: $chars$selectionInfo$cursorInfo';
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
              elevation: 8,
              alignment: AlignmentDirectional.centerStart,
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
          fit: FlexFit.loose,
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
                  fit: FlexFit.loose,
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
