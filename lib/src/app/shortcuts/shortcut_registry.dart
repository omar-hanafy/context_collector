import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shortcut_defaults.dart';
import 'shortcut_models.dart';
import 'shortcut_service.dart';

class ShortcutRegistry {
  ShortcutRegistry(this._bindings);

  final Map<TabShortcutCommand, ShortcutBinding> _bindings;

  ShortcutBinding? bindingFor(TabShortcutCommand command) => _bindings[command];

  SingleActivator? activatorFor(
    TabShortcutCommand command,
    TargetPlatform platform,
  ) {
    final binding = _bindings[command];
    return binding?.toActivator(platform);
  }

  String? hintFor(TabShortcutCommand command, TargetPlatform platform) {
    final binding = _bindings[command];
    return binding?.pretty(platform);
  }

  TabShortcutCommand? lookup(KeyEvent event, TargetPlatform platform) {
    for (final binding in _bindings.values) {
      if (binding.matches(event, platform: platform)) {
        return binding.command;
      }
    }
    return null;
  }

  List<ShortcutBinding> all() => _bindings.values.toList(growable: false);

  ShortcutRegistry copyWithOverride(ShortcutBinding binding) {
    final next = Map<TabShortcutCommand, ShortcutBinding>.from(_bindings)
      ..[binding.command] = binding;
    return ShortcutRegistry(next);
  }
}

final shortcutRegistryProvider =
    StateNotifierProvider<ShortcutRegistryController, ShortcutRegistry>(
      ShortcutRegistryController.new,
    );

class ShortcutRegistryController extends StateNotifier<ShortcutRegistry> {
  ShortcutRegistryController(this.ref)
    : super(
        ShortcutRegistry({
          for (final binding in kDefaultTabBindings) binding.command: binding,
        }),
      ) {
    _loadOverrides();
  }

  final Ref ref;

  Future<void> _loadOverrides() async {
    final overrides = await ShortcutSettingsService.load();
    if (overrides.isEmpty) return;
    var current = state;
    for (final binding in overrides) {
      current = current.copyWithOverride(binding);
    }
    state = current;
  }

  Future<void> update(ShortcutBinding binding) async {
    state = state.copyWithOverride(binding);
    await ShortcutSettingsService.save(state.all());
  }

  Future<void> resetToDefaults() async {
    state = ShortcutRegistry({
      for (final binding in kDefaultTabBindings) binding.command: binding,
    });
    await ShortcutSettingsService.clear();
  }
}
