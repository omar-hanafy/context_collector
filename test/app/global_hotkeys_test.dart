import 'package:context_collector/src/app/global_hotkeys.dart';
import 'package:context_collector/src/app/shortcuts/shortcut_defaults.dart';
import 'package:context_collector/src/app/shortcuts/shortcut_registry.dart'
    as app_shortcuts;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mac app shortcuts are handled by GlobalHotkeys', (tester) async {
    final commands = <TabShortcutCommand>[];
    final editCommands = <GlobalEditCommand>[];

    await _pumpHotkeys(
      tester,
      onCommand: commands.add,
      onEditCommand: editCommands.add,
      canHandleEditCommand: (_) => true,
    );

    await _pressMacShortcut(
      tester,
      LogicalKeyboardKey.keyC,
      shift: true,
    );

    expect(commands, <TabShortcutCommand>[TabShortcutCommand.copyCombined]);
    expect(editCommands, isEmpty);
  });

  testWidgets('mac native paste is handled when Monaco owns focus', (
    tester,
  ) async {
    final commands = <TabShortcutCommand>[];
    final editCommands = <GlobalEditCommand>[];

    await _pumpHotkeys(
      tester,
      onCommand: commands.add,
      onEditCommand: editCommands.add,
      canHandleEditCommand: (_) => true,
    );

    await _pressMacShortcut(tester, LogicalKeyboardKey.keyV);

    expect(commands, isEmpty);
    expect(editCommands, <GlobalEditCommand>[GlobalEditCommand.paste]);
  });

  testWidgets('mac native paste falls through outside Monaco focus', (
    tester,
  ) async {
    final commands = <TabShortcutCommand>[];
    final editCommands = <GlobalEditCommand>[];

    await _pumpHotkeys(
      tester,
      onCommand: commands.add,
      onEditCommand: editCommands.add,
      canHandleEditCommand: (_) => false,
    );

    await _pressMacShortcut(tester, LogicalKeyboardKey.keyV);

    expect(commands, isEmpty);
    expect(editCommands, isEmpty);
  });
}

Future<void> _pumpHotkeys(
  WidgetTester tester, {
  required void Function(TabShortcutCommand command) onCommand,
  required void Function(GlobalEditCommand command) onEditCommand,
  required bool Function(GlobalEditCommand command) canHandleEditCommand,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.macOS),
      home: GlobalHotkeys(
        registry: app_shortcuts.ShortcutRegistry({
          for (final binding in kDefaultTabBindings) binding.command: binding,
        }),
        onCommand: (command) async => onCommand(command),
        canHandleEditCommand: canHandleEditCommand,
        onEditCommand: (command) async => onEditCommand(command),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

Future<void> _pressMacShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
}
