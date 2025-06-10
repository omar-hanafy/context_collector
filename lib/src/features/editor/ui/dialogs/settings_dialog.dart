import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';

/// Refactored settings dialog with extracted tabs
class EditorSettingsDialog extends StatefulWidget {
  const EditorSettingsDialog({
    required this.settings,
    super.key,
    this.customThemes = const [],
    this.customKeybindingPresets = const [],
  });

  final EditorSettings settings;
  final List<EditorTheme> customThemes;
  final List<KeybindingPreset> customKeybindingPresets;

  static Future<EditorSettings?> show(
    BuildContext context,
    EditorSettings currentSettings, {
    List<EditorTheme> customThemes = const [],
    List<KeybindingPreset> customKeybindingPresets = const [],
  }) async {
    return showDialog<EditorSettings>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditorSettingsDialog(
        settings: currentSettings,
        customThemes: customThemes,
        customKeybindingPresets: customKeybindingPresets,
      ),
    );
  }

  @override
  State<EditorSettingsDialog> createState() => _EditorSettingsDialogState();
}

class _EditorSettingsDialogState extends State<EditorSettingsDialog>
    with TickerProviderStateMixin {
  late EditorSettings _settings;
  late TabController _tabController;

  // Form controllers
  final _fontSizeController = TextEditingController();
  final _lineHeightController = TextEditingController();
  final _letterSpacingController = TextEditingController();
  final _tabSizeController = TextEditingController();
  final _wordWrapColumnController = TextEditingController();

  // Focus nodes
  final _fontSizeFocus = FocusNode();
  final _lineHeightFocus = FocusNode();
  final _letterSpacingFocus = FocusNode();
  final _tabSizeFocus = FocusNode();
  final _wordWrapColumnFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _tabController = TabController(length: 6, vsync: this);

    // Initialize form controllers
    _fontSizeController.text = _settings.fontSize.toString();
    _lineHeightController.text = _settings.lineHeight.toString();
    _letterSpacingController.text = _settings.letterSpacing.toString();
    _tabSizeController.text = _settings.tabSize.toString();
    _wordWrapColumnController.text = _settings.wordWrapColumn.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fontSizeController.dispose();
    _lineHeightController.dispose();
    _letterSpacingController.dispose();
    _tabSizeController.dispose();
    _wordWrapColumnController.dispose();
    _fontSizeFocus.dispose();
    _lineHeightFocus.dispose();
    _letterSpacingFocus.dispose();
    _tabSizeFocus.dispose();
    _wordWrapColumnFocus.dispose();
    super.dispose();
  }

  void _updateSettings(EditorSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  void _resetSettings() {
    setState(() {
      _settings = const EditorSettings();
      // Update form controllers
      _fontSizeController.text = _settings.fontSize.toString();
      _lineHeightController.text = _settings.lineHeight.toString();
      _letterSpacingController.text = _settings.letterSpacing.toString();
      _tabSizeController.text = _settings.tabSize.toString();
      _wordWrapColumnController.text = _settings.wordWrapColumn.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 900,
        height: 700,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            DialogHeader(
              title: 'Editor Settings',
              subtitle: 'Customize your Monaco editor experience',
              icon: Icons.settings_outlined,
              onClose: () => Navigator.of(context).pop(),
            ),
            DialogTabBar(tabController: _tabController),
            Expanded(child: _buildTabContent()),
            DialogFooter(
              onCancel: () => Navigator.of(context).pop(),
              onApply: () async {
                await EditorSettingsServiceHelper.save(_settings);
                if (mounted) {
                  Navigator.of(context).pop(_settings);
                }
              },
              onLoadPreset: _loadPreset,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        GeneralTab(
          settings: _settings,
          fontSizeController: _fontSizeController,
          lineHeightController: _lineHeightController,
          letterSpacingController: _letterSpacingController,
          fontSizeFocus: _fontSizeFocus,
          lineHeightFocus: _lineHeightFocus,
          letterSpacingFocus: _letterSpacingFocus,
          onSettingsChanged: _updateSettings,
        ),
        AppearanceTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
          customThemes: widget.customThemes,
        ),
        EditorTab(
          settings: _settings,
          tabSizeController: _tabSizeController,
          wordWrapColumnController: _wordWrapColumnController,
          tabSizeFocus: _tabSizeFocus,
          wordWrapColumnFocus: _wordWrapColumnFocus,
          onSettingsChanged: _updateSettings,
        ),
        KeybindingsTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
          customKeybindingPresets: widget.customKeybindingPresets,
        ),
        LanguagesTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
        ),
        AdvancedTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
          onResetSettings: _resetSettings,
        ),
      ],
    );
  }

  Future<void> _loadPreset() async {
    final preset = await showDialog<String?>(
      context: context,
      builder: (context) => const PresetSelectionDialog(),
    );

    if (preset != null) {
      setState(() {
        _settings = EditorSettings.createPreset(preset);
        // Update form controllers
        _fontSizeController.text = _settings.fontSize.toString();
        _lineHeightController.text = _settings.lineHeight.toString();
        _letterSpacingController.text = _settings.letterSpacing.toString();
        _tabSizeController.text = _settings.tabSize.toString();
        _wordWrapColumnController.text = _settings.wordWrapColumn.toString();
      });
    }
  }
}

/// Reusable dialog header widget
class DialogHeader extends StatelessWidget {
  const DialogHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClose,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: context.primary.addOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: context.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: context.bodyMedium?.copyWith(
                    color: context.onSurface.addOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: context.onSurface.addOpacity(0.6),
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

/// Reusable dialog tab bar widget
class DialogTabBar extends StatelessWidget {
  const DialogTabBar({
    required this.tabController,
    super.key,
  });

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: context.primary,
        unselectedLabelColor: context.onSurface.addOpacity(0.6),
        indicatorColor: context.primary,
        indicatorWeight: 3,
        labelStyle: context.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: context.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Appearance'),
          Tab(text: 'Editor'),
          Tab(text: 'Keybindings'),
          Tab(text: 'Languages'),
          Tab(text: 'Advanced'),
        ],
      ),
    );
  }
}

/// Reusable dialog footer widget
class DialogFooter extends StatelessWidget {
  const DialogFooter({
    required this.onCancel,
    required this.onApply,
    required this.onLoadPreset,
    super.key,
  });

  final VoidCallback onCancel;
  final VoidCallback onApply;
  final VoidCallback onLoadPreset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(
          top: BorderSide(
            color: context.onSurface.addOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onLoadPreset,
            icon: const Icon(Icons.category_outlined),
            label: const Text('Load Preset'),
          ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onApply,
            child: const Text('Apply Settings'),
          ),
        ],
      ),
    );
  }
}

/// Preset selection dialog
class PresetSelectionDialog extends StatelessWidget {
  const PresetSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Load Preset'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final presetName in [
            'beginner',
            'developer',
            'poweruser',
            'accessibility',
          ])
            ListTile(
              title: Text(presetName.toTitle),
              subtitle: Text(_getPresetDescription(presetName)),
              onTap: () {
                Navigator.of(context).pop(presetName);
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getPresetDescription(String preset) {
    switch (preset) {
      case 'beginner':
        return 'Larger font, word wrap enabled, helpful features';
      case 'developer':
        return 'Balanced settings for daily development';
      case 'poweruser':
        return 'Advanced features, compact layout';
      case 'accessibility':
        return 'Optimized for screen readers and visibility';
      default:
        return '';
    }
  }
}
