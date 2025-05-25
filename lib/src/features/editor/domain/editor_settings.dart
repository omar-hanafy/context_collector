import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enums for better type safety
enum WordWrap {
  off,
  on,
  wordWrapColumn,
  bounded;

  bool get enabled => this != WordWrap.off;
}

enum LineNumbersStyle { off, on, relative, interval }

enum MinimapSide { left, right }

enum RenderWhitespace { none, boundary, selection, trailing, all }

enum CursorBlinking { blink, smooth, phase, expand, solid }

enum CursorStyle {
  line,
  block,
  underline,
  lineThin,
  blockOutline,
  underlineThin
}

enum MultiCursorModifier { ctrlCmd, alt }

enum AcceptSuggestionOnEnter { on, off, smart }

enum SnippetSuggestions { top, bottom, inline, none }

enum WordBasedSuggestions {
  off,
  currentDocument,
  matchingDocuments,
  allDocuments
}

enum AccessibilitySupport { auto, off, on }

enum KeybindingPresetEnum { vscode, intellij, vim, emacs, custom }

/// Language-specific configuration
class LanguageConfig {
  const LanguageConfig({
    this.tabSize,
    this.insertSpaces,
    this.wordWrap,
    this.rulers,
    this.formatOnSave,
    this.formatOnPaste,
    this.formatOnType,
    this.autoClosingBrackets,
    this.autoClosingQuotes,
    this.bracketPairColorization,
    this.customTheme,
  });

  factory LanguageConfig.fromJson(Map<String, dynamic> json) => LanguageConfig(
        tabSize: json.tryGetInt('tabSize'),
        insertSpaces: json.tryGetBool('insertSpaces'),
        wordWrap: json.tryGetString('wordWrap')?.let((w) => WordWrap.values
            .firstWhere((e) => e.name == w, orElse: () => WordWrap.off)),
        rulers: json.tryGetList<int>('rulers'),
        formatOnSave: json.tryGetBool('formatOnSave'),
        formatOnPaste: json.tryGetBool('formatOnPaste'),
        formatOnType: json.tryGetBool('formatOnType'),
        autoClosingBrackets: json.tryGetString('autoClosingBrackets'),
        autoClosingQuotes: json.tryGetString('autoClosingQuotes'),
        bracketPairColorization: json.tryGetBool('bracketPairColorization'),
        customTheme: json.tryGetMap('customTheme'),
      );

  final int? tabSize;
  final bool? insertSpaces;
  final WordWrap? wordWrap;
  final List<int>? rulers;
  final bool? formatOnSave;
  final bool? formatOnPaste;
  final bool? formatOnType;
  final String?
      autoClosingBrackets; // 'always', 'languageDefined', 'beforeWhitespace', 'never'
  final String?
      autoClosingQuotes; // 'always', 'languageDefined', 'beforeWhitespace', 'never'
  final bool? bracketPairColorization;
  final Map<String, dynamic>? customTheme;

  Map<String, dynamic> toJson() => {
        if (tabSize != null) 'tabSize': tabSize,
        if (insertSpaces != null) 'insertSpaces': insertSpaces,
        if (wordWrap != null) 'wordWrap': wordWrap!.name,
        if (rulers != null) 'rulers': rulers,
        if (formatOnSave != null) 'formatOnSave': formatOnSave,
        if (formatOnPaste != null) 'formatOnPaste': formatOnPaste,
        if (formatOnType != null) 'formatOnType': formatOnType,
        if (autoClosingBrackets != null)
          'autoClosingBrackets': autoClosingBrackets,
        if (autoClosingQuotes != null) 'autoClosingQuotes': autoClosingQuotes,
        if (bracketPairColorization != null)
          'bracketPairColorization': bracketPairColorization,
        if (customTheme != null) 'customTheme': customTheme,
      };

  LanguageConfig copyWith({
    int? tabSize,
    bool? insertSpaces,
    WordWrap? wordWrap,
    List<int>? rulers,
    bool? formatOnSave,
    bool? formatOnPaste,
    bool? formatOnType,
    String? autoClosingBrackets,
    String? autoClosingQuotes,
    bool? bracketPairColorization,
    Map<String, dynamic>? customTheme,
  }) =>
      LanguageConfig(
        tabSize: tabSize ?? this.tabSize,
        insertSpaces: insertSpaces ?? this.insertSpaces,
        wordWrap: wordWrap ?? this.wordWrap,
        rulers: rulers ?? this.rulers,
        formatOnSave: formatOnSave ?? this.formatOnSave,
        formatOnPaste: formatOnPaste ?? this.formatOnPaste,
        formatOnType: formatOnType ?? this.formatOnType,
        autoClosingBrackets: autoClosingBrackets ?? this.autoClosingBrackets,
        autoClosingQuotes: autoClosingQuotes ?? this.autoClosingQuotes,
        bracketPairColorization:
            bracketPairColorization ?? this.bracketPairColorization,
        customTheme: customTheme ?? this.customTheme,
      );
}

/// Enhanced Editor configuration settings with comprehensive options
@immutable
class EditorSettings {
  const EditorSettings({
    // General Settings
    this.theme = defaultTheme,
    this.fontSize = defaultFontSize,
    this.fontFamily = defaultFontFamily,
    this.lineHeight = defaultLineHeight,
    this.letterSpacing = defaultLetterSpacing,

    // Display Settings
    this.showLineNumbers = defaultShowLineNumbers,
    this.lineNumbersStyle = defaultLineNumbersStyle,
    this.showMinimap = defaultShowMinimap,
    this.minimapSide = defaultMinimapSide,
    this.minimapRenderCharacters = defaultMinimapRenderCharacters,
    this.minimapSize = defaultMinimapSize,
    this.showIndentGuides = defaultShowIndentGuides,
    this.renderWhitespace = defaultRenderWhitespace,
    this.rulers = defaultRulers,
    this.stickyScroll = defaultStickyScroll,
    this.showFoldingControls = defaultShowFoldingControls,
    this.glyphMargin = defaultGlyphMargin,
    this.renderLineHighlight = defaultRenderLineHighlight,

    // Editor Behavior
    this.wordWrap = defaultWordWrap,
    this.wordWrapColumn = defaultWordWrapColumn,
    this.tabSize = defaultTabSize,
    this.insertSpaces = defaultInsertSpaces,
    this.autoIndent = defaultAutoIndent,
    this.autoClosingBrackets = defaultAutoClosingBrackets,
    this.autoClosingQuotes = defaultAutoClosingQuotes,
    this.autoSurround = defaultAutoSurround,
    this.bracketPairColorization = defaultBracketPairColorization,
    this.codeFolding = defaultCodeFolding,
    this.scrollBeyondLastLine = defaultScrollBeyondLastLine,
    this.smoothScrolling = defaultSmoothScrolling,
    this.fastScrollSensitivity = defaultFastScrollSensitivity,
    this.scrollPredominantAxis = defaultScrollPredominantAxis,

    // Cursor Settings
    this.cursorBlinking = defaultCursorBlinking,
    this.cursorSmoothCaretAnimation = defaultCursorSmoothCaretAnimation,
    this.cursorStyle = defaultCursorStyle,
    this.cursorWidth = defaultCursorWidth,
    this.multiCursorModifier = defaultMultiCursorModifier,
    this.multiCursorMergeOverlapping = defaultMultiCursorMergeOverlapping,

    // Editing Features
    this.formatOnSave = defaultFormatOnSave,
    this.formatOnPaste = defaultFormatOnPaste,
    this.formatOnType = defaultFormatOnType,
    this.quickSuggestions = defaultQuickSuggestions,
    this.quickSuggestionsDelay = defaultQuickSuggestionsDelay,
    this.suggestOnTriggerCharacters = defaultSuggestOnTriggerCharacters,
    this.acceptSuggestionOnEnter = defaultAcceptSuggestionOnEnter,
    this.acceptSuggestionOnCommitCharacter =
        defaultAcceptSuggestionOnCommitCharacter,
    this.snippetSuggestions = defaultSnippetSuggestions,
    this.wordBasedSuggestions = defaultWordBasedSuggestions,
    this.parameterHints = defaultParameterHints,
    this.hover = defaultHover,
    this.contextMenu = defaultContextMenu,

    // Find & Replace
    this.find = defaultFind,
    this.seedSearchStringFromSelection = defaultSeedSearchStringFromSelection,

    // Accessibility
    this.accessibilitySupport = defaultAccessibilitySupport,
    this.accessibilityPageSize = defaultAccessibilityPageSize,

    // Performance
    this.renderValidationDecorations = defaultRenderValidationDecorations,
    this.renderControlCharacters = defaultRenderControlCharacters,
    this.disableLayerHinting = defaultDisableLayerHinting,
    this.disableMonospaceOptimizations = defaultDisableMonospaceOptimizations,
    this.maxTokenizationLineLength = defaultMaxTokenizationLineLength,

    // Language Specific
    this.languageConfigs = const {},

    // Keybindings
    this.keybindingPreset = defaultKeybindingPreset,
    this.customKeybindings = const {},

    // Advanced
    this.readOnly = defaultReadOnly,
    this.domReadOnly = defaultDomReadOnly,
    this.dragAndDrop = defaultDragAndDrop,
    this.links = defaultLinks,
    this.mouseWheelZoom = defaultMouseWheelZoom,
    this.mouseWheelScrollSensitivity = defaultMouseWheelScrollSensitivity,
    this.automaticLayout = defaultAutomaticLayout,
    this.padding = defaultPadding,
    this.roundedSelection = defaultRoundedSelection,
    this.selectionHighlight = defaultSelectionHighlight,
    this.occurrencesHighlight = defaultOccurrencesHighlight,
    this.overviewRulerBorder = defaultOverviewRulerBorder,
    this.hideCursorInOverviewRuler = defaultHideCursorInOverviewRuler,
    this.scrollbar = defaultScrollbar,
    this.experimentalFeatures = const {},
  });

  factory EditorSettings.fromJson(Map<String, dynamic> json) {
    T? parseEnum<T extends Enum>(String? value, List<T> values) {
      if (value == null) return null;
      try {
        return values.firstWhere((e) => e.name == value);
      } catch (e) {
        return null; // Or throw an error, or return a default
      }
    }

    final Map<String, LanguageConfig> parsedLanguageConfigs = {};
    final langConfigsDynamic = json[keyLanguageConfigs];
    if (langConfigsDynamic != null) {
      try {
        // If it's a string, decode it first (like from SharedPreferences)
        // If it's already a map (like from direct JSON parsing), use it
        Map<String, dynamic> langConfigsJson = {};
        if (langConfigsDynamic is String) {
          langConfigsJson =
              langConfigsDynamic.decode() as Map<String, dynamic>? ?? {};
        } else if (langConfigsDynamic is Map) {
          langConfigsJson = Map<String, dynamic>.from(langConfigsDynamic);
        }

        for (final entry in langConfigsJson.entries) {
          if (entry.value is Map<String, dynamic>) {
            parsedLanguageConfigs[entry.key] =
                LanguageConfig.fromJson(entry.value as Map<String, dynamic>);
          }
        }
      } catch (e) {
        // Log error or handle as needed
        if (kDebugMode) {
          print('Error parsing language configs from JSON: $e');
        }
      }
    }

    return EditorSettings(
      theme: json.tryGetString(keyTheme) ?? defaultTheme,
      fontSize: json.tryGetDouble(keyFontSize) ?? defaultFontSize,
      fontFamily: json.tryGetString(keyFontFamily) ?? defaultFontFamily,
      lineHeight: json.tryGetDouble(keyLineHeight) ?? defaultLineHeight,
      letterSpacing:
          json.tryGetDouble(keyLetterSpacing) ?? defaultLetterSpacing,
      showLineNumbers:
          json.tryGetBool(keyShowLineNumbers) ?? defaultShowLineNumbers,
      lineNumbersStyle: parseEnum(json.tryGetString(keyLineNumbersStyle),
              LineNumbersStyle.values) ??
          defaultLineNumbersStyle,
      showMinimap: json.tryGetBool(keyShowMinimap) ?? defaultShowMinimap,
      minimapSide:
          parseEnum(json.tryGetString(keyMinimapSide), MinimapSide.values) ??
              defaultMinimapSide,
      minimapRenderCharacters: json.tryGetBool(keyMinimapRenderCharacters) ??
          defaultMinimapRenderCharacters,
      minimapSize: json.tryGetInt(keyMinimapSize) ?? defaultMinimapSize,
      showIndentGuides:
          json.tryGetBool(keyShowIndentGuides) ?? defaultShowIndentGuides,
      renderWhitespace: parseEnum(json.tryGetString(keyRenderWhitespace),
              RenderWhitespace.values) ??
          defaultRenderWhitespace,
      rulers: json
              .tryGetList<String>(keyRulers)
              ?.map((s) => int.tryParse(s) ?? 0)
              .where((i) => i > 0)
              .toList() ??
          defaultRulers,
      stickyScroll: json.tryGetBool(keyStickyScroll) ?? defaultStickyScroll,
      showFoldingControls: json.tryGetString(keyShowFoldingControls) ??
          defaultShowFoldingControls,
      glyphMargin: json.tryGetBool(keyGlyphMargin) ?? defaultGlyphMargin,
      renderLineHighlight: json.tryGetString(keyRenderLineHighlight) ??
          defaultRenderLineHighlight,
      wordWrap: parseEnum(json.tryGetString(keyWordWrap), WordWrap.values) ??
          defaultWordWrap,
      wordWrapColumn:
          json.tryGetInt(keyWordWrapColumn) ?? defaultWordWrapColumn,
      tabSize: json.tryGetInt(keyTabSize) ?? defaultTabSize,
      insertSpaces: json.tryGetBool(keyInsertSpaces) ?? defaultInsertSpaces,
      autoIndent: json.tryGetString(keyAutoIndent) ?? defaultAutoIndent,
      autoClosingBrackets: json.tryGetString(keyAutoClosingBrackets) ??
          defaultAutoClosingBrackets,
      autoClosingQuotes:
          json.tryGetString(keyAutoClosingQuotes) ?? defaultAutoClosingQuotes,
      autoSurround: json.tryGetString(keyAutoSurround) ?? defaultAutoSurround,
      bracketPairColorization: json.tryGetBool(keyBracketPairColorization) ??
          defaultBracketPairColorization,
      codeFolding: json.tryGetBool(keyCodeFolding) ?? defaultCodeFolding,
      scrollBeyondLastLine: json.tryGetBool(keyScrollBeyondLastLine) ??
          defaultScrollBeyondLastLine,
      smoothScrolling:
          json.tryGetBool(keySmoothScrolling) ?? defaultSmoothScrolling,
      fastScrollSensitivity: json.tryGetDouble(keyFastScrollSensitivity) ??
          defaultFastScrollSensitivity,
      scrollPredominantAxis: json.tryGetBool(keyScrollPredominantAxis) ??
          defaultScrollPredominantAxis,
      cursorBlinking: parseEnum(
              json.tryGetString(keyCursorBlinking), CursorBlinking.values) ??
          defaultCursorBlinking,
      cursorSmoothCaretAnimation:
          json.tryGetString(keyCursorSmoothCaretAnimation) ??
              defaultCursorSmoothCaretAnimation,
      cursorStyle:
          parseEnum(json.tryGetString(keyCursorStyle), CursorStyle.values) ??
              defaultCursorStyle,
      cursorWidth: json.tryGetInt(keyCursorWidth) ?? defaultCursorWidth,
      multiCursorModifier: parseEnum(json.tryGetString(keyMultiCursorModifier),
              MultiCursorModifier.values) ??
          defaultMultiCursorModifier,
      multiCursorMergeOverlapping:
          json.tryGetBool(keyMultiCursorMergeOverlapping) ??
              defaultMultiCursorMergeOverlapping,
      formatOnSave: json.tryGetBool(keyFormatOnSave) ?? defaultFormatOnSave,
      formatOnPaste: json.tryGetBool(keyFormatOnPaste) ?? defaultFormatOnPaste,
      formatOnType: json.tryGetBool(keyFormatOnType) ?? defaultFormatOnType,
      quickSuggestions:
          json.tryGetBool(keyQuickSuggestions) ?? defaultQuickSuggestions,
      quickSuggestionsDelay: json.tryGetInt(keyQuickSuggestionsDelay) ??
          defaultQuickSuggestionsDelay,
      suggestOnTriggerCharacters:
          json.tryGetBool(keySuggestOnTriggerCharacters) ??
              defaultSuggestOnTriggerCharacters,
      acceptSuggestionOnEnter: parseEnum(
              json.tryGetString(keyAcceptSuggestionOnEnter),
              AcceptSuggestionOnEnter.values) ??
          defaultAcceptSuggestionOnEnter,
      acceptSuggestionOnCommitCharacter:
          json.tryGetBool(keyAcceptSuggestionOnCommitCharacter) ??
              defaultAcceptSuggestionOnCommitCharacter,
      snippetSuggestions: parseEnum(json.tryGetString(keySnippetSuggestions),
              SnippetSuggestions.values) ??
          defaultSnippetSuggestions,
      wordBasedSuggestions: parseEnum(
              json.tryGetString(keyWordBasedSuggestions),
              WordBasedSuggestions.values) ??
          defaultWordBasedSuggestions,
      parameterHints:
          json.tryGetBool(keyParameterHints) ?? defaultParameterHints,
      hover: json.tryGetBool(keyHover) ?? defaultHover,
      contextMenu: json.tryGetBool(keyContextMenu) ?? defaultContextMenu,
      find: json.tryGetBool(keyFind) ?? defaultFind,
      seedSearchStringFromSelection:
          json.tryGetString(keySeedSearchStringFromSelection) ??
              defaultSeedSearchStringFromSelection,
      accessibilitySupport: parseEnum(
              json.tryGetString(keyAccessibilitySupport),
              AccessibilitySupport.values) ??
          defaultAccessibilitySupport,
      accessibilityPageSize: json.tryGetInt(keyAccessibilityPageSize) ??
          defaultAccessibilityPageSize,
      renderValidationDecorations:
          json.tryGetString(keyRenderValidationDecorations) ??
              defaultRenderValidationDecorations,
      renderControlCharacters: json.tryGetBool(keyRenderControlCharacters) ??
          defaultRenderControlCharacters,
      disableLayerHinting:
          json.tryGetBool(keyDisableLayerHinting) ?? defaultDisableLayerHinting,
      disableMonospaceOptimizations:
          json.tryGetBool(keyDisableMonospaceOptimizations) ??
              defaultDisableMonospaceOptimizations,
      maxTokenizationLineLength: json.tryGetInt(keyMaxTokenizationLineLength) ??
          defaultMaxTokenizationLineLength,
      languageConfigs: parsedLanguageConfigs,
      keybindingPreset: parseEnum(json.tryGetString(keyKeybindingPreset),
              KeybindingPresetEnum.values) ??
          defaultKeybindingPreset,
      customKeybindings: (json[keyCustomKeybindings] is String
              ? (json.tryGetString(keyCustomKeybindings)?.decode()
                      as Map<String, dynamic>?)
                  ?.map((key, value) => MapEntry(key, value.toString()))
              : Map<String, String>.from(
                  json[keyCustomKeybindings] as Map? ?? {})) ??
          {},
      readOnly: json.tryGetBool(keyReadOnly) ?? defaultReadOnly,
      domReadOnly: json.tryGetBool(keyDomReadOnly) ?? defaultDomReadOnly,
      dragAndDrop: json.tryGetBool(keyDragAndDrop) ?? defaultDragAndDrop,
      links: json.tryGetBool(keyLinks) ?? defaultLinks,
      mouseWheelZoom:
          json.tryGetBool(keyMouseWheelZoom) ?? defaultMouseWheelZoom,
      mouseWheelScrollSensitivity:
          json.tryGetDouble(keyMouseWheelScrollSensitivity) ??
              defaultMouseWheelScrollSensitivity,
      automaticLayout:
          json.tryGetBool(keyAutomaticLayout) ?? defaultAutomaticLayout,
      padding: (json[keyPadding] is String
              ? (json.tryGetString(keyPadding)?.decode()
                      as Map<String, dynamic>?)
                  ?.cast<String, int>()
              : Map<String, int>.from(json[keyPadding] as Map? ?? {})) ??
          defaultPadding,
      roundedSelection:
          json.tryGetBool(keyRoundedSelection) ?? defaultRoundedSelection,
      selectionHighlight:
          json.tryGetBool(keySelectionHighlight) ?? defaultSelectionHighlight,
      occurrencesHighlight: json.tryGetString(keyOccurrencesHighlight) ??
          defaultOccurrencesHighlight,
      overviewRulerBorder:
          json.tryGetBool(keyOverviewRulerBorder) ?? defaultOverviewRulerBorder,
      hideCursorInOverviewRuler:
          json.tryGetBool(keyHideCursorInOverviewRuler) ??
              defaultHideCursorInOverviewRuler,
      scrollbar: (json[keyScrollbar] is String
              ? json.tryGetString(keyScrollbar)?.decode()
                  as Map<String, dynamic>?
              : Map<String, dynamic>.from(json[keyScrollbar] as Map? ?? {})) ??
          defaultScrollbar,
      experimentalFeatures: (json[keyExperimentalFeatures] is String
              ? json.tryGetString(keyExperimentalFeatures)?.decode()
                  as Map<String, dynamic>?
              : Map<String, dynamic>.from(
                  json[keyExperimentalFeatures] as Map? ?? {})) ??
          {},
    );
  }

  /// Create preset configurations
  factory EditorSettings.createPreset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'beginner':
        return const EditorSettings(
          showLineNumbers: true,
          showMinimap: false,
          fontSize: 16,
          wordWrap: WordWrap.on,
          formatOnSave: true,
          formatOnPaste: true,
          autoClosingBrackets: 'always',
          autoClosingQuotes: 'always',
          quickSuggestions: true,
          parameterHints: true,
          hover: true,
        );

      case 'developer':
        return const EditorSettings(
          showLineNumbers: true,
          showMinimap: true,
          fontSize: 14,
          wordWrap: WordWrap.off,
          rulers: [80, 120],
          formatOnSave: true,
          bracketPairColorization: true,
          codeFolding: true,
          quickSuggestions: true,
          parameterHints: true,
          hover: true,
          renderWhitespace: RenderWhitespace.boundary,
        );

      case 'poweruser':
        return const EditorSettings(
          showLineNumbers: true,
          lineNumbersStyle: LineNumbersStyle.relative,
          showMinimap: true,
          minimapRenderCharacters: false,
          fontSize: 13,
          wordWrap: WordWrap.off,
          rulers: [80, 100, 120],
          formatOnSave: true,
          formatOnType: true,
          bracketPairColorization: true,
          codeFolding: true,
          stickyScroll: true,
          quickSuggestions: true,
          parameterHints: true,
          hover: true,
          renderWhitespace: RenderWhitespace.all,
          cursorBlinking: CursorBlinking.smooth,
          multiCursorModifier: MultiCursorModifier.alt,
        );

      case 'accessibility':
        return const EditorSettings(
          fontSize: 18,
          lineHeight: 1.6,
          showLineNumbers: true,
          showMinimap: false,
          wordWrap: WordWrap.on,
          accessibilitySupport: AccessibilitySupport.on,
          renderWhitespace: RenderWhitespace.all,
          renderControlCharacters: true,
          cursorBlinking: CursorBlinking.solid,
          cursorStyle: CursorStyle.block,
          cursorWidth: 3,
        );

      default:
        return const EditorSettings();
    }
  }

  // === CONSTANTS & DEFAULTS ===

  // General
  static const String defaultTheme = 'vs-dark';
  static const double defaultFontSize = 14;
  static const String defaultFontFamily =
      'JetBrains Mono, SF Mono, Menlo, Consolas, "Courier New", monospace';
  static const double defaultLineHeight = 1.4;
  static const double defaultLetterSpacing = 0;

  // Display
  static const bool defaultShowLineNumbers = true;
  static const LineNumbersStyle defaultLineNumbersStyle = LineNumbersStyle.on;
  static const bool defaultShowMinimap = false;
  static const MinimapSide defaultMinimapSide = MinimapSide.right;
  static const bool defaultMinimapRenderCharacters = false;
  static const int defaultMinimapSize = 1;
  static const bool defaultShowIndentGuides = true;
  static const RenderWhitespace defaultRenderWhitespace =
      RenderWhitespace.selection;
  static const List<int> defaultRulers = [];
  static const bool defaultStickyScroll = false;
  static const String defaultShowFoldingControls = 'mouseover';
  static const bool defaultGlyphMargin = true;
  static const String defaultRenderLineHighlight = 'line';

  // Editor Behavior
  static const WordWrap defaultWordWrap = WordWrap.on;
  static const int defaultWordWrapColumn = 80;
  static const int defaultTabSize = 4;
  static const bool defaultInsertSpaces = true;
  static const String defaultAutoIndent = 'advanced';
  static const String defaultAutoClosingBrackets = 'languageDefined';
  static const String defaultAutoClosingQuotes = 'languageDefined';
  static const String defaultAutoSurround = 'languageDefined';
  static const bool defaultBracketPairColorization = true;
  static const bool defaultCodeFolding = true;
  static const bool defaultScrollBeyondLastLine = true;
  static const bool defaultSmoothScrolling = false;
  static const double defaultFastScrollSensitivity = 5;
  static const bool defaultScrollPredominantAxis = true;

  // Cursor
  static const CursorBlinking defaultCursorBlinking = CursorBlinking.blink;
  static const String defaultCursorSmoothCaretAnimation = 'off';
  static const CursorStyle defaultCursorStyle = CursorStyle.line;
  static const int defaultCursorWidth = 0;
  static const MultiCursorModifier defaultMultiCursorModifier =
      MultiCursorModifier.ctrlCmd;
  static const bool defaultMultiCursorMergeOverlapping = true;

  // Editing Features
  static const bool defaultFormatOnSave = false;
  static const bool defaultFormatOnPaste = false;
  static const bool defaultFormatOnType = false;
  static const bool defaultQuickSuggestions = true;
  static const int defaultQuickSuggestionsDelay = 10;
  static const bool defaultSuggestOnTriggerCharacters = true;
  static const AcceptSuggestionOnEnter defaultAcceptSuggestionOnEnter =
      AcceptSuggestionOnEnter.on;
  static const bool defaultAcceptSuggestionOnCommitCharacter = true;
  static const SnippetSuggestions defaultSnippetSuggestions =
      SnippetSuggestions.inline;
  static const WordBasedSuggestions defaultWordBasedSuggestions =
      WordBasedSuggestions.currentDocument;
  static const bool defaultParameterHints = true;
  static const bool defaultHover = true;
  static const bool defaultContextMenu = true;

  // Find & Replace
  static const bool defaultFind = true;
  static const String defaultSeedSearchStringFromSelection = 'selection';

  // Accessibility
  static const AccessibilitySupport defaultAccessibilitySupport =
      AccessibilitySupport.auto;
  static const int defaultAccessibilityPageSize = 10;

  // Performance
  static const String defaultRenderValidationDecorations = 'editable';
  static const bool defaultRenderControlCharacters = false;
  static const bool defaultDisableLayerHinting = false;
  static const bool defaultDisableMonospaceOptimizations = false;
  static const int defaultMaxTokenizationLineLength = 20000;

  // Keybindings
  static const KeybindingPresetEnum defaultKeybindingPreset =
      KeybindingPresetEnum.vscode;

  // Advanced
  static const bool defaultReadOnly = false;
  static const bool defaultDomReadOnly = false;
  static const bool defaultDragAndDrop = true;
  static const bool defaultLinks = true;
  static const bool defaultMouseWheelZoom = false;
  static const double defaultMouseWheelScrollSensitivity = 1;
  static const bool defaultAutomaticLayout = true;
  static const Map<String, int> defaultPadding = {
    'top': 10,
    'bottom': 10,
    'start': 10,
    'end': 10
  };
  static const bool defaultRoundedSelection = true;
  static const bool defaultSelectionHighlight = true;
  static const String defaultOccurrencesHighlight = 'singleFile';
  static const bool defaultOverviewRulerBorder = true;
  static const bool defaultHideCursorInOverviewRuler = false;
  static const Map<String, dynamic> defaultScrollbar = {
    'vertical': 'auto',
    'horizontal': 'auto',
    'arrowSize': 11,
    'useShadows': true,
    'verticalScrollbarSize': 14,
    'horizontalScrollbarSize': 10,
    'scrollByPage': false,
  };

  // === STORAGE KEYS ===
  static const String keyTheme = 'editor_theme';
  static const String keyFontSize = 'editor_font_size';
  static const String keyFontFamily = 'editor_font_family';
  static const String keyLineHeight = 'editor_line_height';
  static const String keyLetterSpacing = 'editor_letter_spacing';
  static const String keyShowLineNumbers = 'editor_show_line_numbers';
  static const String keyLineNumbersStyle = 'editor_line_numbers_style';
  static const String keyShowMinimap = 'editor_show_minimap';
  static const String keyMinimapSide = 'editor_minimap_side';
  static const String keyMinimapRenderCharacters =
      'editor_minimap_render_characters';
  static const String keyMinimapSize = 'editor_minimap_size';
  static const String keyShowIndentGuides = 'editor_show_indent_guides';
  static const String keyRenderWhitespace = 'editor_render_whitespace';
  static const String keyRulers = 'editor_rulers';
  static const String keyStickyScroll = 'editor_sticky_scroll';
  static const String keyShowFoldingControls = 'editor_show_folding_controls';
  static const String keyGlyphMargin = 'editor_glyph_margin';
  static const String keyRenderLineHighlight = 'editor_render_line_highlight';
  static const String keyWordWrap = 'editor_word_wrap';
  static const String keyWordWrapColumn = 'editor_word_wrap_column';
  static const String keyTabSize = 'editor_tab_size';
  static const String keyInsertSpaces = 'editor_insert_spaces';
  static const String keyAutoIndent = 'editor_auto_indent';
  static const String keyAutoClosingBrackets = 'editor_auto_closing_brackets';
  static const String keyAutoClosingQuotes = 'editor_auto_closing_quotes';
  static const String keyAutoSurround = 'editor_auto_surround';
  static const String keyBracketPairColorization =
      'editor_bracket_pair_colorization';
  static const String keyCodeFolding = 'editor_code_folding';
  static const String keyScrollBeyondLastLine =
      'editor_scroll_beyond_last_line';
  static const String keySmoothScrolling = 'editor_smooth_scrolling';
  static const String keyFastScrollSensitivity =
      'editor_fast_scroll_sensitivity';
  static const String keyScrollPredominantAxis =
      'editor_scroll_predominant_axis';
  static const String keyCursorBlinking = 'editor_cursor_blinking';
  static const String keyCursorSmoothCaretAnimation =
      'editor_cursor_smooth_caret_animation';
  static const String keyCursorStyle = 'editor_cursor_style';
  static const String keyCursorWidth = 'editor_cursor_width';
  static const String keyMultiCursorModifier = 'editor_multi_cursor_modifier';
  static const String keyMultiCursorMergeOverlapping =
      'editor_multi_cursor_merge_overlapping';
  static const String keyFormatOnSave = 'editor_format_on_save';
  static const String keyFormatOnPaste = 'editor_format_on_paste';
  static const String keyFormatOnType = 'editor_format_on_type';
  static const String keyQuickSuggestions = 'editor_quick_suggestions';
  static const String keyQuickSuggestionsDelay =
      'editor_quick_suggestions_delay';
  static const String keySuggestOnTriggerCharacters =
      'editor_suggest_on_trigger_characters';
  static const String keyAcceptSuggestionOnEnter =
      'editor_accept_suggestion_on_enter';
  static const String keyAcceptSuggestionOnCommitCharacter =
      'editor_accept_suggestion_on_commit_character';
  static const String keySnippetSuggestions = 'editor_snippet_suggestions';
  static const String keyWordBasedSuggestions = 'editor_word_based_suggestions';
  static const String keyParameterHints = 'editor_parameter_hints';
  static const String keyHover = 'editor_hover';
  static const String keyContextMenu = 'editor_context_menu';
  static const String keyFind = 'editor_find';
  static const String keySeedSearchStringFromSelection =
      'editor_seed_search_string_from_selection';
  static const String keyAccessibilitySupport = 'editor_accessibility_support';
  static const String keyAccessibilityPageSize =
      'editor_accessibility_page_size';
  static const String keyRenderValidationDecorations =
      'editor_render_validation_decorations';
  static const String keyRenderControlCharacters =
      'editor_render_control_characters';
  static const String keyDisableLayerHinting = 'editor_disable_layer_hinting';
  static const String keyDisableMonospaceOptimizations =
      'editor_disable_monospace_optimizations';
  static const String keyMaxTokenizationLineLength =
      'editor_max_tokenization_line_length';
  static const String keyLanguageConfigs = 'editor_language_configs';
  static const String keyKeybindingPreset = 'editor_keybinding_preset';
  static const String keyCustomKeybindings = 'editor_custom_keybindings';
  static const String keyReadOnly = 'editor_read_only';
  static const String keyDomReadOnly = 'editor_dom_read_only';
  static const String keyDragAndDrop = 'editor_drag_and_drop';
  static const String keyLinks = 'editor_links';
  static const String keyMouseWheelZoom = 'editor_mouse_wheel_zoom';
  static const String keyMouseWheelScrollSensitivity =
      'editor_mouse_wheel_scroll_sensitivity';
  static const String keyAutomaticLayout = 'editor_automatic_layout';
  static const String keyPadding = 'editor_padding';
  static const String keyRoundedSelection = 'editor_rounded_selection';
  static const String keySelectionHighlight = 'editor_selection_highlight';
  static const String keyOccurrencesHighlight = 'editor_occurrences_highlight';
  static const String keyOverviewRulerBorder = 'editor_overview_ruler_border';
  static const String keyHideCursorInOverviewRuler =
      'editor_hide_cursor_in_overview_ruler';
  static const String keyScrollbar = 'editor_scrollbar';
  static const String keyExperimentalFeatures = 'editor_experimental_features';

  // === PROPERTIES ===

  // General Settings
  final String theme;
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final double letterSpacing;

  // Display Settings
  final bool showLineNumbers;
  final LineNumbersStyle lineNumbersStyle;
  final bool showMinimap;
  final MinimapSide minimapSide;
  final bool minimapRenderCharacters;
  final int minimapSize;
  final bool showIndentGuides;
  final RenderWhitespace renderWhitespace;
  final List<int> rulers;
  final bool stickyScroll;
  final String showFoldingControls;
  final bool glyphMargin;
  final String renderLineHighlight;

  // Editor Behavior
  final WordWrap wordWrap;
  final int wordWrapColumn;
  final int tabSize;
  final bool insertSpaces;
  final String autoIndent;
  final String autoClosingBrackets;
  final String autoClosingQuotes;
  final String autoSurround;
  final bool bracketPairColorization;
  final bool codeFolding;
  final bool scrollBeyondLastLine;
  final bool smoothScrolling;
  final double fastScrollSensitivity;
  final bool scrollPredominantAxis;

  // Cursor Settings
  final CursorBlinking cursorBlinking;
  final String cursorSmoothCaretAnimation;
  final CursorStyle cursorStyle;
  final int cursorWidth;
  final MultiCursorModifier multiCursorModifier;
  final bool multiCursorMergeOverlapping;

  // Editing Features
  final bool formatOnSave;
  final bool formatOnPaste;
  final bool formatOnType;
  final bool quickSuggestions;
  final int quickSuggestionsDelay;
  final bool suggestOnTriggerCharacters;
  final AcceptSuggestionOnEnter acceptSuggestionOnEnter;
  final bool acceptSuggestionOnCommitCharacter;
  final SnippetSuggestions snippetSuggestions;
  final WordBasedSuggestions wordBasedSuggestions;
  final bool parameterHints;
  final bool hover;
  final bool contextMenu;

  // Find & Replace
  final bool find;
  final String seedSearchStringFromSelection;

  // Accessibility
  final AccessibilitySupport accessibilitySupport;
  final int accessibilityPageSize;

  // Performance
  final String renderValidationDecorations;
  final bool renderControlCharacters;
  final bool disableLayerHinting;
  final bool disableMonospaceOptimizations;
  final int maxTokenizationLineLength;

  // Language Specific
  final Map<String, LanguageConfig> languageConfigs;

  // Keybindings
  final KeybindingPresetEnum keybindingPreset;
  final Map<String, String> customKeybindings;

  // Advanced
  final bool readOnly;
  final bool domReadOnly;
  final bool dragAndDrop;
  final bool links;
  final bool mouseWheelZoom;
  final double mouseWheelScrollSensitivity;
  final bool automaticLayout;
  final Map<String, int> padding;
  final bool roundedSelection;
  final bool selectionHighlight;
  final String occurrencesHighlight;
  final bool overviewRulerBorder;
  final bool hideCursorInOverviewRuler;
  final Map<String, dynamic> scrollbar;
  final Map<String, dynamic> experimentalFeatures;

  // === METHODS ===

  EditorSettings copyWith({
    String? theme,
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? letterSpacing,
    bool? showLineNumbers,
    LineNumbersStyle? lineNumbersStyle,
    bool? showMinimap,
    MinimapSide? minimapSide,
    bool? minimapRenderCharacters,
    int? minimapSize,
    bool? showIndentGuides,
    RenderWhitespace? renderWhitespace,
    List<int>? rulers,
    bool? stickyScroll,
    String? showFoldingControls,
    bool? glyphMargin,
    String? renderLineHighlight,
    WordWrap? wordWrap,
    int? wordWrapColumn,
    int? tabSize,
    bool? insertSpaces,
    String? autoIndent,
    String? autoClosingBrackets,
    String? autoClosingQuotes,
    String? autoSurround,
    bool? bracketPairColorization,
    bool? codeFolding,
    bool? scrollBeyondLastLine,
    bool? smoothScrolling,
    double? fastScrollSensitivity,
    bool? scrollPredominantAxis,
    CursorBlinking? cursorBlinking,
    String? cursorSmoothCaretAnimation,
    CursorStyle? cursorStyle,
    int? cursorWidth,
    MultiCursorModifier? multiCursorModifier,
    bool? multiCursorMergeOverlapping,
    bool? formatOnSave,
    bool? formatOnPaste,
    bool? formatOnType,
    bool? quickSuggestions,
    int? quickSuggestionsDelay,
    bool? suggestOnTriggerCharacters,
    AcceptSuggestionOnEnter? acceptSuggestionOnEnter,
    bool? acceptSuggestionOnCommitCharacter,
    SnippetSuggestions? snippetSuggestions,
    WordBasedSuggestions? wordBasedSuggestions,
    bool? parameterHints,
    bool? hover,
    bool? contextMenu,
    bool? find,
    String? seedSearchStringFromSelection,
    AccessibilitySupport? accessibilitySupport,
    int? accessibilityPageSize,
    String? renderValidationDecorations,
    bool? renderControlCharacters,
    bool? disableLayerHinting,
    bool? disableMonospaceOptimizations,
    int? maxTokenizationLineLength,
    Map<String, LanguageConfig>? languageConfigs,
    KeybindingPresetEnum? keybindingPreset,
    Map<String, String>? customKeybindings,
    bool? readOnly,
    bool? domReadOnly,
    bool? dragAndDrop,
    bool? links,
    bool? mouseWheelZoom,
    double? mouseWheelScrollSensitivity,
    bool? automaticLayout,
    Map<String, int>? padding,
    bool? roundedSelection,
    bool? selectionHighlight,
    String? occurrencesHighlight,
    bool? overviewRulerBorder,
    bool? hideCursorInOverviewRuler,
    Map<String, dynamic>? scrollbar,
    Map<String, dynamic>? experimentalFeatures,
  }) {
    return EditorSettings(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      lineNumbersStyle: lineNumbersStyle ?? this.lineNumbersStyle,
      showMinimap: showMinimap ?? this.showMinimap,
      minimapSide: minimapSide ?? this.minimapSide,
      minimapRenderCharacters:
          minimapRenderCharacters ?? this.minimapRenderCharacters,
      minimapSize: minimapSize ?? this.minimapSize,
      showIndentGuides: showIndentGuides ?? this.showIndentGuides,
      renderWhitespace: renderWhitespace ?? this.renderWhitespace,
      rulers: rulers ?? this.rulers,
      stickyScroll: stickyScroll ?? this.stickyScroll,
      showFoldingControls: showFoldingControls ?? this.showFoldingControls,
      glyphMargin: glyphMargin ?? this.glyphMargin,
      renderLineHighlight: renderLineHighlight ?? this.renderLineHighlight,
      wordWrap: wordWrap ?? this.wordWrap,
      wordWrapColumn: wordWrapColumn ?? this.wordWrapColumn,
      tabSize: tabSize ?? this.tabSize,
      insertSpaces: insertSpaces ?? this.insertSpaces,
      autoIndent: autoIndent ?? this.autoIndent,
      autoClosingBrackets: autoClosingBrackets ?? this.autoClosingBrackets,
      autoClosingQuotes: autoClosingQuotes ?? this.autoClosingQuotes,
      autoSurround: autoSurround ?? this.autoSurround,
      bracketPairColorization:
          bracketPairColorization ?? this.bracketPairColorization,
      codeFolding: codeFolding ?? this.codeFolding,
      scrollBeyondLastLine: scrollBeyondLastLine ?? this.scrollBeyondLastLine,
      smoothScrolling: smoothScrolling ?? this.smoothScrolling,
      fastScrollSensitivity:
          fastScrollSensitivity ?? this.fastScrollSensitivity,
      scrollPredominantAxis:
          scrollPredominantAxis ?? this.scrollPredominantAxis,
      cursorBlinking: cursorBlinking ?? this.cursorBlinking,
      cursorSmoothCaretAnimation:
          cursorSmoothCaretAnimation ?? this.cursorSmoothCaretAnimation,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      multiCursorModifier: multiCursorModifier ?? this.multiCursorModifier,
      multiCursorMergeOverlapping:
          multiCursorMergeOverlapping ?? this.multiCursorMergeOverlapping,
      formatOnSave: formatOnSave ?? this.formatOnSave,
      formatOnPaste: formatOnPaste ?? this.formatOnPaste,
      formatOnType: formatOnType ?? this.formatOnType,
      quickSuggestions: quickSuggestions ?? this.quickSuggestions,
      quickSuggestionsDelay:
          quickSuggestionsDelay ?? this.quickSuggestionsDelay,
      suggestOnTriggerCharacters:
          suggestOnTriggerCharacters ?? this.suggestOnTriggerCharacters,
      acceptSuggestionOnEnter:
          acceptSuggestionOnEnter ?? this.acceptSuggestionOnEnter,
      acceptSuggestionOnCommitCharacter: acceptSuggestionOnCommitCharacter ??
          this.acceptSuggestionOnCommitCharacter,
      snippetSuggestions: snippetSuggestions ?? this.snippetSuggestions,
      wordBasedSuggestions: wordBasedSuggestions ?? this.wordBasedSuggestions,
      parameterHints: parameterHints ?? this.parameterHints,
      hover: hover ?? this.hover,
      contextMenu: contextMenu ?? this.contextMenu,
      find: find ?? this.find,
      seedSearchStringFromSelection:
          seedSearchStringFromSelection ?? this.seedSearchStringFromSelection,
      accessibilitySupport: accessibilitySupport ?? this.accessibilitySupport,
      accessibilityPageSize:
          accessibilityPageSize ?? this.accessibilityPageSize,
      renderValidationDecorations:
          renderValidationDecorations ?? this.renderValidationDecorations,
      renderControlCharacters:
          renderControlCharacters ?? this.renderControlCharacters,
      disableLayerHinting: disableLayerHinting ?? this.disableLayerHinting,
      disableMonospaceOptimizations:
          disableMonospaceOptimizations ?? this.disableMonospaceOptimizations,
      maxTokenizationLineLength:
          maxTokenizationLineLength ?? this.maxTokenizationLineLength,
      languageConfigs: languageConfigs ?? this.languageConfigs,
      keybindingPreset: keybindingPreset ?? this.keybindingPreset,
      customKeybindings: customKeybindings ?? this.customKeybindings,
      readOnly: readOnly ?? this.readOnly,
      domReadOnly: domReadOnly ?? this.domReadOnly,
      dragAndDrop: dragAndDrop ?? this.dragAndDrop,
      links: links ?? this.links,
      mouseWheelZoom: mouseWheelZoom ?? this.mouseWheelZoom,
      mouseWheelScrollSensitivity:
          mouseWheelScrollSensitivity ?? this.mouseWheelScrollSensitivity,
      automaticLayout: automaticLayout ?? this.automaticLayout,
      padding: padding ?? this.padding,
      roundedSelection: roundedSelection ?? this.roundedSelection,
      selectionHighlight: selectionHighlight ?? this.selectionHighlight,
      occurrencesHighlight: occurrencesHighlight ?? this.occurrencesHighlight,
      overviewRulerBorder: overviewRulerBorder ?? this.overviewRulerBorder,
      hideCursorInOverviewRuler:
          hideCursorInOverviewRuler ?? this.hideCursorInOverviewRuler,
      scrollbar: scrollbar ?? this.scrollbar,
      experimentalFeatures: experimentalFeatures ?? this.experimentalFeatures,
    );
  }

  /// Get settings for a specific language, merging global and language-specific settings
  EditorSettings getLanguageSettings(String language) {
    final langConfig = languageConfigs[language];
    if (langConfig == null) return this;

    return copyWith(
      tabSize: langConfig.tabSize ?? tabSize,
      insertSpaces: langConfig.insertSpaces ?? insertSpaces,
      wordWrap: langConfig.wordWrap ?? wordWrap,
      rulers: langConfig.rulers ?? rulers,
      formatOnSave: langConfig.formatOnSave ?? formatOnSave,
      formatOnPaste: langConfig.formatOnPaste ?? formatOnPaste,
      formatOnType: langConfig.formatOnType ?? formatOnType,
      autoClosingBrackets:
          langConfig.autoClosingBrackets ?? autoClosingBrackets,
      autoClosingQuotes: langConfig.autoClosingQuotes ?? autoClosingQuotes,
      bracketPairColorization:
          langConfig.bracketPairColorization ?? bracketPairColorization,
    );
  }

  /// Convert to Monaco editor options JSON
  Map<String, dynamic> toMonacoOptions() {
    return {
      'theme': theme,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': lineHeight,
      'letterSpacing': letterSpacing,
      'lineNumbers': showLineNumbers ? 'on' : 'off',
      'minimap': {
        'enabled': showMinimap,
        'side': minimapSide.name,
        'renderCharacters': minimapRenderCharacters,
        'size': minimapSize,
      },
      'renderIndentGuides': showIndentGuides,
      'renderWhitespace': renderWhitespace.name,
      'rulers': rulers,
      'stickyScroll': {'enabled': stickyScroll},
      'showFoldingControls': showFoldingControls,
      'glyphMargin': glyphMargin,
      'renderLineHighlight': renderLineHighlight,
      'wordWrap': wordWrap.name,
      'wordWrapColumn': wordWrapColumn,
      'tabSize': tabSize,
      'insertSpaces': insertSpaces,
      'autoIndent': autoIndent,
      'autoClosingBrackets': autoClosingBrackets,
      'autoClosingQuotes': autoClosingQuotes,
      'autoSurround': autoSurround,
      'bracketPairColorization': {'enabled': bracketPairColorization},
      'folding': codeFolding,
      'scrollBeyondLastLine': scrollBeyondLastLine,
      'smoothScrolling': smoothScrolling,
      'fastScrollSensitivity': fastScrollSensitivity,
      'scrollPredominantAxis': scrollPredominantAxis,
      'cursorBlinking': cursorBlinking.name,
      'cursorSmoothCaretAnimation': cursorSmoothCaretAnimation,
      'cursorStyle': cursorStyle.name,
      'cursorWidth': cursorWidth,
      'multiCursorModifier': multiCursorModifier.name,
      'multiCursorMergeOverlapping': multiCursorMergeOverlapping,
      'formatOnPaste': formatOnPaste,
      'formatOnType': formatOnType,
      'quickSuggestions': quickSuggestions,
      'quickSuggestionsDelay': quickSuggestionsDelay,
      'suggestOnTriggerCharacters': suggestOnTriggerCharacters,
      'acceptSuggestionOnEnter': acceptSuggestionOnEnter.name,
      'acceptSuggestionOnCommitCharacter': acceptSuggestionOnCommitCharacter,
      'snippetSuggestions': snippetSuggestions.name,
      'wordBasedSuggestions': wordBasedSuggestions.name,
      'parameterHints': {'enabled': parameterHints},
      'hover': {'enabled': hover},
      'contextmenu': contextMenu,
      'find': {
        'seedSearchStringFromSelection': seedSearchStringFromSelection,
      },
      'accessibilitySupport': accessibilitySupport.name,
      'accessibilityPageSize': accessibilityPageSize,
      'renderValidationDecorations': renderValidationDecorations,
      'renderControlCharacters': renderControlCharacters,
      'disableLayerHinting': disableLayerHinting,
      'disableMonospaceOptimizations': disableMonospaceOptimizations,
      'maxTokenizationLineLength': maxTokenizationLineLength,
      'readOnly': readOnly,
      'domReadOnly': domReadOnly,
      'dragAndDrop': dragAndDrop,
      'links': links,
      'mouseWheelZoom': mouseWheelZoom,
      'mouseWheelScrollSensitivity': mouseWheelScrollSensitivity,
      'automaticLayout': automaticLayout,
      'padding': padding,
      'roundedSelection': roundedSelection,
      'selectionHighlight': selectionHighlight,
      'occurrencesHighlight': occurrencesHighlight,
      'overviewRulerBorder': overviewRulerBorder,
      'hideCursorInOverviewRuler': hideCursorInOverviewRuler,
      'scrollbar': scrollbar,
    };
  }

  /// Save all settings to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    // General
    await prefs.setString(keyTheme, theme);
    await prefs.setDouble(keyFontSize, fontSize);
    await prefs.setString(keyFontFamily, fontFamily);
    await prefs.setDouble(keyLineHeight, lineHeight);
    await prefs.setDouble(keyLetterSpacing, letterSpacing);

    // Display
    await prefs.setBool(keyShowLineNumbers, showLineNumbers);
    await prefs.setString(keyLineNumbersStyle, lineNumbersStyle.name);
    await prefs.setBool(keyShowMinimap, showMinimap);
    await prefs.setString(keyMinimapSide, minimapSide.name);
    await prefs.setBool(keyMinimapRenderCharacters, minimapRenderCharacters);
    await prefs.setInt(keyMinimapSize, minimapSize);
    await prefs.setBool(keyShowIndentGuides, showIndentGuides);
    await prefs.setString(keyRenderWhitespace, renderWhitespace.name);
    await prefs.setStringList(
        keyRulers, rulers.map((r) => r.toString()).toList());
    await prefs.setBool(keyStickyScroll, stickyScroll);
    await prefs.setString(keyShowFoldingControls, showFoldingControls);
    await prefs.setBool(keyGlyphMargin, glyphMargin);
    await prefs.setString(keyRenderLineHighlight, renderLineHighlight);

    // Editor Behavior
    await prefs.setString(keyWordWrap, wordWrap.name);
    await prefs.setInt(keyWordWrapColumn, wordWrapColumn);
    await prefs.setInt(keyTabSize, tabSize);
    await prefs.setBool(keyInsertSpaces, insertSpaces);
    await prefs.setString(keyAutoIndent, autoIndent);
    await prefs.setString(keyAutoClosingBrackets, autoClosingBrackets);
    await prefs.setString(keyAutoClosingQuotes, autoClosingQuotes);
    await prefs.setString(keyAutoSurround, autoSurround);
    await prefs.setBool(keyBracketPairColorization, bracketPairColorization);
    await prefs.setBool(keyCodeFolding, codeFolding);
    await prefs.setBool(keyScrollBeyondLastLine, scrollBeyondLastLine);
    await prefs.setBool(keySmoothScrolling, smoothScrolling);
    await prefs.setDouble(keyFastScrollSensitivity, fastScrollSensitivity);
    await prefs.setBool(keyScrollPredominantAxis, scrollPredominantAxis);

    // Cursor
    await prefs.setString(keyCursorBlinking, cursorBlinking.name);
    await prefs.setString(
        keyCursorSmoothCaretAnimation, cursorSmoothCaretAnimation);
    await prefs.setString(keyCursorStyle, cursorStyle.name);
    await prefs.setInt(keyCursorWidth, cursorWidth);
    await prefs.setString(keyMultiCursorModifier, multiCursorModifier.name);
    await prefs.setBool(
        keyMultiCursorMergeOverlapping, multiCursorMergeOverlapping);

    // Editing Features
    await prefs.setBool(keyFormatOnSave, formatOnSave);
    await prefs.setBool(keyFormatOnPaste, formatOnPaste);
    await prefs.setBool(keyFormatOnType, formatOnType);
    await prefs.setBool(keyQuickSuggestions, quickSuggestions);
    await prefs.setInt(keyQuickSuggestionsDelay, quickSuggestionsDelay);
    await prefs.setBool(
        keySuggestOnTriggerCharacters, suggestOnTriggerCharacters);
    await prefs.setString(
        keyAcceptSuggestionOnEnter, acceptSuggestionOnEnter.name);
    await prefs.setBool(keyAcceptSuggestionOnCommitCharacter,
        acceptSuggestionOnCommitCharacter);
    await prefs.setString(keySnippetSuggestions, snippetSuggestions.name);
    await prefs.setString(keyWordBasedSuggestions, wordBasedSuggestions.name);
    await prefs.setBool(keyParameterHints, parameterHints);
    await prefs.setBool(keyHover, hover);
    await prefs.setBool(keyContextMenu, contextMenu);

    // Find & Replace
    await prefs.setBool(keyFind, find);
    await prefs.setString(
        keySeedSearchStringFromSelection, seedSearchStringFromSelection);

    // Accessibility
    await prefs.setString(keyAccessibilitySupport, accessibilitySupport.name);
    await prefs.setInt(keyAccessibilityPageSize, accessibilityPageSize);

    // Performance
    await prefs.setString(
        keyRenderValidationDecorations, renderValidationDecorations);
    await prefs.setBool(keyRenderControlCharacters, renderControlCharacters);
    await prefs.setBool(keyDisableLayerHinting, disableLayerHinting);
    await prefs.setBool(
        keyDisableMonospaceOptimizations, disableMonospaceOptimizations);
    await prefs.setInt(keyMaxTokenizationLineLength, maxTokenizationLineLength);

    // Language Configs (as JSON)
    final langConfigsJson = <String, Map<String, dynamic>>{};
    for (final entry in languageConfigs.entries) {
      langConfigsJson[entry.key] = entry.value.toJson();
    }
    await prefs.setString(keyLanguageConfigs, langConfigsJson.encode());

    // Keybindings
    await prefs.setString(keyKeybindingPreset, keybindingPreset.name);
    await prefs.setString(keyCustomKeybindings, customKeybindings.encode());

    // Advanced
    await prefs.setBool(keyReadOnly, readOnly);
    await prefs.setBool(keyDomReadOnly, domReadOnly);
    await prefs.setBool(keyDragAndDrop, dragAndDrop);
    await prefs.setBool(keyLinks, links);
    await prefs.setBool(keyMouseWheelZoom, mouseWheelZoom);
    await prefs.setDouble(
        keyMouseWheelScrollSensitivity, mouseWheelScrollSensitivity);
    await prefs.setBool(keyAutomaticLayout, automaticLayout);
    await prefs.setString(keyPadding, padding.encode());
    await prefs.setBool(keyRoundedSelection, roundedSelection);
    await prefs.setBool(keySelectionHighlight, selectionHighlight);
    await prefs.setString(keyOccurrencesHighlight, occurrencesHighlight);
    await prefs.setBool(keyOverviewRulerBorder, overviewRulerBorder);
    await prefs.setBool(
        keyHideCursorInOverviewRuler, hideCursorInOverviewRuler);
    await prefs.setString(keyScrollbar, scrollbar.encode());
    await prefs.setString(
        keyExperimentalFeatures, experimentalFeatures.encode());
  }

  /// Load all settings from SharedPreferences
  static Future<EditorSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Helper functions for enum parsing
    T? parseEnum<T extends Enum>(String? value, List<T> values) {
      if (value == null) return null;
      try {
        return values.firstWhere((e) => e.name == value);
      } catch (e) {
        return null;
      }
    }

    // Parse language configs
    final Map<String, LanguageConfig> parsedLanguageConfigs = {};
    final langConfigsString = prefs.getString(keyLanguageConfigs);
    if (langConfigsString != null) {
      try {
        final langConfigsJson =
            langConfigsString.decode() as Map<String, dynamic>? ?? {};
        for (final entry in langConfigsJson.entries) {
          if (entry.value is Map<String, dynamic>) {
            parsedLanguageConfigs[entry.key] =
                LanguageConfig.fromJson(entry.value as Map<String, dynamic>);
          }
        }
      } catch (e) {
        // Ignore parsing errors, use empty map
        if (kDebugMode) {
          print('Error parsing language configs from SharedPreferences: $e');
        }
      }
    }

    return EditorSettings(
      // General
      theme: prefs.getString(keyTheme) ?? defaultTheme,
      fontSize: prefs.getDouble(keyFontSize) ?? defaultFontSize,
      fontFamily: prefs.getString(keyFontFamily) ?? defaultFontFamily,
      lineHeight: prefs.getDouble(keyLineHeight) ?? defaultLineHeight,
      letterSpacing: prefs.getDouble(keyLetterSpacing) ?? defaultLetterSpacing,

      // Display
      showLineNumbers:
          prefs.getBool(keyShowLineNumbers) ?? defaultShowLineNumbers,
      lineNumbersStyle: parseEnum(
              prefs.getString(keyLineNumbersStyle), LineNumbersStyle.values) ??
          defaultLineNumbersStyle,
      showMinimap: prefs.getBool(keyShowMinimap) ?? defaultShowMinimap,
      minimapSide:
          parseEnum(prefs.getString(keyMinimapSide), MinimapSide.values) ??
              defaultMinimapSide,
      minimapRenderCharacters: prefs.getBool(keyMinimapRenderCharacters) ??
          defaultMinimapRenderCharacters,
      minimapSize: prefs.getInt(keyMinimapSize) ?? defaultMinimapSize,
      showIndentGuides:
          prefs.getBool(keyShowIndentGuides) ?? defaultShowIndentGuides,
      renderWhitespace: parseEnum(
              prefs.getString(keyRenderWhitespace), RenderWhitespace.values) ??
          defaultRenderWhitespace,
      rulers: prefs
              .getStringList(keyRulers)
              ?.map((s) => int.tryParse(s) ?? 0)
              .where((i) => i > 0)
              .toList() ??
          defaultRulers,
      stickyScroll: prefs.getBool(keyStickyScroll) ?? defaultStickyScroll,
      showFoldingControls:
          prefs.getString(keyShowFoldingControls) ?? defaultShowFoldingControls,
      glyphMargin: prefs.getBool(keyGlyphMargin) ?? defaultGlyphMargin,
      renderLineHighlight:
          prefs.getString(keyRenderLineHighlight) ?? defaultRenderLineHighlight,

      // Editor Behavior
      wordWrap: parseEnum(prefs.getString(keyWordWrap), WordWrap.values) ??
          defaultWordWrap,
      wordWrapColumn: prefs.getInt(keyWordWrapColumn) ?? defaultWordWrapColumn,
      tabSize: prefs.getInt(keyTabSize) ?? defaultTabSize,
      insertSpaces: prefs.getBool(keyInsertSpaces) ?? defaultInsertSpaces,
      autoIndent: prefs.getString(keyAutoIndent) ?? defaultAutoIndent,
      autoClosingBrackets:
          prefs.getString(keyAutoClosingBrackets) ?? defaultAutoClosingBrackets,
      autoClosingQuotes:
          prefs.getString(keyAutoClosingQuotes) ?? defaultAutoClosingQuotes,
      autoSurround: prefs.getString(keyAutoSurround) ?? defaultAutoSurround,
      bracketPairColorization: prefs.getBool(keyBracketPairColorization) ??
          defaultBracketPairColorization,
      codeFolding: prefs.getBool(keyCodeFolding) ?? defaultCodeFolding,
      scrollBeyondLastLine:
          prefs.getBool(keyScrollBeyondLastLine) ?? defaultScrollBeyondLastLine,
      smoothScrolling:
          prefs.getBool(keySmoothScrolling) ?? defaultSmoothScrolling,
      fastScrollSensitivity: prefs.getDouble(keyFastScrollSensitivity) ??
          defaultFastScrollSensitivity,
      scrollPredominantAxis: prefs.getBool(keyScrollPredominantAxis) ??
          defaultScrollPredominantAxis,

      // Cursor
      cursorBlinking: parseEnum(
              prefs.getString(keyCursorBlinking), CursorBlinking.values) ??
          defaultCursorBlinking,
      cursorSmoothCaretAnimation:
          prefs.getString(keyCursorSmoothCaretAnimation) ??
              defaultCursorSmoothCaretAnimation,
      cursorStyle:
          parseEnum(prefs.getString(keyCursorStyle), CursorStyle.values) ??
              defaultCursorStyle,
      cursorWidth: prefs.getInt(keyCursorWidth) ?? defaultCursorWidth,
      multiCursorModifier: parseEnum(prefs.getString(keyMultiCursorModifier),
              MultiCursorModifier.values) ??
          defaultMultiCursorModifier,
      multiCursorMergeOverlapping:
          prefs.getBool(keyMultiCursorMergeOverlapping) ??
              defaultMultiCursorMergeOverlapping,

      // Editing Features
      formatOnSave: prefs.getBool(keyFormatOnSave) ?? defaultFormatOnSave,
      formatOnPaste: prefs.getBool(keyFormatOnPaste) ?? defaultFormatOnPaste,
      formatOnType: prefs.getBool(keyFormatOnType) ?? defaultFormatOnType,
      quickSuggestions:
          prefs.getBool(keyQuickSuggestions) ?? defaultQuickSuggestions,
      quickSuggestionsDelay: prefs.getInt(keyQuickSuggestionsDelay) ??
          defaultQuickSuggestionsDelay,
      suggestOnTriggerCharacters:
          prefs.getBool(keySuggestOnTriggerCharacters) ??
              defaultSuggestOnTriggerCharacters,
      acceptSuggestionOnEnter: parseEnum(
              prefs.getString(keyAcceptSuggestionOnEnter),
              AcceptSuggestionOnEnter.values) ??
          defaultAcceptSuggestionOnEnter,
      acceptSuggestionOnCommitCharacter:
          prefs.getBool(keyAcceptSuggestionOnCommitCharacter) ??
              defaultAcceptSuggestionOnCommitCharacter,
      snippetSuggestions: parseEnum(prefs.getString(keySnippetSuggestions),
              SnippetSuggestions.values) ??
          defaultSnippetSuggestions,
      wordBasedSuggestions: parseEnum(prefs.getString(keyWordBasedSuggestions),
              WordBasedSuggestions.values) ??
          defaultWordBasedSuggestions,
      parameterHints: prefs.getBool(keyParameterHints) ?? defaultParameterHints,
      hover: prefs.getBool(keyHover) ?? defaultHover,
      contextMenu: prefs.getBool(keyContextMenu) ?? defaultContextMenu,

      // Find & Replace
      find: prefs.getBool(keyFind) ?? defaultFind,
      seedSearchStringFromSelection:
          prefs.getString(keySeedSearchStringFromSelection) ??
              defaultSeedSearchStringFromSelection,

      // Accessibility
      accessibilitySupport: parseEnum(prefs.getString(keyAccessibilitySupport),
              AccessibilitySupport.values) ??
          defaultAccessibilitySupport,
      accessibilityPageSize: prefs.getInt(keyAccessibilityPageSize) ??
          defaultAccessibilityPageSize,

      // Performance
      renderValidationDecorations:
          prefs.getString(keyRenderValidationDecorations) ??
              defaultRenderValidationDecorations,
      renderControlCharacters: prefs.getBool(keyRenderControlCharacters) ??
          defaultRenderControlCharacters,
      disableLayerHinting:
          prefs.getBool(keyDisableLayerHinting) ?? defaultDisableLayerHinting,
      disableMonospaceOptimizations:
          prefs.getBool(keyDisableMonospaceOptimizations) ??
              defaultDisableMonospaceOptimizations,
      maxTokenizationLineLength: prefs.getInt(keyMaxTokenizationLineLength) ??
          defaultMaxTokenizationLineLength,

      // Language Configs
      languageConfigs: parsedLanguageConfigs,

      // Keybindings
      keybindingPreset: parseEnum(prefs.getString(keyKeybindingPreset),
              KeybindingPresetEnum.values) ??
          defaultKeybindingPreset,
      customKeybindings: ConvertObject.toMap(
          prefs.getString(keyCustomKeybindings),
          defaultValue: {}),

      // Advanced
      readOnly: prefs.getBool(keyReadOnly) ?? defaultReadOnly,
      domReadOnly: prefs.getBool(keyDomReadOnly) ?? defaultDomReadOnly,
      dragAndDrop: prefs.getBool(keyDragAndDrop) ?? defaultDragAndDrop,
      links: prefs.getBool(keyLinks) ?? defaultLinks,
      mouseWheelZoom: prefs.getBool(keyMouseWheelZoom) ?? defaultMouseWheelZoom,
      mouseWheelScrollSensitivity:
          prefs.getDouble(keyMouseWheelScrollSensitivity) ??
              defaultMouseWheelScrollSensitivity,
      automaticLayout:
          prefs.getBool(keyAutomaticLayout) ?? defaultAutomaticLayout,
      padding: prefs.getString(keyPadding)?.decode()
              as Map<String, int>? ?? // Cast to Map<String, int>
          defaultPadding,
      roundedSelection:
          prefs.getBool(keyRoundedSelection) ?? defaultRoundedSelection,
      selectionHighlight:
          prefs.getBool(keySelectionHighlight) ?? defaultSelectionHighlight,
      occurrencesHighlight: prefs.getString(keyOccurrencesHighlight) ??
          defaultOccurrencesHighlight,
      overviewRulerBorder:
          prefs.getBool(keyOverviewRulerBorder) ?? defaultOverviewRulerBorder,
      hideCursorInOverviewRuler: prefs.getBool(keyHideCursorInOverviewRuler) ??
          defaultHideCursorInOverviewRuler,
      scrollbar: prefs.getString(keyScrollbar)?.decode()
              as Map<String, dynamic>? ?? // Cast to Map<String, dynamic>
          defaultScrollbar,
      experimentalFeatures: prefs.getString(keyExperimentalFeatures)?.decode()
              as Map<String, dynamic>? ?? // Cast to Map<String, dynamic>
          {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditorSettings &&
        other.theme == theme &&
        other.fontSize == fontSize &&
        other.fontFamily == fontFamily &&
        other.lineHeight == lineHeight &&
        other.letterSpacing == letterSpacing &&
        other.showLineNumbers == showLineNumbers &&
        other.lineNumbersStyle == lineNumbersStyle &&
        other.showMinimap == showMinimap &&
        other.minimapSide == minimapSide &&
        other.minimapRenderCharacters == minimapRenderCharacters &&
        other.minimapSize == minimapSize &&
        other.showIndentGuides == showIndentGuides &&
        other.renderWhitespace == renderWhitespace &&
        other.rulers.toString() == rulers.toString() &&
        other.stickyScroll == stickyScroll &&
        other.showFoldingControls == showFoldingControls &&
        other.glyphMargin == glyphMargin &&
        other.renderLineHighlight == renderLineHighlight &&
        other.wordWrap == wordWrap &&
        other.wordWrapColumn == wordWrapColumn &&
        other.tabSize == tabSize &&
        other.insertSpaces == insertSpaces &&
        other.autoIndent == autoIndent &&
        other.autoClosingBrackets == autoClosingBrackets &&
        other.autoClosingQuotes == autoClosingQuotes &&
        other.autoSurround == autoSurround &&
        other.bracketPairColorization == bracketPairColorization &&
        other.codeFolding == codeFolding &&
        other.scrollBeyondLastLine == scrollBeyondLastLine &&
        other.smoothScrolling == smoothScrolling &&
        other.readOnly == readOnly;
  }

  @override
  int get hashCode => Object.hashAll([
        theme,
        fontSize,
        fontFamily,
        lineHeight,
        letterSpacing,
        showLineNumbers,
        lineNumbersStyle,
        showMinimap,
        minimapSide,
        minimapRenderCharacters,
        minimapSize,
        showIndentGuides,
        renderWhitespace,
        rulers,
        stickyScroll,
        showFoldingControls,
        glyphMargin,
        renderLineHighlight,
        wordWrap,
        wordWrapColumn,
        tabSize,
        insertSpaces,
        autoIndent,
        autoClosingBrackets,
        autoClosingQuotes,
        autoSurround,
        bracketPairColorization,
        codeFolding,
        scrollBeyondLastLine,
        smoothScrolling,
        readOnly,
      ]);

  @override
  String toString() => 'EditorSettings('
      'theme: $theme, '
      'fontSize: $fontSize, '
      'fontFamily: $fontFamily, '
      'showLineNumbers: $showLineNumbers, '
      'showMinimap: $showMinimap, '
      'wordWrap: $wordWrap, '
      'tabSize: $tabSize, '
      'readOnly: $readOnly'
      ')';
}
