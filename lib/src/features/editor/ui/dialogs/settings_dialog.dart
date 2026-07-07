import 'package:context_collector/src/app/shortcuts/shortcut_defaults.dart';
import 'package:context_collector/src/app/shortcuts/shortcut_models.dart';
import 'package:context_collector/src/app/shortcuts/shortcut_registry.dart'
    as app_shortcuts;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_service.dart';
import 'settings_dialog_widgets.dart';

/// Data model for a toggle setting
class _ToggleSetting {
  const _ToggleSetting({
    required this.title,
    required this.getValue,
    required this.onChanged,
  });

  final String title;
  final bool Function(EditorOptions options) getValue;
  final EditorOptions Function(EditorOptions options, bool value) onChanged;
}

/// Simplified settings dialog for EditorOptions
class EditorSettingsDialog extends StatefulWidget {
  const EditorSettingsDialog({
    required this.options,
    this.highlightShortcuts = false,
    super.key,
  });

  final EditorOptions options;
  final bool highlightShortcuts;

  static Future<EditorOptions?> show(
    BuildContext context,
    EditorOptions currentOptions, {
    bool highlightShortcuts = false,
  }) async {
    return showDialog<EditorOptions>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditorSettingsDialog(
        options: currentOptions,
        highlightShortcuts: highlightShortcuts,
      ),
    );
  }

  @override
  State<EditorSettingsDialog> createState() => _EditorSettingsDialogState();
}

class _EditorSettingsDialogState extends State<EditorSettingsDialog> {
  late EditorOptions _options;
  late TextEditingController _fontSizeController;
  late TextEditingController _tabSizeController;
  late final ScrollController _scrollController;
  final GlobalKey _shortcutSectionKey = GlobalKey();

  // Data-driven list for feature toggles
  static final List<_ToggleSetting> _featureToggles = [
    _ToggleSetting(
      title: 'Show Minimap',
      getValue: EditorSettingsService.minimapEnabled,
      onChanged: (o, v) => o.copyWith(
        minimap: MonacoMinimapOptions(enabled: v),
      ),
    ),
    _ToggleSetting(
      title: 'Show Line Numbers',
      getValue: EditorSettingsService.lineNumbersEnabled,
      onChanged: (o, v) => o.copyWith(
        lineNumbers: v ? MonacoLineNumbers.on : MonacoLineNumbers.off,
      ),
    ),
    _ToggleSetting(
      title: 'Bracket Pair Colorization',
      getValue: (o) => EditorSettingsService.boolValue(
        o,
        (options) => options.bracketPairColorization,
      ),
      onChanged: (o, v) => o.copyWith(bracketPairColorization: v),
    ),
    _ToggleSetting(
      title: 'Format on Paste',
      getValue: (o) => EditorSettingsService.boolValue(
        o,
        (options) => options.formatOnPaste,
      ),
      onChanged: (o, v) => o.copyWith(formatOnPaste: v),
    ),
    _ToggleSetting(
      title: 'Format on Type',
      getValue: (o) => EditorSettingsService.boolValue(
        o,
        (options) => options.formatOnType,
      ),
      onChanged: (o, v) => o.copyWith(formatOnType: v),
    ),
    _ToggleSetting(
      title: 'Mouse Wheel Zoom',
      getValue: (o) => EditorSettingsService.boolValue(
        o,
        (options) => options.mouseWheelZoom,
      ),
      onChanged: (o, v) => o.copyWith(mouseWheelZoom: v),
    ),
    _ToggleSetting(
      title: 'Read Only',
      getValue: (o) => EditorSettingsService.boolValue(
        o,
        (options) => options.readOnly,
      ),
      onChanged: (o, v) => o.copyWith(readOnly: v),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _fontSizeController = TextEditingController(
      text: EditorSettingsService.fontSize(_options).toString(),
    );
    _tabSizeController = TextEditingController(
      text: EditorSettingsService.tabSize(_options).toString(),
    );
    _scrollController = ScrollController();

    if (widget.highlightShortcuts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _shortcutSectionKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            alignment: 0,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    _tabSizeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.settings_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Editor Settings'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Section
              const SectionTitle('Appearance'),
              const SizedBox(height: 8),
              DropdownTile(
                label: 'Theme',
                value: EditorSettingsService.effectiveTheme(_options).id,
                items: MonacoTheme.builtIn.map((t) => t.id).toList(),
                onChanged: (value) => setState(() {
                  _options = _options.copyWith(
                    theme: MonacoTheme(value),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                "This theme also sets the app's Light/Dark mode.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.setOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              // Font Settings
              const SectionTitle('Font'),
              const SizedBox(height: 8),
              NumberField(
                label: 'Font Size',
                controller: _fontSizeController,
                onChanged: (value) {
                  final size = double.tryParse(value);
                  if (size != null && size >= 8 && size <= 48) {
                    setState(() {
                      _options = _options.copyWith(fontSize: size);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownTile(
                label: 'Font Family',
                value: EditorSettingsService.fontFamily(_options),
                items: MonacoFontStacks.all,
                onChanged: (value) => setState(() {
                  _options = _options.copyWith(fontFamily: value);
                }),
                isExpanded: true,
              ),
              const SizedBox(height: 16),

              // Editor Settings
              const SectionTitle('Editor'),
              const SizedBox(height: 8),
              NumberField(
                label: 'Tab Size',
                controller: _tabSizeController,
                onChanged: (value) {
                  final size = int.tryParse(value);
                  if (size != null && size >= 1 && size <= 8) {
                    setState(() {
                      _options = _options.copyWith(tabSize: size);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Word Wrap'),
                value: EditorSettingsService.wordWrapEnabled(_options),
                onChanged: (value) => setState(() {
                  _options = _options.copyWith(
                    wordWrap: value ? MonacoWordWrap.on : MonacoWordWrap.off,
                  );
                }),
                dense: true,
              ),
              const SizedBox(height: 16),

              // Common Toggles - Data-driven approach
              const SectionTitle('Features'),
              const SizedBox(height: 8),
              ..._featureToggles.map((setting) {
                return SwitchListTile(
                  title: Text(setting.title),
                  value: setting.getValue(_options),
                  onChanged: (value) => setState(() {
                    _options = setting.onChanged(_options, value);
                  }),
                  dense: true,
                );
              }),
              const SizedBox(height: 16),
              ShortcutSettingsSection(
                key: _shortcutSectionKey,
                highlight: widget.highlightShortcuts,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  // Reset to defaults
                  setState(() {
                    _options = EditorSettingsService.defaultOptions;
                    _fontSizeController.text = '14';
                    _tabSizeController.text = '4';
                  });
                },
                child: const Text('Reset'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await EditorSettingsService.save(_options);
                  if (mounted) {
                    Navigator.of(context).pop(_options);
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ShortcutSettingsSection extends ConsumerStatefulWidget {
  const ShortcutSettingsSection({
    super.key,
    this.highlight = false,
  });

  final bool highlight;

  @override
  ConsumerState<ShortcutSettingsSection> createState() =>
      _ShortcutSettingsSectionState();
}

class _ShortcutSettingsSectionState
    extends ConsumerState<ShortcutSettingsSection> {
  bool _flash = false;

  @override
  void initState() {
    super.initState();
    _flash = widget.highlight;
    if (_flash) {
      _scheduleFlashReset();
    }
  }

  @override
  void didUpdateWidget(covariant ShortcutSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight && !_flash) {
      setState(() => _flash = true);
      _scheduleFlashReset();
    }
  }

  void _scheduleFlashReset() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() => _flash = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(app_shortcuts.shortcutRegistryProvider);
    final platform = Theme.of(context).platform;
    final theme = Theme.of(context);
    const commands = TabShortcutCommand.values;

    final background = theme.colorScheme.primary.withValues(alpha: 0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: _flash ? background : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Keyboard Shortcuts'),
          const SizedBox(height: 8),
          Text(
            platform == TargetPlatform.macOS
                ? 'Hold ⌘ and press a key to set a shortcut. Add ⇧/⌥ for variants.'
                : 'Hold Ctrl and press a key to set a shortcut. Add Shift/Alt for variants.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: commands.length,
            separatorBuilder: (_, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final command = commands[index];
              final binding = registry.bindingFor(command);
              final label = _commandLabels[command] ?? command.name;
              final hint = binding?.pretty(platform) ?? 'Unassigned';
              return _ShortcutRow(
                label: label,
                hint: hint,
                onChange: () => _handleChange(context, command),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _resetShortcuts(context),
                icon: const Icon(Icons.restore),
                label: const Text('Reset to defaults'),
              ),
              const Spacer(),
              Text(
                'Changes apply immediately across tabs.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleChange(
    BuildContext context,
    TabShortcutCommand command,
  ) async {
    final captured = await _CaptureShortcutDialog.capture(
      context: context,
      command: command,
    );
    if (captured == null) return;

    final registry = ref.read(app_shortcuts.shortcutRegistryProvider);
    final conflict = _findConflict(registry, captured);
    if (conflict != null) {
      final label = _commandLabels[conflict] ?? conflict.name;
      await _showInfoDialog(
        context,
        title: 'Shortcut already in use',
        message: 'That shortcut is already assigned to “$label”.',
      );
      return;
    }

    await ref
        .read(app_shortcuts.shortcutRegistryProvider.notifier)
        .update(captured);

    final platform = Theme.of(context).platform;
    _showToast(
      context,
      'Updated "${_commandLabels[command] ?? command.name}" to ${captured.pretty(platform)}',
    );
  }

  Future<void> _resetShortcuts(BuildContext context) async {
    final confirmed = await _confirmDialog(
      context,
      title: 'Reset all shortcuts?',
      message: 'Restore the default keymap for every command.',
    );
    if (confirmed != true) return;

    await ref
        .read(app_shortcuts.shortcutRegistryProvider.notifier)
        .resetToDefaults();

    _showToast(context, 'Shortcuts reset to defaults');
  }

  TabShortcutCommand? _findConflict(
    app_shortcuts.ShortcutRegistry registry,
    ShortcutBinding candidate,
  ) {
    final candidateSig = _signature(candidate);
    for (final binding in registry.all()) {
      if (binding.command == candidate.command) continue;
      if (_signature(binding) == candidateSig) {
        return binding.command;
      }
    }
    return null;
  }

  String _signature(ShortcutBinding binding) =>
      '${binding.key.keyId}|${binding.primary}|${binding.shift}|${binding.alt}';

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.label,
    required this.hint,
    required this.onChange,
  });

  final String label;
  final String hint;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hintColor = textTheme.bodySmall?.color?.withValues(alpha: 0.7);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyLarge,
          ),
        ),
        Text(
          hint,
          style: textTheme.bodyMedium?.copyWith(color: hintColor),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onChange,
          icon: const Icon(Icons.keyboard),
          label: const Text('Change'),
        ),
      ],
    );
  }
}

class _CaptureShortcutDialog extends StatefulWidget {
  const _CaptureShortcutDialog({required this.command});

  final TabShortcutCommand command;

  static Future<ShortcutBinding?> capture({
    required BuildContext context,
    required TabShortcutCommand command,
  }) {
    return showDialog<ShortcutBinding?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 520,
          height: 220,
          child: _CaptureShortcutDialog(command: command),
        ),
      ),
    );
  }

  @override
  State<_CaptureShortcutDialog> createState() => _CaptureShortcutDialogState();
}

class _CaptureShortcutDialogState extends State<_CaptureShortcutDialog> {
  ShortcutBinding? _candidate;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isMac = platform == TargetPlatform.macOS;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;

        if (key == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }

        if (_isModifier(key)) {
          return KeyEventResult.ignored;
        }

        final hardware = HardwareKeyboard.instance;
        final primaryDown = isMac
            ? hardware.isMetaPressed
            : hardware.isControlPressed;

        if (!primaryDown) {
          return KeyEventResult.ignored;
        }

        setState(() {
          _candidate = ShortcutBinding(
            command: widget.command,
            key: key,
            primary: true,
            shift: hardware.isShiftPressed,
            alt: hardware.isAltPressed,
          );
        });

        return KeyEventResult.handled;
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Press a new shortcut',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isMac
                  ? 'Hold ⌘ (plus optional ⌥/⇧) and press a key.'
                  : 'Hold Ctrl (plus optional Alt/Shift) and press a key.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: _candidate == null
                    ? const Text('Waiting for input…')
                    : _BigShortcutPreview(binding: _candidate!),
              ),
            ),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _candidate == null
                      ? null
                      : () => Navigator.of(context).pop(_candidate),
                  child: const Text('Assign'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static bool _isModifier(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }
}

class _BigShortcutPreview extends StatelessWidget {
  const _BigShortcutPreview({required this.binding});

  final ShortcutBinding binding;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    return Text(
      binding.pretty(platform),
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

const Map<TabShortcutCommand, String> _commandLabels = {
  TabShortcutCommand.rename: 'Rename Tab',
  TabShortcutCommand.newTab: 'New Tab',
  TabShortcutCommand.refresh: 'Refresh',
  TabShortcutCommand.newFile: 'New Virtual File',
  TabShortcutCommand.paste: 'Paste as New File',
  TabShortcutCommand.pastePaths: 'Paste Paths',
  TabShortcutCommand.addFiles: 'Add Files…',
  TabShortcutCommand.addFolder: 'Add Folder…',
  TabShortcutCommand.saveWorkspace: 'Save Workspace…',
  TabShortcutCommand.saveCombined: 'Save Combined…',
  TabShortcutCommand.reopenClosed: 'Reopen Closed Tab',
  TabShortcutCommand.duplicate: 'Duplicate Tab',
  TabShortcutCommand.close: 'Close Tab',
  TabShortcutCommand.closeOthers: 'Close Others',
  TabShortcutCommand.closeAll: 'Close All',
  TabShortcutCommand.settings: 'Preferences',
  TabShortcutCommand.copyCombined: 'Copy Combined',
};
