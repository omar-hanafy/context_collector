import 'package:context_collector/src/app/shortcuts/shortcut_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class ShortcutBinding {
  const ShortcutBinding({
    required this.command,
    required this.key,
    this.primary = true,
    this.shift = false,
    this.alt = false,
  });

  factory ShortcutBinding.fromJson(Map<String, dynamic> json) {
    return ShortcutBinding(
      command: TabShortcutCommand.values.firstWhere(
        (c) => c.name == json['command'] as String,
      ),
      key: LogicalKeyboardKey(json['key'] as int),
      primary: json['primary'] as bool? ?? true,
      shift: json['shift'] as bool? ?? false,
      alt: json['alt'] as bool? ?? false,
    );
  }

  final TabShortcutCommand command;
  final LogicalKeyboardKey key;
  final bool primary;
  final bool shift;
  final bool alt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'command': command.name,
    'key': key.keyId,
    'primary': primary,
    'shift': shift,
    'alt': alt,
  };

  SingleActivator toActivator(TargetPlatform platform) {
    final isMac = platform == TargetPlatform.macOS;
    return SingleActivator(
      key,
      meta: primary && isMac,
      control: primary && !isMac,
      shift: shift,
      alt: alt,
    );
  }

  bool matches(KeyEvent event, {required TargetPlatform platform}) {
    if (event.logicalKey != key) return false;

    final hardware = HardwareKeyboard.instance;
    final isMac = platform == TargetPlatform.macOS;

    final primaryDown = isMac
        ? hardware.isMetaPressed
        : hardware.isControlPressed;
    if (primary != primaryDown) return false;

    if (shift != hardware.isShiftPressed) return false;
    if (alt != hardware.isAltPressed) return false;

    // Guard against extra modifiers (e.g., Ctrl+Cmd on macOS).
    if (isMac && hardware.isControlPressed) return false;
    if (!isMac && hardware.isMetaPressed) return false;

    return true;
  }

  String pretty(TargetPlatform platform) {
    final isMac = platform == TargetPlatform.macOS;
    final keyLabel = _labelForKey();
    if (isMac) {
      final buffer = StringBuffer();
      if (alt) buffer.write('⌥');
      if (shift) buffer.write('⇧');
      if (primary) buffer.write('⌘');
      buffer.write(keyLabel);
      return buffer.toString();
    }

    final parts = <String>[];
    if (primary) parts.add('Ctrl');
    if (shift) parts.add('Shift');
    if (alt) parts.add('Alt');
    parts.add(keyLabel);
    return parts.join('+');
  }

  String _labelForKey() {
    final label = key.keyLabel;
    if (label.isNotEmpty) {
      return label.length == 1 ? label.toUpperCase() : label;
    }
    if (key == LogicalKeyboardKey.comma) return ',';
    if (key == LogicalKeyboardKey.period) return '.';
    return key.debugName ?? '';
  }
}
