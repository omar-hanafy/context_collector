import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'shortcut_models.dart';

class ShortcutSettingsService {
  const ShortcutSettingsService._();

  static const String _storageKey = 'tab_shortcuts_v1';

  static Future<List<ShortcutBinding>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return const <ShortcutBinding>[];
    }
    try {
      final data = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      return data.map(ShortcutBinding.fromJson).toList(growable: false);
    } catch (_) {
      return const <ShortcutBinding>[];
    }
  }

  static Future<void> save(List<ShortcutBinding> bindings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      bindings.map((binding) => binding.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
