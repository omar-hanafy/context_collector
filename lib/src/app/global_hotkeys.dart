import 'dart:async';

import 'package:context_collector/src/app/shortcuts/shortcut_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shortcuts/shortcut_registry.dart' as app_shortcuts;

/// Ensures tab shell shortcuts fire even when a platform view (e.g. Monaco)
/// owns keyboard focus.
class GlobalHotkeys extends StatefulWidget {
  const GlobalHotkeys({
    super.key,
    required this.child,
    required this.onCommand,
    required this.registry,
    this.canHandleEditCommand,
    this.onEditCommand,
  });

  final Widget child;
  final Future<void> Function(TabShortcutCommand command) onCommand;
  final app_shortcuts.ShortcutRegistry registry;
  final bool Function(GlobalEditCommand command)? canHandleEditCommand;
  final Future<void> Function(GlobalEditCommand command)? onEditCommand;

  @override
  State<GlobalHotkeys> createState() => _GlobalHotkeysState();
}

class _GlobalHotkeysState extends State<GlobalHotkeys> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleEvent);
    super.dispose();
  }

  bool _handleEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final platform = Theme.of(context).platform;
    final editCommand = _lookupEditCommand(event, platform);
    if (editCommand != null &&
        (widget.canHandleEditCommand?.call(editCommand) ?? false)) {
      unawaited(widget.onEditCommand?.call(editCommand));
      return true;
    }

    final TabShortcutCommand? command = widget.registry.lookup(event, platform);
    if (command == null) {
      return false;
    }

    unawaited(widget.onCommand(command));
    return true;
  }

  GlobalEditCommand? _lookupEditCommand(
    KeyEvent event,
    TargetPlatform platform,
  ) {
    if (platform != TargetPlatform.macOS) return null;

    final hardware = HardwareKeyboard.instance;
    if (!hardware.isMetaPressed ||
        hardware.isAltPressed ||
        hardware.isControlPressed) {
      return null;
    }

    final shift = hardware.isShiftPressed;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyZ) {
      return shift ? GlobalEditCommand.redo : GlobalEditCommand.undo;
    }
    if (shift) return null;
    if (key == LogicalKeyboardKey.keyX) return GlobalEditCommand.cut;
    if (key == LogicalKeyboardKey.keyC) return GlobalEditCommand.copy;
    if (key == LogicalKeyboardKey.keyV) return GlobalEditCommand.paste;
    if (key == LogicalKeyboardKey.keyA) return GlobalEditCommand.selectAll;
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum GlobalEditCommand {
  undo,
  redo,
  cut,
  copy,
  paste,
  selectAll,
}
