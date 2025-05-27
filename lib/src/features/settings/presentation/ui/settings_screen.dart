import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/extensions.dart';
import '../../../../shared/utils/extension_catalog.dart';
import '../state/preferences_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _extensionController = TextEditingController();
  FileCategory _selectedCategory = FileCategory.other;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _extensionController.dispose();
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
                        selection:
                            TextSelection.collapsed(offset: text.length + 1),
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
                  if (currentPrefs.activeExtensions
                      .containsKey(value.toLowerCase())) {
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
                        Icon(category.icon, size: 20),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extension Settings'),
        actions: [
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
                        content: Text('All default extensions disabled'),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Settings reset to defaults'),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(builder: (context) {
        if (prefsState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupedExtensions = notifier.groupedExtensions;
        final currentPrefs = prefsState.prefs;

        return Column(
          children: [
            Container(
              padding: const EdgeInsetsDirectional.all(16),
              color: context.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customize Supported File Extensions',
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
              child: ListView.builder(
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
                                        await notifier
                                            .toggleExtension(extension);
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
              ),
            ),
          ],
        );
      }),
    );
  }
}
