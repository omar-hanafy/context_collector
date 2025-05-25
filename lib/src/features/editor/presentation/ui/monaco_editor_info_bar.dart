import 'package:flutter/material.dart';

import '../../../../shared/theme/extensions.dart';
import '../../bridge/monaco_bridge.dart';

/// Enhanced info bar for Monaco editor with comprehensive controls
class MonacoEditorInfoBar extends StatefulWidget {
  const MonacoEditorInfoBar({
    super.key,
    required this.bridge,
    required this.onCopy,
  });

  final MonacoBridge bridge;
  final VoidCallback onCopy;

  @override
  State<MonacoEditorInfoBar> createState() => _MonacoEditorInfoBarState();
}

class _MonacoEditorInfoBarState extends State<MonacoEditorInfoBar> {
  // State variables for stats are no longer needed here,
  // as ValueListenableBuilder will handle them.

  // _loadEditorStats and related listener logic can be removed.

  // Available languages from the enhanced bridge
  final List<Map<String, String>> _supportedLanguages =
      MonacoBridge.availableLanguages;

  String _currentLanguage = MonacoBridge.availableLanguages.isNotEmpty
      ? MonacoBridge.availableLanguages.first['value']!
      : 'markdown'; // Initialize with a default

  @override
  void initState() {
    super.initState();
    // Initial language determination (could also listen to bridge for language changes if needed)
    _determineCurrentLanguage();
    widget.bridge.addListener(
        _determineCurrentLanguage); // Listen for language changes from bridge
  }

  @override
  void dispose() {
    widget.bridge.removeListener(_determineCurrentLanguage);
    super.dispose();
  }

  Future<void> _determineCurrentLanguage() async {
    if (widget.bridge.isReady) {
      final stats = await widget.bridge
          .getEditorStats(); // getEditorStats still useful for language
      if (mounted) {
        setState(() {
          final String detectedRawLanguage =
              stats['language'] as String? ?? 'markdown';
          _currentLanguage = _supportedLanguages
                  .any((lang) => lang['value'] == detectedRawLanguage)
              ? detectedRawLanguage
              : (_supportedLanguages.isNotEmpty
                  ? _supportedLanguages.first['value']!
                  : 'markdown');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget
          .bridge, // Still listen for isReady and other general bridge changes
      builder: (context, _) {
        if (!widget.bridge.isReady) {
          return _buildLoadingBar(context);
        }
        // Language determination is handled by _determineCurrentLanguage and setState

        return Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              // Live Editor Stats Display using ValueListenableBuilder
              ValueListenableBuilder<Map<String, int>>(
                valueListenable: widget.bridge.liveStats,
                builder: (context, stats, _) {
                  final lines = stats['lines'] ?? 0;
                  final chars = stats['chars'] ?? 0;
                  final selLn = stats['selLn'] ?? 0;
                  final selCh = stats['selCh'] ?? 0;
                  final carets = stats['carets'] ?? 1;

                  final selBlock = selLn > 0 || selCh > 0
                      ? ' (Sel Ln: $selLn Ch: $selCh)'
                      : '';
                  final caretsBlock = carets > 1 ? ' — $carets cursors' : '';

                  return Flexible(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      child: Text(
                        'Ln: $lines Ch: $chars$selBlock$caretsBlock',
                        style: context.labelSmall?.copyWith(
                          color: context.onSurface.addOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines:
                            1, // Ensure it doesn't wrap and cause overflow
                      ),
                    ),
                  );
                },
              ),

              // Concise Language selector
              _buildConciseDropdown<String>(
                context: context,
                icon: Icons.translate,
                value: _currentLanguage, // Use state variable for language
                items: _supportedLanguages
                    .map((lang) => DropdownMenuItem<String>(
                          value: lang['value'],
                          child:
                              Text(lang['text']!, style: context.labelMedium),
                        ))
                    .toList(),
                onChanged: (value) async {
                  if (value != null && value != _currentLanguage) {
                    await widget.bridge.setLanguage(value);
                    // No need to call _determineCurrentLanguage here as the listener will handle it
                  }
                },
                getShortDisplayName: (val) {
                  final selectedLang = _supportedLanguages.firstWhere(
                      (lang) => lang['value'] == val,
                      orElse: () => {'text': val.toUpperCase()});
                  return selectedLang['text']!;
                },
                tooltip: 'Select Language',
              ),
              const SizedBox(width: 8),

              const Spacer(), // Pushes actions to the right

              // Action Buttons - unified style
              _buildActionButton(
                context,
                icon: Icons.copy_outlined,
                tooltip: 'Copy Content',
                onPressed: widget.onCopy,
              ),
              _buildActionButton(
                context,
                icon: Icons.format_align_left_outlined,
                tooltip: 'Format Content',
                onPressed: () async => widget.bridge.format(),
              ),
              _buildActionButton(
                context,
                icon: Icons.keyboard_arrow_up_outlined,
                tooltip: 'Scroll to Top',
                onPressed: () async => widget.bridge.scrollToTop(),
              ),
              _buildActionButton(
                context,
                icon: Icons.keyboard_arrow_down_outlined,
                tooltip: 'Scroll to Bottom',
                onPressed: () async => widget.bridge.scrollToBottom(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingBar(BuildContext context) {
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

  Widget _buildConciseDropdown<T>({
    required BuildContext context,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String Function(T value) getShortDisplayName,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.onSurface.addOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
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
            selectedItemBuilder: (context) {
              return items.map((DropdownMenuItem<T> item) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: context.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        getShortDisplayName(value),
                        style: context.labelSmall?.copyWith(
                            color: context.onSurface.addOpacity(0.9)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            hint: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: context.onSurface.addOpacity(0.7)),
                const SizedBox(width: 6),
                Text('Select...',
                    style: context.labelSmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
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
    );
  }
}
