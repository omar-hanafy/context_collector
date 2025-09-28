import 'package:flutter/services.dart';

import 'shortcut_models.dart';

/// Identifiers for top-level tab shell shortcut commands.
enum TabShortcutCommand {
  rename,
  newTab,
  refresh,
  newFile,
  paste,
  pastePaths,
  addFiles,
  addFolder,
  saveCombined,
  close,
  closeOthers,
  closeAll,
  settings,
  copyCombined,
}

const List<ShortcutBinding> kDefaultTabBindings = <ShortcutBinding>[
  ShortcutBinding(
    command: TabShortcutCommand.newTab,
    key: LogicalKeyboardKey.keyT,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.close,
    key: LogicalKeyboardKey.keyW,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.closeOthers,
    key: LogicalKeyboardKey.keyW,
    alt: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.closeAll,
    key: LogicalKeyboardKey.keyW,
    shift: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.refresh,
    key: LogicalKeyboardKey.keyR,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.rename,
    key: LogicalKeyboardKey.keyR,
    shift: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.newFile,
    key: LogicalKeyboardKey.keyN,
    shift: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.paste,
    key: LogicalKeyboardKey.keyV,
    shift: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.pastePaths,
    key: LogicalKeyboardKey.keyV,
    alt: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.addFiles,
    key: LogicalKeyboardKey.keyO,
    shift: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.addFolder,
    key: LogicalKeyboardKey.keyO,
    alt: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.saveCombined,
    key: LogicalKeyboardKey.keyS,
    shift: true,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.settings,
    key: LogicalKeyboardKey.comma,
  ),
  ShortcutBinding(
    command: TabShortcutCommand.copyCombined,
    key: LogicalKeyboardKey.keyC,
    alt: true,
  ),
];
