import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple service for persisting EditorOptions
class EditorSettingsService {
  static const String _storageKey = 'editor_options';

  /// Build canonical JSON expected by EditorOptions.fromJson
  static Map<String, dynamic> _toStorageJson(EditorOptions o) {
    return <String, dynamic>{
      'language': o.language.id,
      'theme': o.theme.id,
      'fontSize': o.fontSize,
      'fontFamily': o.fontFamily,
      'lineHeight': o.lineHeight,
      'wordWrap': o.wordWrap,
      'minimap': o.minimap,
      'lineNumbers': o.lineNumbers,
      'rulers': o.rulers,
      'tabSize': o.tabSize,
      'insertSpaces': o.insertSpaces,
      'readOnly': o.readOnly,
      'automaticLayout': o.automaticLayout,
      if (o.padding != null) 'padding': o.padding,
      'scrollBeyondLastLine': o.scrollBeyondLastLine,
      'smoothScrolling': o.smoothScrolling,
      'cursorBlinking': o.cursorBlinking.id,
      'cursorStyle': o.cursorStyle.id,
      'renderWhitespace': o.renderWhitespace.id,
      'bracketPairColorization': o.bracketPairColorization,
      'autoClosingBrackets': o.autoClosingBrackets.id,
      'autoClosingQuotes': o.autoClosingQuotes.id,
      'formatOnPaste': o.formatOnPaste,
      'formatOnType': o.formatOnType,
      'quickSuggestions': o.quickSuggestions,
      'fontLigatures': o.fontLigatures,
      'parameterHints': o.parameterHints,
      'hover': o.hover,
      'contextMenu': o.contextMenu,
      'mouseWheelZoom': o.mouseWheelZoom,
      'roundedSelection': o.roundedSelection,
      'selectionHighlight': o.selectionHighlight,
      'overviewRulerBorder': o.overviewRulerBorder,
      'renderControlCharacters': o.renderControlCharacters,
      'disableLayerHinting': o.disableLayerHinting,
      'disableMonospaceOptimizations': o.disableMonospaceOptimizations,
    };
  }

  static bool _needsMigration(Map<String, dynamic> json) {
    if (json['lineNumbers'] is String) return true;
    if (json['wordWrap'] is String) return true;
    if (json['minimap'] is Map) return true;
    if (json['bracketPairColorization'] is Map) return true;
    if (json.containsKey('contextmenu')) return true;
    if (json['hover'] is Map) return true;
    if (json['parameterHints'] is Map) return true;
    // If canonical keys are missing but Monaco options present, migrate
    if (!json.containsKey('theme') && json.containsKey('fontSize')) return true;
    return false;
  }

  static Map<String, dynamic> _migrateToCanonical(
    Map<String, dynamic> legacy,
  ) {
    final out = <String, dynamic>{};

    // Defaults for any missing values
    const def = MonacoConstants.defaultOptions;

    bool parseBool(dynamic value, bool defBool) => ConvertObject.toBool(
      value,
      defaultValue: defBool,
      converter: (obj) {
        if (obj is Map) {
          final v = obj['enabled'];
          return ConvertObject.toBool(
            v,
            defaultValue: defBool,
            converter: (inner) {
              if (inner is String) {
                final s = inner.toLowerCase();
                if (s == 'on') return true;
                if (s == 'off') return false;
              }
              if (inner is num) return inner > 0;
              if (inner is bool) return inner;
              return defBool;
            },
          );
        }
        if (obj is String) {
          final s = obj.toLowerCase();
          if (s == 'on') return true;
          if (s == 'off') return false;
        }
        if (obj is num) return obj > 0;
        if (obj is bool) return obj;
        return defBool;
      },
    );

    out['language'] = ConvertObject.toString1(
      legacy,
      mapKey: 'language',
      defaultValue: def.language.id,
    );
    out['theme'] = ConvertObject.toString1(
      legacy,
      mapKey: 'theme',
      defaultValue: def.theme.id,
    );
    out['fontSize'] = ConvertObject.toDouble(
      legacy,
      mapKey: 'fontSize',
      defaultValue: def.fontSize,
    );
    out['fontFamily'] = ConvertObject.toString1(
      legacy,
      mapKey: 'fontFamily',
      defaultValue: def.fontFamily,
    );
    out['lineHeight'] = ConvertObject.toDouble(
      legacy,
      mapKey: 'lineHeight',
      defaultValue: def.lineHeight,
    );
    out['wordWrap'] = parseBool(legacy['wordWrap'], def.wordWrap);
    out['minimap'] = parseBool(legacy['minimap'], def.minimap);
    out['lineNumbers'] = parseBool(legacy['lineNumbers'], def.lineNumbers);

    final rulers = ConvertObject.tryToList<int>(
      legacy,
      mapKey: 'rulers',
      elementConverter: ConvertObject.toInt,
    );
    out['rulers'] = rulers ?? def.rulers;

    out['tabSize'] = ConvertObject.toInt(
      legacy,
      mapKey: 'tabSize',
      defaultValue: def.tabSize,
    );
    out['insertSpaces'] = parseBool(legacy['insertSpaces'], def.insertSpaces);
    out['readOnly'] = parseBool(legacy['readOnly'], def.readOnly);
    out['automaticLayout'] = parseBool(
      legacy['automaticLayout'],
      def.automaticLayout,
    );

    final padding = legacy['padding'];
    if (padding is Map) {
      final m = toMap<String, dynamic>(padding);
      if (m.isNotEmpty) {
        out['padding'] = m.map(
          (k, v) => MapEntry(k, ConvertObject.toInt(v, defaultValue: 0)),
        );
      }
    }

    out['scrollBeyondLastLine'] = parseBool(
      legacy['scrollBeyondLastLine'],
      def.scrollBeyondLastLine,
    );
    out['smoothScrolling'] = parseBool(
      legacy['smoothScrolling'],
      def.smoothScrolling,
    );
    out['cursorBlinking'] = ConvertObject.toString1(
      legacy,
      mapKey: 'cursorBlinking',
      defaultValue: def.cursorBlinking.id,
    );
    out['cursorStyle'] = ConvertObject.toString1(
      legacy,
      mapKey: 'cursorStyle',
      defaultValue: def.cursorStyle.id,
    );
    out['renderWhitespace'] = ConvertObject.toString1(
      legacy,
      mapKey: 'renderWhitespace',
      defaultValue: def.renderWhitespace.id,
    );
    out['bracketPairColorization'] = parseBool(
      legacy['bracketPairColorization'],
      def.bracketPairColorization,
    );
    out['autoClosingBrackets'] = ConvertObject.toString1(
      legacy,
      mapKey: 'autoClosingBrackets',
      defaultValue: def.autoClosingBrackets.id,
    );
    out['autoClosingQuotes'] = ConvertObject.toString1(
      legacy,
      mapKey: 'autoClosingQuotes',
      defaultValue: def.autoClosingQuotes.id,
    );
    out['formatOnPaste'] = parseBool(
      legacy['formatOnPaste'],
      def.formatOnPaste,
    );
    out['formatOnType'] = parseBool(legacy['formatOnType'], def.formatOnType);
    out['quickSuggestions'] = parseBool(
      legacy['quickSuggestions'],
      def.quickSuggestions,
    );
    out['fontLigatures'] = parseBool(
      legacy['fontLigatures'],
      def.fontLigatures,
    );
    out['parameterHints'] = parseBool(
      legacy['parameterHints'],
      def.parameterHints,
    );
    out['hover'] = parseBool(legacy['hover'], def.hover);

    final cm =
        ConvertObject.tryToBool(legacy, mapKey: 'contextMenu') ??
        ConvertObject.tryToBool(legacy, mapKey: 'contextmenu') ??
        def.contextMenu;
    out['contextMenu'] = cm;

    out['mouseWheelZoom'] = parseBool(
      legacy['mouseWheelZoom'],
      def.mouseWheelZoom,
    );
    out['roundedSelection'] = parseBool(
      legacy['roundedSelection'],
      def.roundedSelection,
    );
    out['selectionHighlight'] = parseBool(
      legacy['selectionHighlight'],
      def.selectionHighlight,
    );
    out['overviewRulerBorder'] = parseBool(
      legacy['overviewRulerBorder'],
      def.overviewRulerBorder,
    );
    out['renderControlCharacters'] = parseBool(
      legacy['renderControlCharacters'],
      def.renderControlCharacters,
    );
    out['disableLayerHinting'] = parseBool(
      legacy['disableLayerHinting'],
      def.disableLayerHinting,
    );
    out['disableMonospaceOptimizations'] = parseBool(
      legacy['disableMonospaceOptimizations'],
      def.disableMonospaceOptimizations,
    );

    return out;
  }

  /// Save EditorOptions to SharedPreferences
  static Future<void> save(EditorOptions options) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_toStorageJson(options)));
  }

  /// Load EditorOptions from SharedPreferences
  static Future<EditorOptions> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      // Return default options from MonacoConstants
      return MonacoConstants.defaultOptions;
    }

    try {
      final raw = jsonDecode(jsonString);
      if (raw is! Map<String, dynamic>) {
        return MonacoConstants.defaultOptions;
      }

      Map<String, dynamic> json = raw;
      if (_needsMigration(json)) {
        final canonical = _migrateToCanonical(json);
        await prefs.setString(_storageKey, jsonEncode(canonical));
        json = canonical;
      }

      return EditorOptions.fromJson(json);
    } catch (e) {
      // Return defaults on error
      return MonacoConstants.defaultOptions;
    }
  }

  /// Clear saved settings
  static Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_storageKey);
  }

  /// True if there are persisted editor options (used to detect first run)
  static Future<bool> hasSavedOptions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_storageKey);
  }
}
