import 'dart:async';
import 'dart:io';

import 'package:context_collector/src/features/settings/presentation/state/preferences_notifier.dart';
import 'package:context_collector/src/features/settings/presentation/state/theme_notifier.dart';
import 'package:context_collector/src/features/settings/services/auto_updater_service.dart';
import 'package:context_collector/src/shared/theme/extensions.dart';
import 'package:context_collector/src/shared/utils/extension_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _extensionController = TextEditingController();
  FileCategory _selectedCategory = FileCategory.other;
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    // Add Updates tab only on supported platforms
    final tabCount = (Platform.isMacOS || Platform.isWindows) ? 3 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  void dispose() {
    _extensionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddExtensionDialog(BuildContext context) async {
    final notifier = ref.read(preferencesProvider.notifier);
    final currentPrefs = ref.read(preferencesProvider).prefs;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Custom Extension'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _extensionController,
                decoration: const InputDecoration(
                  labelText: 'Extension',
                  hintText: '.example',
                  prefixIcon: Icon(Icons.extension_rounded),
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    if (text.isEmpty) return newValue;
                    if (!text.startsWith('.')) {
                      return TextEditingValue(
                        text: '.$text',
                        selection: TextSelection.collapsed(
                          offset: text.length + 1,
                        ),
                      );
                    }
                    return newValue;
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty || value == '.') {
                    return 'Please enter a valid extension';
                  }
                  if (!value.startsWith('.')) {
                    return 'Extension must start with a dot';
                  }
                  if (currentPrefs.activeExtensions.containsKey(
                    value.toLowerCase(),
                  )) {
                    return 'Extension already exists';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FileCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: FileCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          category.icon,
                          size: 20,
                          color: context.isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await notifier.addCustomExtension(
                    _extensionController.text.toLowerCase(),
                    _selectedCategory,
                  );
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    _extensionController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Extension added successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: context.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsState = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'General'),
            const Tab(text: 'Extensions'),
            if (Platform.isMacOS || Platform.isWindows)
              const Tab(text: 'Updates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // General Settings Tab
          _buildGeneralSettings(context, currentTheme),
          // Extensions Settings Tab
          _buildExtensionsSettings(context, prefsState, notifier),
          // Updates Settings Tab (only on supported platforms)
          if (Platform.isMacOS || Platform.isWindows)
            _buildUpdatesSettings(context),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context, ThemeMode currentTheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette_rounded,
                      color: context.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Appearance',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Theme Mode',
                  style: context.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.settings_brightness_rounded),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_rounded),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_rounded),
                    ),
                  ],
                  selected: {currentTheme},
                  onSelectionChanged: (Set<ThemeMode> selection) {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtensionsSettings(
    BuildContext context,
    ExtensionPrefsWithLoading prefsState,
    PreferencesNotifier notifier,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsetsDirectional.all(16),
          color: context.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Customize Supported File Extensions',
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) async {
                      switch (value) {
                        case 'enable_all':
                          await notifier.enableAll();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All extensions enabled'),
                              ),
                            );
                          }
                        case 'disable_all':
                          await notifier.disableAll();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'All default extensions disabled',
                                ),
                              ),
                            );
                          }
                        case 'reset':
                          await showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Reset to Defaults'),
                              content: const Text(
                                'This will remove all custom extensions and reset all settings to default. Are you sure?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    await notifier.resetToDefaults();
                                    if (mounted) {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Settings reset to defaults',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: context.error,
                                  ),
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'enable_all',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded),
                            SizedBox(width: 12),
                            Text('Enable All'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'disable_all',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle_outline_rounded),
                            SizedBox(width: 12),
                            Text('Disable All Default'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.restore_rounded),
                            SizedBox(width: 12),
                            Text('Reset to Defaults'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enable or disable file extensions for context collection. You can also add custom extensions.',
                style: context.bodyMedium?.copyWith(
                  color: context.onSurface.addOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showAddExtensionDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Custom Extension'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (prefsState.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final groupedExtensions = notifier.groupedExtensions;
              final currentPrefs = prefsState.prefs;

              return ListView.builder(
                padding: const EdgeInsetsDirectional.all(16),
                itemCount: groupedExtensions.length,
                itemBuilder: (context, index) {
                  final category = groupedExtensions.keys.elementAt(index);
                  final extensions = groupedExtensions[category]!;
                  final enabledCount = extensions.where((e) => e.value).length;

                  return Card(
                    margin: const EdgeInsetsDirectional.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(category.icon),
                      title: Text(category.displayName),
                      subtitle: Text(
                        '$enabledCount of ${extensions.length} enabled',
                        style: context.bodySmall?.copyWith(
                          color: context.onSurface.addOpacity(0.6),
                        ),
                      ),
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsetsDirectional.all(8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: extensions.map((entry) {
                              final extension = entry.key;
                              final isEnabled = entry.value;
                              final isCustom = currentPrefs.customExtensions
                                  .containsKey(extension);

                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(extension),
                                    if (isCustom) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: context.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                selected: isEnabled,
                                onSelected: (_) async {
                                  await notifier.toggleExtension(extension);
                                },
                                showCheckmark: true,
                                deleteIcon: isCustom
                                    ? const Icon(Icons.close_rounded, size: 18)
                                    : null,
                                onDeleted: isCustom
                                    ? () async {
                                        await notifier.toggleExtension(
                                          extension,
                                        );
                                      }
                                    : null,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatesSettings(BuildContext context) {
    final autoUpdaterService = ref.read(autoUpdaterServiceProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.system_update_rounded,
                      color: context.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Automatic Updates',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Keep Context Collector up to date with the latest features and improvements.',
                  style: context.bodyMedium?.copyWith(
                    color: context.onSurface.addOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      // Show loading indicator without awaiting it
                      unawaited(
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) => const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        ),
                      );

                      await autoUpdaterService.checkForUpdates();

                      if (mounted) {
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Update check complete! If an update is available, it will download automatically.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to check for updates: $e'),
                            backgroundColor: context.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check for Updates'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Update Settings',
                  style: context.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: context.onSurface.addOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Automatic check interval: Every 6 hours',
                            style: context.bodySmall?.copyWith(
                              color: context.onSurface.addOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_download_rounded,
                            size: 16,
                            color: context.onSurface.addOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Updates are downloaded automatically and will be installed on next app restart',
                              style: context.bodySmall?.copyWith(
                                color: context.onSurface.addOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: context.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'About',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  'Version',
                  _packageInfo == null
                      ? 'Loading...'
                      : '${_packageInfo!.version}${_packageInfo!.buildNumber.isNotEmpty ? '+${_packageInfo!.buildNumber}' : ''}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(context, 'Platform', Platform.operatingSystem),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Update Channel',
                  'Stable',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: context.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: context.bodyMedium?.copyWith(
            color: context.onSurface.addOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
