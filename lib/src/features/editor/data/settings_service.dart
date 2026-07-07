import 'dart:convert';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the app's editor preferences in flutter_monaco v3's native shape.
class EditorSettingsService {
  static const String _storageKey = 'editor_options';

  /// Fully materialized app defaults for settings UI and persistence.
  ///
  /// flutter_monaco v3 keeps [EditorOptions] sparse by design. The app still
  /// needs concrete values for controls, so defaults live here and saved user
  /// values are merged over them.
  static const EditorOptions defaultOptions = EditorOptions(
    language: MonacoDefaults.language,
    theme: MonacoDefaults.darkTheme,
    fontSize: 14,
    fontFamily: MonacoFontStacks.cascadiaCodePrimary,
    fontLigatures: false,
    wordWrap: MonacoWordWrap.on,
    minimap: MonacoMinimapOptions(enabled: false),
    lineNumbers: MonacoLineNumbers.on,
    rulers: [],
    tabSize: 4,
    insertSpaces: true,
    readOnly: false,
    automaticLayout: true,
    padding: MonacoPadding(top: 10),
    scrollBeyondLastLine: true,
    smoothScrolling: true,
    mouseWheelZoom: true,
    cursorBlinking: CursorBlinking.blink,
    cursorStyle: CursorStyle.line,
    renderWhitespace: RenderWhitespace.selection,
    bracketPairColorization: true,
    autoClosingBrackets: AutoClosingBehavior.languageDefined,
    autoClosingQuotes: AutoClosingBehavior.languageDefined,
    formatOnPaste: false,
    formatOnType: false,
    quickSuggestions: true,
    parameterHints: true,
    hover: true,
    contextMenu: true,
    roundedSelection: true,
    selectionHighlight: true,
    overviewRulerBorder: true,
    renderControlCharacters: false,
    disableLayerHinting: false,
    disableMonospaceOptimizations: false,
  );

  static MonacoTheme effectiveTheme(EditorOptions options) {
    return options.theme ?? defaultOptions.theme ?? MonacoDefaults.darkTheme;
  }

  static MonacoWordWrap effectiveWordWrap(EditorOptions options) {
    return options.wordWrap ?? defaultOptions.wordWrap ?? MonacoWordWrap.on;
  }

  static bool wordWrapEnabled(EditorOptions options) {
    return effectiveWordWrap(options) != MonacoWordWrap.off;
  }

  static bool minimapEnabled(EditorOptions options) {
    return options.minimap?.enabled ?? defaultOptions.minimap?.enabled ?? false;
  }

  static bool lineNumbersEnabled(EditorOptions options) {
    return (options.lineNumbers ??
            defaultOptions.lineNumbers ??
            MonacoLineNumbers.on) !=
        MonacoLineNumbers.off;
  }

  static double fontSize(EditorOptions options) {
    return options.fontSize ?? defaultOptions.fontSize ?? 14;
  }

  static String fontFamily(EditorOptions options) {
    return options.fontFamily ??
        defaultOptions.fontFamily ??
        MonacoFontStacks.cascadiaCodePrimary;
  }

  static int tabSize(EditorOptions options) {
    return options.tabSize ?? defaultOptions.tabSize ?? 4;
  }

  static bool boolValue(
    EditorOptions options,
    bool? Function(EditorOptions options) read,
  ) {
    return read(options) ?? read(defaultOptions) ?? false;
  }

  /// Save EditorOptions to SharedPreferences.
  static Future<void> save(EditorOptions options) async {
    final prefs = await SharedPreferences.getInstance();
    final materialized = defaultOptions.merge(options);
    await prefs.setString(_storageKey, jsonEncode(materialized.toJson()));
  }

  /// Load EditorOptions from SharedPreferences.
  static Future<EditorOptions> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      return defaultOptions;
    }

    try {
      final raw = jsonDecode(jsonString);
      if (raw is! Map<String, dynamic>) {
        return defaultOptions;
      }

      final parsed = _parseStoredOptions(raw);
      final materialized = defaultOptions.merge(parsed);
      if (parsed.toJson().toString() != raw.toString()) {
        await prefs.setString(_storageKey, jsonEncode(materialized.toJson()));
      }
      return materialized;
    } catch (_) {
      return defaultOptions;
    }
  }

  static EditorOptions _parseStoredOptions(Map<String, dynamic> raw) {
    try {
      return EditorOptions.fromJson(raw);
    } on FormatException {
      return _migrateLegacyOptions(raw);
    }
  }

  static EditorOptions _migrateLegacyOptions(Map<String, dynamic> legacy) {
    var migrated = defaultOptions;

    final language = _string(legacy['language']);
    if (language != null && language.trim().isNotEmpty) {
      migrated = migrated.copyWith(language: MonacoLanguage(language));
    }

    final theme = _string(legacy['theme']) ?? _string(legacy['themeId']);
    if (theme != null && theme.trim().isNotEmpty) {
      migrated = migrated.copyWith(theme: MonacoTheme(theme));
    }

    return migrated.copyWith(
      fontSize: _double(legacy['fontSize']) ?? migrated.fontSize,
      fontFamily: _string(legacy['fontFamily']) ?? migrated.fontFamily,
      fontLigatures: _bool(legacy['fontLigatures']) ?? migrated.fontLigatures,
      lineHeight:
          _legacyLineHeight(legacy['lineHeight']) ?? migrated.lineHeight,
      wordWrap: _wordWrap(legacy['wordWrap']) ?? migrated.wordWrap,
      minimap: _minimap(legacy['minimap']) ?? migrated.minimap,
      lineNumbers: _lineNumbers(legacy['lineNumbers']) ?? migrated.lineNumbers,
      rulers: _intList(legacy['rulers']) ?? migrated.rulers,
      tabSize: _int(legacy['tabSize']) ?? migrated.tabSize,
      insertSpaces: _bool(legacy['insertSpaces']) ?? migrated.insertSpaces,
      readOnly: _bool(legacy['readOnly']) ?? migrated.readOnly,
      automaticLayout:
          _bool(legacy['automaticLayout']) ?? migrated.automaticLayout,
      padding: _padding(legacy['padding']) ?? migrated.padding,
      scrollBeyondLastLine:
          _bool(legacy['scrollBeyondLastLine']) ??
          migrated.scrollBeyondLastLine,
      smoothScrolling:
          _bool(legacy['smoothScrolling']) ?? migrated.smoothScrolling,
      mouseWheelZoom:
          _bool(legacy['mouseWheelZoom']) ?? migrated.mouseWheelZoom,
      cursorBlinking:
          _enumById(
            legacy['cursorBlinking'],
            CursorBlinking.values,
            (value) => value.id,
          ) ??
          migrated.cursorBlinking,
      cursorStyle:
          _enumById(
            legacy['cursorStyle'],
            CursorStyle.values,
            (value) => value.id,
          ) ??
          migrated.cursorStyle,
      renderWhitespace:
          _enumById(
            legacy['renderWhitespace'],
            RenderWhitespace.values,
            (value) => value.id,
          ) ??
          migrated.renderWhitespace,
      bracketPairColorization:
          _bool(legacy['bracketPairColorization']) ??
          migrated.bracketPairColorization,
      autoClosingBrackets:
          _enumById(
            legacy['autoClosingBrackets'],
            AutoClosingBehavior.values,
            (value) => value.id,
          ) ??
          migrated.autoClosingBrackets,
      autoClosingQuotes:
          _enumById(
            legacy['autoClosingQuotes'],
            AutoClosingBehavior.values,
            (value) => value.id,
          ) ??
          migrated.autoClosingQuotes,
      formatOnPaste: _bool(legacy['formatOnPaste']) ?? migrated.formatOnPaste,
      formatOnType: _bool(legacy['formatOnType']) ?? migrated.formatOnType,
      quickSuggestions:
          _bool(legacy['quickSuggestions']) ?? migrated.quickSuggestions,
      parameterHints:
          _bool(legacy['parameterHints']) ?? migrated.parameterHints,
      hover: _bool(legacy['hover']) ?? migrated.hover,
      contextMenu:
          _bool(legacy['contextMenu']) ??
          _bool(legacy['contextmenu']) ??
          migrated.contextMenu,
      roundedSelection:
          _bool(legacy['roundedSelection']) ?? migrated.roundedSelection,
      selectionHighlight:
          _bool(legacy['selectionHighlight']) ?? migrated.selectionHighlight,
      overviewRulerBorder:
          _bool(legacy['overviewRulerBorder']) ?? migrated.overviewRulerBorder,
      renderControlCharacters:
          _bool(legacy['renderControlCharacters']) ??
          migrated.renderControlCharacters,
      disableLayerHinting:
          _bool(legacy['disableLayerHinting']) ?? migrated.disableLayerHinting,
      disableMonospaceOptimizations:
          _bool(legacy['disableMonospaceOptimizations']) ??
          migrated.disableMonospaceOptimizations,
    );
  }

  static String? _string(Object? value) {
    if (value is String) return value;
    return null;
  }

  static int? _int(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double? _legacyLineHeight(Object? value) {
    final parsed = _double(value);
    if (parsed == null || parsed <= 0) return null;
    return parsed < 8 ? defaultOptions.fontSize! * parsed : parsed;
  }

  static bool? _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == 'on') return true;
      if (normalized == 'false' || normalized == 'off') return false;
    }
    if (value is Map) {
      return _bool(value['enabled']);
    }
    return null;
  }

  static List<int>? _intList(Object? value) {
    if (value is! List) return null;
    final result = <int>[];
    for (final entry in value) {
      final parsed = _int(entry);
      if (parsed == null) return null;
      result.add(parsed);
    }
    return result;
  }

  static T? _enumById<T>(
    Object? value,
    List<T> values,
    String Function(T value) idOf,
  ) {
    final id = _string(value);
    if (id == null) return null;
    for (final candidate in values) {
      if (idOf(candidate) == id) return candidate;
    }
    return null;
  }

  static MonacoWordWrap? _wordWrap(Object? value) {
    return _enumById(value, MonacoWordWrap.values, (value) => value.id) ??
        switch (_bool(value)) {
          true => MonacoWordWrap.on,
          false => MonacoWordWrap.off,
          null => null,
        };
  }

  static MonacoLineNumbers? _lineNumbers(Object? value) {
    return _enumById(value, MonacoLineNumbers.values, (value) => value.id) ??
        switch (_bool(value)) {
          true => MonacoLineNumbers.on,
          false => MonacoLineNumbers.off,
          null => null,
        };
  }

  static MonacoMinimapOptions? _minimap(Object? value) {
    if (value is Map) {
      return MonacoMinimapOptions(
        enabled: _bool(value['enabled']),
        side: _enumById(
          value['side'],
          MonacoMinimapSide.values,
          (value) => value.id,
        ),
        renderCharacters: _bool(value['renderCharacters']),
        maxColumn: _int(value['maxColumn']),
        scale: _int(value['scale']),
      );
    }
    final enabled = _bool(value);
    return enabled == null ? null : MonacoMinimapOptions(enabled: enabled);
  }

  static MonacoPadding? _padding(Object? value) {
    if (value is! Map) return null;
    return MonacoPadding(
      top: _int(value['top']),
      bottom: _int(value['bottom']),
    );
  }

  /// Clear saved settings.
  static Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_storageKey);
  }

  /// True if there are persisted editor options.
  static Future<bool> hasSavedOptions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_storageKey);
  }
}
