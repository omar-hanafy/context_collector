import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/foundation.dart';

/// Keybinding action category for organization
enum KeybindingCategory {
  editing,
  navigation,
  selection,
  search,
  view,
  debug,
  terminal,
  file,
  general,
  custom,
}

/// Individual keybinding definition
@immutable
class Keybinding {
  const Keybinding({
    required this.id,
    required this.key,
    required this.command,
    this.when,
    this.args,
    this.category = KeybindingCategory.general,
    this.description,
    this.group,
  });

  /// Create from JSON
  factory Keybinding.fromJson(Map<String, dynamic> json) {
    return Keybinding(
      id: json.getString('id'),
      key: json.getString('key'),
      command: json.getString('command'),
      when: json.tryGetString('when'),
      args: json.tryGetMap('args'),
      category: KeybindingCategory.values.firstWhere(
        (c) => c.name == json.getString('category'),
        orElse: () => KeybindingCategory.general,
      ),
      description: json.tryGetString('description'),
      group: json.tryGetString('group'),
    );
  }

  final String id;
  final String key; // Monaco keybinding format (e.g., "ctrl+s", "cmd+shift+p")
  final String command; // Monaco command ID
  final String? when; // Context condition
  final Map<String, dynamic>? args; // Command arguments
  final KeybindingCategory category;
  final String? description;
  final String? group;

  /// Convert to Monaco keybinding format
  Map<String, dynamic> toMonacoKeybinding() {
    final binding = {
      'keybinding': _parseKeyToMonaco(key),
      'command': command,
    };

    if (when != null) binding['when'] = when!;
    if (args != null) binding['args'] = args!;

    return binding;
  }

  /// Parse key string to Monaco key code
  int _parseKeyToMonaco(String key) {
    // This is a simplified version - in real implementation,
    // you'd need to convert key strings to Monaco key codes
    // For now, return a placeholder
    return key.hashCode;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'command': command,
      'when': when,
      'args': args,
      'category': category.name,
      'description': description,
      'group': group,
    };
  }

  Keybinding copyWith({
    String? id,
    String? key,
    String? command,
    String? when,
    Map<String, dynamic>? args,
    KeybindingCategory? category,
    String? description,
    String? group,
  }) {
    return Keybinding(
      id: id ?? this.id,
      key: key ?? this.key,
      command: command ?? this.command,
      when: when ?? this.when,
      args: args ?? this.args,
      category: category ?? this.category,
      description: description ?? this.description,
      group: group ?? this.group,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Keybinding &&
        other.id == id &&
        other.key == key &&
        other.command == command;
  }

  @override
  int get hashCode => Object.hash(id, key, command);

  @override
  String toString() => 'Keybinding(id: $id, key: $key, command: $command)';
}

/// Keybinding preset containing multiple keybindings
@immutable
class KeybindingPreset {
  const KeybindingPreset({
    required this.id,
    required this.name,
    required this.keybindings,
    this.description,
    this.isBuiltIn = false,
    this.isCustom = false,
  });

  /// Create from JSON
  factory KeybindingPreset.fromJson(Map<String, dynamic> json) {
    return KeybindingPreset(
      id: json.getString('id'),
      name: json.getString('name'),
      keybindings: json
          .getList('keybindings', defaultValue: [])
          .map((kb) => Keybinding.fromJson(kb as Map<String, dynamic>))
          .toList(),
      description: json.tryGetString('description'),
      isBuiltIn: json.getBool('isBuiltIn', defaultValue: false),
      isCustom: json.getBool('isCustom', defaultValue: false),
    );
  }

  final String id;
  final String name;
  final List<Keybinding> keybindings;
  final String? description;
  final bool isBuiltIn;
  final bool isCustom;

  /// Get keybindings by category
  List<Keybinding> getKeybindingsByCategory(KeybindingCategory category) {
    return keybindings.where((kb) => kb.category == category).toList();
  }

  /// Find keybinding by ID
  Keybinding? findKeybindingById(String id) {
    return keybindings.cast<Keybinding?>().firstWhere(
          (kb) => kb?.id == id,
          orElse: () => null,
        );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keybindings': keybindings.map((kb) => kb.toJson()).toList(),
      'description': description,
      'isBuiltIn': isBuiltIn,
      'isCustom': isCustom,
    };
  }

  KeybindingPreset copyWith({
    String? id,
    String? name,
    List<Keybinding>? keybindings,
    String? description,
    bool? isBuiltIn,
    bool? isCustom,
  }) {
    return KeybindingPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      keybindings: keybindings ?? this.keybindings,
      description: description ?? this.description,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeybindingPreset && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() =>
      'KeybindingPresetEnum(id: $id, name: $name, keybindings: ${keybindings.length})';
}

/// Keybinding manager for handling keybinding operations
class KeybindingManager {
  /// VS Code style keybindings (default)
  static const vsCodePreset = KeybindingPreset(
    id: 'vscode',
    name: 'VS Code',
    description: 'Default VS Code keybindings',
    isBuiltIn: true,
    keybindings: [
      // File operations
      Keybinding(
        id: 'file.save',
        key: 'ctrl+s',
        command: 'editor.action.save',
        category: KeybindingCategory.file,
        description: 'Save file',
        group: 'File Operations',
      ),
      Keybinding(
        id: 'file.saveAll',
        key: 'ctrl+k s',
        command: 'workbench.action.files.saveAll',
        category: KeybindingCategory.file,
        description: 'Save all files',
        group: 'File Operations',
      ),
      Keybinding(
        id: 'file.newFile',
        key: 'ctrl+n',
        command: 'workbench.action.files.newUntitledFile',
        category: KeybindingCategory.file,
        description: 'New file',
        group: 'File Operations',
      ),

      // Editing
      Keybinding(
        id: 'edit.undo',
        key: 'ctrl+z',
        command: 'undo',
        category: KeybindingCategory.editing,
        description: 'Undo',
        group: 'Basic Editing',
      ),
      Keybinding(
        id: 'edit.redo',
        key: 'ctrl+y',
        command: 'redo',
        category: KeybindingCategory.editing,
        description: 'Redo',
        group: 'Basic Editing',
      ),
      Keybinding(
        id: 'edit.cut',
        key: 'ctrl+x',
        command: 'editor.action.clipboardCutAction',
        category: KeybindingCategory.editing,
        description: 'Cut',
        group: 'Basic Editing',
      ),
      Keybinding(
        id: 'edit.copy',
        key: 'ctrl+c',
        command: 'editor.action.clipboardCopyAction',
        category: KeybindingCategory.editing,
        description: 'Copy',
        group: 'Basic Editing',
      ),
      Keybinding(
        id: 'edit.paste',
        key: 'ctrl+v',
        command: 'editor.action.clipboardPasteAction',
        category: KeybindingCategory.editing,
        description: 'Paste',
        group: 'Basic Editing',
      ),
      Keybinding(
        id: 'edit.selectAll',
        key: 'ctrl+a',
        command: 'editor.action.selectAll',
        category: KeybindingCategory.selection,
        description: 'Select all',
        group: 'Selection',
      ),
      Keybinding(
        id: 'edit.commentLine',
        key: 'ctrl+/',
        command: 'editor.action.commentLine',
        category: KeybindingCategory.editing,
        description: 'Toggle line comment',
        group: 'Comments',
      ),
      Keybinding(
        id: 'edit.commentBlock',
        key: 'shift+alt+a',
        command: 'editor.action.blockComment',
        category: KeybindingCategory.editing,
        description: 'Toggle block comment',
        group: 'Comments',
      ),
      Keybinding(
        id: 'edit.format',
        key: 'shift+alt+f',
        command: 'editor.action.formatDocument',
        category: KeybindingCategory.editing,
        description: 'Format document',
        group: 'Formatting',
      ),

      // Navigation
      Keybinding(
        id: 'nav.goToLine',
        key: 'ctrl+g',
        command: 'editor.action.gotoLine',
        category: KeybindingCategory.navigation,
        description: 'Go to line',
        group: 'Navigation',
      ),
      Keybinding(
        id: 'nav.goToDefinition',
        key: 'f12',
        command: 'editor.action.revealDefinition',
        category: KeybindingCategory.navigation,
        description: 'Go to definition',
        group: 'Navigation',
      ),
      Keybinding(
        id: 'nav.goBack',
        key: 'alt+left',
        command: 'workbench.action.navigateBack',
        category: KeybindingCategory.navigation,
        description: 'Go back',
        group: 'Navigation',
      ),
      Keybinding(
        id: 'nav.goForward',
        key: 'alt+right',
        command: 'workbench.action.navigateForward',
        category: KeybindingCategory.navigation,
        description: 'Go forward',
        group: 'Navigation',
      ),

      // Search
      Keybinding(
        id: 'search.find',
        key: 'ctrl+f',
        command: 'actions.find',
        category: KeybindingCategory.search,
        description: 'Find',
        group: 'Search',
      ),
      Keybinding(
        id: 'search.replace',
        key: 'ctrl+h',
        command: 'editor.action.startFindReplaceAction',
        category: KeybindingCategory.search,
        description: 'Replace',
        group: 'Search',
      ),
      Keybinding(
        id: 'search.findNext',
        key: 'f3',
        command: 'editor.action.nextMatchFindAction',
        category: KeybindingCategory.search,
        description: 'Find next',
        group: 'Search',
      ),
      Keybinding(
        id: 'search.findPrevious',
        key: 'shift+f3',
        command: 'editor.action.previousMatchFindAction',
        category: KeybindingCategory.search,
        description: 'Find previous',
        group: 'Search',
      ),

      // Selection
      Keybinding(
        id: 'select.word',
        key: 'ctrl+d',
        command: 'editor.action.addSelectionToNextFindMatch',
        category: KeybindingCategory.selection,
        description: 'Select word',
        group: 'Multi-Selection',
      ),
      Keybinding(
        id: 'select.allOccurrences',
        key: 'ctrl+shift+l',
        command: 'editor.action.selectHighlights',
        category: KeybindingCategory.selection,
        description: 'Select all occurrences',
        group: 'Multi-Selection',
      ),
      Keybinding(
        id: 'select.line',
        key: 'ctrl+l',
        command: 'editor.action.selectLine',
        category: KeybindingCategory.selection,
        description: 'Select line',
        group: 'Selection',
      ),

      // View
      Keybinding(
        id: 'view.zoomIn',
        key: 'ctrl+=',
        command: 'editor.action.fontZoomIn',
        category: KeybindingCategory.view,
        description: 'Zoom in',
        group: 'View',
      ),
      Keybinding(
        id: 'view.zoomOut',
        key: 'ctrl+-',
        command: 'editor.action.fontZoomOut',
        category: KeybindingCategory.view,
        description: 'Zoom out',
        group: 'View',
      ),
      Keybinding(
        id: 'view.resetZoom',
        key: 'ctrl+0',
        command: 'editor.action.fontZoomReset',
        category: KeybindingCategory.view,
        description: 'Reset zoom',
        group: 'View',
      ),

      // General
      Keybinding(
        id: 'general.commandPalette',
        key: 'ctrl+shift+p',
        command: 'editor.action.quickCommand',
        description: 'Command palette',
        group: 'General',
      ),
      Keybinding(
        id: 'general.quickOpen',
        key: 'ctrl+p',
        command: 'workbench.action.quickOpen',
        description: 'Quick open',
        group: 'General',
      ),
      Keybinding(
        id: 'general.preferences',
        key: 'ctrl+,',
        command: 'workbench.action.openSettings',
        description: 'Open settings',
        group: 'General',
      ),
    ],
  );

  /// IntelliJ/WebStorm style keybindings
  static const intellijPreset = KeybindingPreset(
    id: 'intellij',
    name: 'IntelliJ IDEA',
    description: 'IntelliJ IDEA / WebStorm keybindings',
    isBuiltIn: true,
    keybindings: [
      // File operations
      Keybinding(
        id: 'file.save',
        key: 'ctrl+s',
        command: 'editor.action.save',
        category: KeybindingCategory.file,
        description: 'Save file',
      ),
      Keybinding(
        id: 'file.saveAll',
        key: 'ctrl+shift+s',
        command: 'workbench.action.files.saveAll',
        category: KeybindingCategory.file,
        description: 'Save all files',
      ),

      // Editing
      Keybinding(
        id: 'edit.commentLine',
        key: 'ctrl+/',
        command: 'editor.action.commentLine',
        category: KeybindingCategory.editing,
        description: 'Toggle line comment',
      ),
      Keybinding(
        id: 'edit.commentBlock',
        key: 'ctrl+shift+/',
        command: 'editor.action.blockComment',
        category: KeybindingCategory.editing,
        description: 'Toggle block comment',
      ),
      Keybinding(
        id: 'edit.format',
        key: 'ctrl+alt+l',
        command: 'editor.action.formatDocument',
        category: KeybindingCategory.editing,
        description: 'Format document',
      ),
      Keybinding(
        id: 'edit.duplicateLine',
        key: 'ctrl+d',
        command: 'editor.action.copyLinesDownAction',
        category: KeybindingCategory.editing,
        description: 'Duplicate line',
      ),

      // Navigation
      Keybinding(
        id: 'nav.goToLine',
        key: 'ctrl+g',
        command: 'editor.action.gotoLine',
        category: KeybindingCategory.navigation,
        description: 'Go to line',
      ),
      Keybinding(
        id: 'nav.goToDeclaration',
        key: 'ctrl+b',
        command: 'editor.action.revealDefinition',
        category: KeybindingCategory.navigation,
        description: 'Go to declaration',
      ),

      // Search
      Keybinding(
        id: 'search.find',
        key: 'ctrl+f',
        command: 'actions.find',
        category: KeybindingCategory.search,
        description: 'Find',
      ),
      Keybinding(
        id: 'search.replace',
        key: 'ctrl+r',
        command: 'editor.action.startFindReplaceAction',
        category: KeybindingCategory.search,
        description: 'Replace',
      ),
      Keybinding(
        id: 'search.findInFiles',
        key: 'ctrl+shift+f',
        command: 'workbench.action.findInFiles',
        category: KeybindingCategory.search,
        description: 'Find in files',
      ),

      // General
      Keybinding(
        id: 'general.commandPalette',
        key: 'ctrl+shift+a',
        command: 'editor.action.quickCommand',
        description: 'Find action',
      ),
    ],
  );

  /// Vim-style keybindings (basic)
  static const vimPreset = KeybindingPreset(
    id: 'vim',
    name: 'Vim',
    description: 'Basic Vim-style keybindings',
    isBuiltIn: true,
    keybindings: [
      // These would need special handling in Monaco
      Keybinding(
        id: 'vim.escape',
        key: 'escape',
        command: 'vim.escapeKey',
        description: 'Escape to normal mode',
      ),
      Keybinding(
        id: 'vim.save',
        key: ':w',
        command: 'editor.action.save',
        category: KeybindingCategory.file,
        description: 'Save file (Vim style)',
      ),
    ],
  );

  /// Emacs-style keybindings
  static const emacsPreset = KeybindingPreset(
    id: 'emacs',
    name: 'Emacs',
    description: 'Emacs-style keybindings',
    isBuiltIn: true,
    keybindings: [
      // File operations
      Keybinding(
        id: 'file.save',
        key: 'ctrl+x ctrl+s',
        command: 'editor.action.save',
        category: KeybindingCategory.file,
        description: 'Save file',
      ),
      Keybinding(
        id: 'file.open',
        key: 'ctrl+x ctrl+f',
        command: 'workbench.action.files.openFile',
        category: KeybindingCategory.file,
        description: 'Open file',
      ),

      // Editing
      Keybinding(
        id: 'edit.cut',
        key: 'ctrl+w',
        command: 'editor.action.clipboardCutAction',
        category: KeybindingCategory.editing,
        description: 'Cut',
      ),
      Keybinding(
        id: 'edit.copy',
        key: 'alt+w',
        command: 'editor.action.clipboardCopyAction',
        category: KeybindingCategory.editing,
        description: 'Copy',
      ),
      Keybinding(
        id: 'edit.paste',
        key: 'ctrl+y',
        command: 'editor.action.clipboardPasteAction',
        category: KeybindingCategory.editing,
        description: 'Paste',
      ),

      // Navigation
      Keybinding(
        id: 'nav.beginningOfLine',
        key: 'ctrl+a',
        command: 'cursorHome',
        category: KeybindingCategory.navigation,
        description: 'Beginning of line',
      ),
      Keybinding(
        id: 'nav.endOfLine',
        key: 'ctrl+e',
        command: 'cursorEnd',
        category: KeybindingCategory.navigation,
        description: 'End of line',
      ),

      // Search
      Keybinding(
        id: 'search.find',
        key: 'ctrl+s',
        command: 'actions.find',
        category: KeybindingCategory.search,
        description: 'Incremental search',
      ),
    ],
  );

  /// Get all built-in presets
  static List<KeybindingPreset> get builtInPresets => [
        vsCodePreset,
        intellijPreset,
        vimPreset,
        emacsPreset,
      ];

  /// Get all available presets
  static List<KeybindingPreset> getAllPresets({
    List<KeybindingPreset> customPresets = const [],
  }) {
    return [...builtInPresets, ...customPresets];
  }

  /// Find preset by ID
  static KeybindingPreset? findPresetById(
    String id, {
    List<KeybindingPreset> customPresets = const [],
  }) {
    return getAllPresets(customPresets: customPresets)
        .cast<KeybindingPreset?>()
        .firstWhere(
          (preset) => preset?.id == id,
          orElse: () => null,
        );
  }

  /// Get keybindings by category across all presets
  static List<Keybinding> getKeybindingsByCategory(
    KeybindingCategory category, {
    List<KeybindingPreset> customPresets = const [],
  }) {
    final allKeybindings = <Keybinding>[];
    for (final preset in getAllPresets(customPresets: customPresets)) {
      allKeybindings.addAll(preset.getKeybindingsByCategory(category));
    }
    return allKeybindings;
  }

  /// Detect conflicts between keybindings
  static List<String> detectConflicts(List<Keybinding> keybindings) {
    final conflicts = <String>[];
    final keyMap = <String, List<Keybinding>>{};

    // Group by key
    for (final keybinding in keybindings) {
      keyMap.putIfAbsent(keybinding.key, () => []).add(keybinding);
    }

    // Find conflicts
    for (final entry in keyMap.entries) {
      if (entry.value.length > 1) {
        final commands = entry.value.map((kb) => kb.command).join(', ');
        conflicts.add('Key "${entry.key}" conflicts: $commands');
      }
    }

    return conflicts;
  }

  /// Merge multiple keybinding presets
  static KeybindingPreset mergePresets(
    List<KeybindingPreset> presets, {
    required String id,
    required String name,
    String? description,
  }) {
    final allKeybindings = <Keybinding>[];
    final seenKeys = <String>{};

    // Add keybindings, with later presets overriding earlier ones
    for (final preset in presets) {
      for (final keybinding in preset.keybindings) {
        if (!seenKeys.contains(keybinding.key)) {
          allKeybindings.add(keybinding);
          seenKeys.add(keybinding.key);
        }
      }
    }

    return KeybindingPreset(
      id: id,
      name: name,
      description: description,
      keybindings: allKeybindings,
      isCustom: true,
    );
  }

  /// Export keybindings to JSON format
  static Map<String, dynamic> exportKeybindings(KeybindingPreset preset) {
    return {
      'name': preset.name,
      'description': preset.description,
      'keybindings': preset.keybindings
          .map((kb) => {
                'key': kb.key,
                'command': kb.command,
                'when': kb.when,
                'args': kb.args,
              })
          .toList(),
    };
  }

  /// Import keybindings from JSON format
  static KeybindingPreset? importKeybindings(Map<String, dynamic> json) {
    try {
      final name = json.getString('name');
      final keybindings = <Keybinding>[];

      for (final kbJson in json.getList('keybindings', defaultValue: [])) {
        if (kbJson is Map<String, dynamic>) {
          keybindings.add(
            Keybinding(
              id: '${name.toLowerCase()}.${kbJson.getString('command')}',
              key: kbJson.getString('key'),
              command: kbJson.getString('command'),
              when: kbJson.tryGetString('when'),
              args: kbJson.tryGetMap('args'),
              category: KeybindingCategory.custom,
            ),
          );
        }
      }

      return KeybindingPreset(
        id: name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '-'),
        name: name,
        description: json.tryGetString('description'),
        keybindings: keybindings,
        isCustom: true,
      );
    } catch (e) {
      return null;
    }
  }
}
