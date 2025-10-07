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
  });

  final Widget child;
  final Future<void> Function(TabShortcutCommand command) onCommand;
  final app_shortcuts.ShortcutRegistry registry;

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
    final TabShortcutCommand? command = widget.registry.lookup(event, platform);
    if (command == null) {
      return false;
    }
    if (platform == TargetPlatform.macOS &&
        _macMenuReservedCommands.contains(command)) {
      return false;
    }

    unawaited(widget.onCommand(command));
    return true;
  }

  static const Set<TabShortcutCommand> _macMenuReservedCommands = <
      TabShortcutCommand>{
    TabShortcutCommand.paste,
    TabShortcutCommand.pastePaths,
    TabShortcutCommand.copyCombined,
  };

  @override
  Widget build(BuildContext context) => widget.child;
}
