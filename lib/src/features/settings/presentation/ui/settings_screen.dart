import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _extensionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _extensionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefsState = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _buildSinglePageSettings(
        context,
        prefsState,
        notifier,
      ),
    );
  }

  Widget _buildSinglePageSettings(
    BuildContext context,
    FilterSettingsWithLoading prefsState,
    PreferencesNotifier notifier,
  ) {
    if (prefsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final blacklist = prefsState.settings.blacklistedExtensions.toList()
      ..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Appearance hint — app theme is controlled by the Editor Settings dialog
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.palette_rounded, color: context.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: context.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Theme is controlled by the Editor → Settings → Theme selector. '
                      'Pick a Monaco theme there and the app switches to Light/Dark automatically.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Extensions Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Blacklisted Extensions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                      if (confirm ?? false) {
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
              const SizedBox(height: 8),
              Text(
                'Files matching these patterns will be ignored during scanning. '
                'Supports extensions (.log), multi-part extensions (.g.dart), '
                'and specific filenames (pubspec.lock).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

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

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Blacklisted extensions list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Currently Blacklisted (${blacklist.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (blacklist.isEmpty)
                    Text(
                      'No extensions blacklisted',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
}
