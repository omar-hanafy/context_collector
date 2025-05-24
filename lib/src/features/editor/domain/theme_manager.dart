import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/foundation.dart';

/// Theme category for organization
enum ThemeCategory { light, dark, highContrast, custom }

/// Monaco editor theme definition
@immutable
class EditorTheme {
  const EditorTheme({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.author,
    this.base = 'vs-dark',
    this.inherit = true,
    this.colors = const {},
    this.rules = const [],
    this.encodedTokensColors = const [],
    this.isBuiltIn = false,
    this.isCustom = false,
  });

  /// Create from JSON
  factory EditorTheme.fromJson(Map<String, dynamic> json) {
    return EditorTheme(
      id: json.getString('id'),
      name: json.getString('name'),
      category: ThemeCategory.values.firstWhere(
        (c) => c.name == json.getString('category'),
        orElse: () => ThemeCategory.custom,
      ),
      description: json.tryGetString('description'),
      author: json.tryGetString('author'),
      base: json.getString('base', defaultValue: 'vs-dark'),
      inherit: json.getBool('inherit', defaultValue: true),
      colors: json.getMap('colors', defaultValue: {}).cast<String, String>(),
      rules:
          json.getList('rules', defaultValue: []).cast<Map<String, dynamic>>(),
      encodedTokensColors:
          json.getList('encodedTokensColors', defaultValue: []).cast<String>(),
      isBuiltIn: json.getBool('isBuiltIn', defaultValue: false),
      isCustom: json.getBool('isCustom', defaultValue: false),
    );
  }

  final String id;
  final String name;
  final ThemeCategory category;
  final String? description;
  final String? author;
  final String base; // 'vs', 'vs-dark', or 'hc-black'
  final bool inherit;
  final Map<String, String> colors;
  final List<Map<String, dynamic>> rules;
  final List<String> encodedTokensColors;
  final bool isBuiltIn;
  final bool isCustom;

  /// Convert to Monaco theme data format
  Map<String, dynamic> toMonacoThemeData() {
    return {
      'base': base,
      'inherit': inherit,
      'rules': rules,
      'encodedTokensColors': encodedTokensColors,
      'colors': colors,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'description': description,
      'author': author,
      'base': base,
      'inherit': inherit,
      'colors': colors,
      'rules': rules,
      'encodedTokensColors': encodedTokensColors,
      'isBuiltIn': isBuiltIn,
      'isCustom': isCustom,
    };
  }

  EditorTheme copyWith({
    String? id,
    String? name,
    ThemeCategory? category,
    String? description,
    String? author,
    String? base,
    bool? inherit,
    Map<String, String>? colors,
    List<Map<String, dynamic>>? rules,
    List<String>? encodedTokensColors,
    bool? isBuiltIn,
    bool? isCustom,
  }) {
    return EditorTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      author: author ?? this.author,
      base: base ?? this.base,
      inherit: inherit ?? this.inherit,
      colors: colors ?? this.colors,
      rules: rules ?? this.rules,
      encodedTokensColors: encodedTokensColors ?? this.encodedTokensColors,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditorTheme &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.base == base;
  }

  @override
  int get hashCode => Object.hash(id, name, category, base);

  @override
  String toString() => 'EditorTheme(id: $id, name: $name, category: $category)';
}

/// Theme manager for handling theme operations
class ThemeManager {
  static const List<EditorTheme> builtInThemes = [
    EditorTheme(
      id: 'vs',
      name: 'Visual Studio Light',
      category: ThemeCategory.light,
      description: 'Classic light theme inspired by Visual Studio',
      base: 'vs',
      isBuiltIn: true,
    ),
    EditorTheme(
      id: 'vs-dark',
      name: 'Visual Studio Dark',
      category: ThemeCategory.dark,
      description: 'Classic dark theme inspired by Visual Studio',
      base: 'vs-dark',
      isBuiltIn: true,
    ),
    EditorTheme(
      id: 'hc-black',
      name: 'High Contrast Dark',
      category: ThemeCategory.highContrast,
      description: 'High contrast dark theme for accessibility',
      base: 'hc-black',
      isBuiltIn: true,
    ),
    EditorTheme(
      id: 'one-dark-pro',
      name: 'One Dark Pro',
      category: ThemeCategory.dark,
      description: 'Popular dark theme inspired by Atom',
      author: 'binaryify',
      base: 'vs-dark',
      isBuiltIn: true,
    ),
    EditorTheme(
      id: 'one-dark-pro-transparent',
      name: 'One Dark Pro Transparent',
      category: ThemeCategory.dark,
      description: 'One Dark Pro with transparent background',
      author: 'binaryify',
      base: 'vs-dark',
      isBuiltIn: true,
    ),
  ];

  /// Get all available themes
  static List<EditorTheme> getAllThemes({
    List<EditorTheme> customThemes = const [],
  }) {
    return [...builtInThemes, ...customThemes];
  }

  /// Get themes by category
  static List<EditorTheme> getThemesByCategory(
    ThemeCategory category, {
    List<EditorTheme> customThemes = const [],
  }) {
    return getAllThemes(customThemes: customThemes)
        .where((theme) => theme.category == category)
        .toList();
  }

  /// Find theme by ID
  static EditorTheme? findThemeById(
    String id, {
    List<EditorTheme> customThemes = const [],
  }) {
    return getAllThemes(customThemes: customThemes)
        .cast<EditorTheme?>()
        .firstWhere(
          (theme) => theme?.id == id,
          orElse: () => null,
        );
  }

  /// Get default theme for category
  static EditorTheme getDefaultThemeForCategory(ThemeCategory category) {
    switch (category) {
      case ThemeCategory.light:
        return builtInThemes.firstWhere((t) => t.id == 'vs');
      case ThemeCategory.dark:
        return builtInThemes.firstWhere((t) => t.id == 'vs-dark');
      case ThemeCategory.highContrast:
        return builtInThemes.firstWhere((t) => t.id == 'hc-black');
      case ThemeCategory.custom:
        return builtInThemes.firstWhere((t) => t.id == 'vs-dark');
    }
  }

  /// Create theme from VS Code theme format
  static EditorTheme fromVSCodeTheme(Map<String, dynamic> vscodeTheme) {
    final name = vscodeTheme.tryGetString('name') ?? 'Unnamed Theme';
    final type = vscodeTheme.tryGetString('type') ?? 'dark';

    ThemeCategory category;
    String base;

    switch (type.toLowerCase()) {
      case 'light':
        category = ThemeCategory.light;
        base = 'vs';
      case 'hc':
      case 'high-contrast':
        category = ThemeCategory.highContrast;
        base = 'hc-black';
      default:
        category = ThemeCategory.dark;
        base = 'vs-dark';
    }

    return EditorTheme(
      id: name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '-'),
      name: name,
      category: category,
      description: 'Imported from VS Code theme',
      base: base,
      colors: (vscodeTheme.tryGetMap('colors') ?? {}).cast<String, String>(),
      rules: _convertVSCodeTokenColors(
          vscodeTheme.tryGetList('tokenColors') ?? []),
      isCustom: true,
    );
  }

  /// Convert VS Code token colors to Monaco rules
  static List<Map<String, dynamic>> _convertVSCodeTokenColors(
      List<dynamic> tokenColors) {
    final rules = <Map<String, dynamic>>[];

    for (final tokenColor in tokenColors) {
      if (tokenColor is! Map<String, dynamic>) continue;

      final scope = tokenColor.tryGetString('scope') ??
          tokenColor.tryGetList<String>('scope')?.first;
      final settings = tokenColor.tryGetMap('settings');

      if (scope != null && settings != null) {
        final rule = <String, dynamic>{
          'token': scope,
        };

        final foreground = settings.tryGetString('foreground');
        if (foreground != null) {
          rule['foreground'] = foreground.replaceFirst('#', '');
        }

        final fontStyle = settings.tryGetString('fontStyle');
        if (fontStyle != null) {
          rule['fontStyle'] = fontStyle;
        }

        rules.add(rule);
      }
    }

    return rules;
  }

  /// Validate theme data
  static bool isValidTheme(Map<String, dynamic> themeData) {
    try {
      return themeData.containsKey('name') &&
          themeData.containsKey('base') &&
          ['vs', 'vs-dark', 'hc-black'].contains(themeData['base']);
    } catch (e) {
      return false;
    }
  }

  /// Generate theme preview colors
  static Map<String, String> getThemePreviewColors(EditorTheme theme) {
    final colors = theme.colors;
    return {
      'background': colors['editor.background'] ??
          (theme.base == 'vs' ? '#ffffff' : '#1e1e1e'),
      'foreground': colors['editor.foreground'] ??
          (theme.base == 'vs' ? '#000000' : '#d4d4d4'),
      'selection': colors['editor.selectionBackground'] ??
          (theme.base == 'vs' ? '#add6ff' : '#264f78'),
      'lineNumber': colors['editorLineNumber.foreground'] ??
          (theme.base == 'vs' ? '#237893' : '#858585'),
      'accent':
          colors['focusBorder'] ?? (theme.base == 'vs' ? '#005fb8' : '#007acc'),
    };
  }
}
