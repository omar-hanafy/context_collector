import 'dart:async';
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
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
      padding: DsDimensions.paddingMedium,
      children: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsSectionHeader(
                title: 'Appearance',
                trailing: Icon(
                  Icons.palette_rounded,
                  color: context.primary,
                  size: DesignSystem.iconSizeMedium,
                ),
              ),
              context.ds.spaceHeight(DesignSystem.space16),
              Text(
                'Theme Mode',
                style: context.titleSmall,
              ),
              context.ds.spaceHeight(DesignSystem.space8),
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
      ],
    );
  }

  Widget _buildExtensionsSettings(
    BuildContext context,
    FilterSettingsWithLoading prefsState,
    PreferencesNotifier notifier,
  ) {
    if (prefsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final blacklist = prefsState.settings.blacklistedExtensions.toList()
      ..sort();

    return Column(
      children: [
        // Header section with add extension form
        Container(
          padding: const EdgeInsetsDirectional.all(16),
          color: context.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Blacklisted Extensions',
                    style: context.titleBold,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Reset to Defaults'),
                          content: const Text(
                            'This will reset the blacklist to default settings. Are you sure?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: context.error,
                              ),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await notifier.resetToDefaults();
                        if (mounted) {
                          context.showOk('Blacklist reset to defaults');
                        }
                      }
                    },
                    child: const Text('Reset to Default'),
                  ),
                ],
              ),
              context.ds.spaceHeight(DesignSystem.space8),
              Text(
                'Files matching these patterns will be ignored during scanning. '
                'Supports extensions (.log), multi-part extensions (.g.dart), '
                'and specific filenames (pubspec.lock).',
                style: context.bodyMuted,
              ),
              context.ds.spaceHeight(DesignSystem.space16),
              // Add new extension form
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _extensionController,
                        decoration: const InputDecoration(
                          labelText: 'Pattern to blacklist',
                          hintText: 'e.g., .log, .g.dart, pubspec.lock',
                          prefixIcon: Icon(Icons.block_rounded),
                          border: OutlineInputBorder(),
                        ),
                        // No input formatters - allow any pattern
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a valid pattern';
                          }
                          if (blacklist.contains(value.toLowerCase())) {
                            return 'Pattern already blacklisted';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await notifier.addToBlacklist(
                            _extensionController.text,
                          );
                          _extensionController.clear();
                          if (mounted) {
                            context.showOk('Extension added to blacklist');
                          }
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Blacklisted extensions list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Currently Blacklisted (${blacklist.length})',
                    style: context.titleMedium,
                  ),
                  if (blacklist.isEmpty)
                    Text(
                      'No extensions blacklisted',
                      style: context.bodyMuted,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (blacklist.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: blacklist.map((ext) {
                    return Chip(
                      label: Text(
                        ext,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 18),
                      onDeleted: () async {
                        await notifier.removeFromBlacklist(ext);
                        if (mounted) {
                          context.showOk('Extension removed from blacklist');
                        }
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatesSettings(BuildContext context) {
    final autoUpdaterService = ref.read(autoUpdaterServiceProvider);

    return ListView(
      padding: DsDimensions.paddingMedium,
      children: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsSectionHeader(
                title: 'Automatic Updates',
                trailing: Icon(
                  Icons.system_update_rounded,
                  color: context.primary,
                  size: DesignSystem.iconSizeMedium,
                ),
              ),
              context.ds.spaceHeight(DesignSystem.space16),
              Text(
                'Keep Context Collector up to date with the latest features and improvements.',
                style: context.bodyMuted,
              ),
              context.ds.spaceHeight(DesignSystem.space24),
              DsButton(
                onPressed: () async {
                  try {
                    // Show loading indicator without awaiting it
                    unawaited(
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => const Center(
                          child: DsCard(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    );

                    await autoUpdaterService.checkForUpdates();

                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      context.showOk(
                        'Update check complete! If an update is available, it will download automatically.',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      context.showErr('Failed to check for updates: $e');
                    }
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                isFilled: true,
                child: const Text('Check for Updates'),
              ),
              context.ds.spaceHeight(DesignSystem.space16),
              const DsDivider(),
              context.ds.spaceHeight(DesignSystem.space16),
              Text(
                'Update Settings',
                style: context.titleBold,
              ),
              context.ds.spaceHeight(DesignSystem.space12),
              Container(
                padding: DsDimensions.paddingSmall,
                decoration: BoxDecoration(
                  color: context.surfaceContainerHighest,
                  borderRadius: context.ds.radiusMedium,
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
                        context.ds.spaceWidth(DesignSystem.space8),
                        Text(
                          'Automatic check interval: Every 6 hours',
                          style: context.bodyMuted,
                        ),
                      ],
                    ),
                    context.ds.spaceHeight(DesignSystem.space8),
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_download_rounded,
                          size: 16,
                          color: context.onSurface.addOpacity(0.6),
                        ),
                        context.ds.spaceWidth(DesignSystem.space8),
                        Expanded(
                          child: Text(
                            'Updates are downloaded automatically and will be installed on next app restart',
                            style: context.bodyMuted,
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
        context.ds.spaceHeight(DesignSystem.space16),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsSectionHeader(
                title: 'About',
                trailing: Icon(
                  Icons.info_outline_rounded,
                  color: context.primary,
                  size: DesignSystem.iconSizeMedium,
                ),
              ),
              context.ds.spaceHeight(DesignSystem.space16),
              _buildInfoRow(
                context,
                'Version',
                _packageInfo == null
                    ? 'Loading...'
                    : '${_packageInfo!.version}${_packageInfo!.buildNumber.isNotEmpty ? '+${_packageInfo!.buildNumber}' : ''}',
              ),
              context.ds.spaceHeight(DesignSystem.space8),
              _buildInfoRow(context, 'Platform', Platform.operatingSystem),
              context.ds.spaceHeight(DesignSystem.space8),
              _buildInfoRow(
                context,
                'Update Channel',
                'Stable',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return DsInfoRow(
      label: '$label:',
      value: value,
    );
  }
}
