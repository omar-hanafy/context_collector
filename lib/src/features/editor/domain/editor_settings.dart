import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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

enum KeybindingPresetEnum {
  vscode,
  intellij,
  vim,
  emacs,
  custom;

  // Map your enum values to Monaco keybinding presets
  String get monacoPreset => switch (this) {
        KeybindingPresetEnum.vscode => 'vscode',
        KeybindingPresetEnum.intellij => 'intellij',
        KeybindingPresetEnum.vim => 'vim',
        KeybindingPresetEnum.emacs => 'emacs',
        KeybindingPresetEnum.custom => 'custom',
      };
}

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

/// Editor configuration settings with comprehensive options
@immutable
class EditorSettings extends Equatable {
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
    // Helper to parse enum values with dart_helper_utils
    T? parseEnum<T extends Enum>(String? value, List<T> values) {
      if (value == null) return null;
      return values.firstWhereOrNull((e) => e.name == value);
    }

    // Parse language configs
    final parsedLanguageConfigs = <String, LanguageConfig>{};
    final langConfigsMap =
        ConvertObject.toMap<String, dynamic>(json['editor_language_configs']);
    for (final entry in langConfigsMap.entries) {
      final configMap = ConvertObject.toMap<String, dynamic>(entry.value);
      parsedLanguageConfigs[entry.key] = LanguageConfig.fromJson(configMap);
    }

    // Parse rulers list - handle both int and string lists
    List<int> parseRulers(dynamic rulersData) {
      if (rulersData == null) return defaultRulers;
      if (rulersData is List) {
        return rulersData
            .map(ConvertObject.toInt)
            .whereType<int>()
            .where((i) => i > 0)
            .toList();
      }
      return defaultRulers;
    }

    return EditorSettings(
      // General
      theme: json.tryGetString('editor_theme') ?? defaultTheme,
      fontSize: json.tryGetDouble('editor_font_size') ?? defaultFontSize,
      fontFamily: json.tryGetString('editor_font_family') ?? defaultFontFamily,
      lineHeight: json.tryGetDouble('editor_line_height') ?? defaultLineHeight,
      letterSpacing:
          json.tryGetDouble('editor_letter_spacing') ?? defaultLetterSpacing,

      // Display
      showLineNumbers:
          json.tryGetBool('editor_show_line_numbers') ?? defaultShowLineNumbers,
      lineNumbersStyle: parseEnum(
              json.tryGetString('editor_line_numbers_style'),
              LineNumbersStyle.values) ??
          defaultLineNumbersStyle,
      showMinimap: json.tryGetBool('editor_show_minimap') ?? defaultShowMinimap,
      minimapSide: parseEnum(
              json.tryGetString('editor_minimap_side'), MinimapSide.values) ??
          defaultMinimapSide,
      minimapRenderCharacters:
          json.tryGetBool('editor_minimap_render_characters') ??
              defaultMinimapRenderCharacters,
      minimapSize: json.tryGetInt('editor_minimap_size') ?? defaultMinimapSize,
      showIndentGuides: json.tryGetBool('editor_show_indent_guides') ??
          defaultShowIndentGuides,
      renderWhitespace: parseEnum(json.tryGetString('editor_render_whitespace'),
              RenderWhitespace.values) ??
          defaultRenderWhitespace,
      rulers: parseRulers(json['editor_rulers']),
      stickyScroll:
          json.tryGetBool('editor_sticky_scroll') ?? defaultStickyScroll,
      showFoldingControls: json.tryGetString('editor_show_folding_controls') ??
          defaultShowFoldingControls,
      glyphMargin: json.tryGetBool('editor_glyph_margin') ?? defaultGlyphMargin,
      renderLineHighlight: json.tryGetString('editor_render_line_highlight') ??
          defaultRenderLineHighlight,

      // Editor Behavior
      wordWrap:
          parseEnum(json.tryGetString('editor_word_wrap'), WordWrap.values) ??
              defaultWordWrap,
      wordWrapColumn:
          json.tryGetInt('editor_word_wrap_column') ?? defaultWordWrapColumn,
      tabSize: json.tryGetInt('editor_tab_size') ?? defaultTabSize,
      insertSpaces:
          json.tryGetBool('editor_insert_spaces') ?? defaultInsertSpaces,
      autoIndent: json.tryGetString('editor_auto_indent') ?? defaultAutoIndent,
      autoClosingBrackets: json.tryGetString('editor_auto_closing_brackets') ??
          defaultAutoClosingBrackets,
      autoClosingQuotes: json.tryGetString('editor_auto_closing_quotes') ??
          defaultAutoClosingQuotes,
      autoSurround:
          json.tryGetString('editor_auto_surround') ?? defaultAutoSurround,
      bracketPairColorization:
          json.tryGetBool('editor_bracket_pair_colorization') ??
              defaultBracketPairColorization,
      codeFolding: json.tryGetBool('editor_code_folding') ?? defaultCodeFolding,
      scrollBeyondLastLine: json.tryGetBool('editor_scroll_beyond_last_line') ??
          defaultScrollBeyondLastLine,
      smoothScrolling:
          json.tryGetBool('editor_smooth_scrolling') ?? defaultSmoothScrolling,
      fastScrollSensitivity:
          json.tryGetDouble('editor_fast_scroll_sensitivity') ??
              defaultFastScrollSensitivity,
      scrollPredominantAxis:
          json.tryGetBool('editor_scroll_predominant_axis') ??
              defaultScrollPredominantAxis,

      // Cursor
      cursorBlinking: parseEnum(json.tryGetString('editor_cursor_blinking'),
              CursorBlinking.values) ??
          defaultCursorBlinking,
      cursorSmoothCaretAnimation:
          json.tryGetString('editor_cursor_smooth_caret_animation') ??
              defaultCursorSmoothCaretAnimation,
      cursorStyle: parseEnum(
              json.tryGetString('editor_cursor_style'), CursorStyle.values) ??
          defaultCursorStyle,
      cursorWidth: json.tryGetInt('editor_cursor_width') ?? defaultCursorWidth,
      multiCursorModifier: parseEnum(
              json.tryGetString('editor_multi_cursor_modifier'),
              MultiCursorModifier.values) ??
          defaultMultiCursorModifier,
      multiCursorMergeOverlapping:
          json.tryGetBool('editor_multi_cursor_merge_overlapping') ??
              defaultMultiCursorMergeOverlapping,

      // Editing Features
      formatOnSave:
          json.tryGetBool('editor_format_on_save') ?? defaultFormatOnSave,
      formatOnPaste:
          json.tryGetBool('editor_format_on_paste') ?? defaultFormatOnPaste,
      formatOnType:
          json.tryGetBool('editor_format_on_type') ?? defaultFormatOnType,
      quickSuggestions: json.tryGetBool('editor_quick_suggestions') ??
          defaultQuickSuggestions,
      quickSuggestionsDelay: json.tryGetInt('editor_quick_suggestions_delay') ??
          defaultQuickSuggestionsDelay,
      suggestOnTriggerCharacters:
          json.tryGetBool('editor_suggest_on_trigger_characters') ??
              defaultSuggestOnTriggerCharacters,
      acceptSuggestionOnEnter: parseEnum(
              json.tryGetString('editor_accept_suggestion_on_enter'),
              AcceptSuggestionOnEnter.values) ??
          defaultAcceptSuggestionOnEnter,
      acceptSuggestionOnCommitCharacter:
          json.tryGetBool('editor_accept_suggestion_on_commit_character') ??
              defaultAcceptSuggestionOnCommitCharacter,
      snippetSuggestions: parseEnum(
              json.tryGetString('editor_snippet_suggestions'),
              SnippetSuggestions.values) ??
          defaultSnippetSuggestions,
      wordBasedSuggestions: parseEnum(
              json.tryGetString('editor_word_based_suggestions'),
              WordBasedSuggestions.values) ??
          defaultWordBasedSuggestions,
      parameterHints:
          json.tryGetBool('editor_parameter_hints') ?? defaultParameterHints,
      hover: json.tryGetBool('editor_hover') ?? defaultHover,
      contextMenu: json.tryGetBool('editor_context_menu') ?? defaultContextMenu,

      // Find & Replace
      find: json.tryGetBool('editor_find') ?? defaultFind,
      seedSearchStringFromSelection:
          json.tryGetString('editor_seed_search_string_from_selection') ??
              defaultSeedSearchStringFromSelection,

      // Accessibility
      accessibilitySupport: parseEnum(
              json.tryGetString('editor_accessibility_support'),
              AccessibilitySupport.values) ??
          defaultAccessibilitySupport,
      accessibilityPageSize: json.tryGetInt('editor_accessibility_page_size') ??
          defaultAccessibilityPageSize,

      // Performance
      renderValidationDecorations:
          json.tryGetString('editor_render_validation_decorations') ??
              defaultRenderValidationDecorations,
      renderControlCharacters:
          json.tryGetBool('editor_render_control_characters') ??
              defaultRenderControlCharacters,
      disableLayerHinting: json.tryGetBool('editor_disable_layer_hinting') ??
          defaultDisableLayerHinting,
      disableMonospaceOptimizations:
          json.tryGetBool('editor_disable_monospace_optimizations') ??
              defaultDisableMonospaceOptimizations,
      maxTokenizationLineLength:
          json.tryGetInt('editor_max_tokenization_line_length') ??
              defaultMaxTokenizationLineLength,

      // Language Configs
      languageConfigs: parsedLanguageConfigs,

      // Keybindings
      keybindingPreset: parseEnum(json.tryGetString('editor_keybinding_preset'),
              KeybindingPresetEnum.values) ??
          defaultKeybindingPreset,
      customKeybindings: ConvertObject.toMap<String, String>(
          json['editor_custom_keybindings']),

      // Advanced
      readOnly: json.tryGetBool('editor_read_only') ?? defaultReadOnly,
      domReadOnly:
          json.tryGetBool('editor_dom_read_only') ?? defaultDomReadOnly,
      dragAndDrop:
          json.tryGetBool('editor_drag_and_drop') ?? defaultDragAndDrop,
      links: json.tryGetBool('editor_links') ?? defaultLinks,
      mouseWheelZoom:
          json.tryGetBool('editor_mouse_wheel_zoom') ?? defaultMouseWheelZoom,
      mouseWheelScrollSensitivity:
          json.tryGetDouble('editor_mouse_wheel_scroll_sensitivity') ??
              defaultMouseWheelScrollSensitivity,
      automaticLayout:
          json.tryGetBool('editor_automatic_layout') ?? defaultAutomaticLayout,
      padding:
          ConvertObject.toMap<String, int>(json['editor_padding']).isNotEmpty
              ? ConvertObject.toMap<String, int>(json['editor_padding'])
              : defaultPadding,
      roundedSelection: json.tryGetBool('editor_rounded_selection') ??
          defaultRoundedSelection,
      selectionHighlight: json.tryGetBool('editor_selection_highlight') ??
          defaultSelectionHighlight,
      occurrencesHighlight: json.tryGetString('editor_occurrences_highlight') ??
          defaultOccurrencesHighlight,
      overviewRulerBorder: json.tryGetBool('editor_overview_ruler_border') ??
          defaultOverviewRulerBorder,
      hideCursorInOverviewRuler:
          json.tryGetBool('editor_hide_cursor_in_overview_ruler') ??
              defaultHideCursorInOverviewRuler,
      scrollbar: ConvertObject.toMap<String, dynamic>(json['editor_scrollbar'])
              .isNotEmpty
          ? ConvertObject.toMap<String, dynamic>(json['editor_scrollbar'])
          : defaultScrollbar,
      experimentalFeatures: ConvertObject.toMap<String, dynamic>(
          json['editor_experimental_features']),
    );
  }

  /// Create preset configurations
  factory EditorSettings.createPreset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'beginner':
        return const EditorSettings(
          showMinimap: false,
          fontSize: 16,
          formatOnSave: true,
          formatOnPaste: true,
          autoClosingBrackets: 'always',
          autoClosingQuotes: 'always',
        );

      case 'developer':
        return const EditorSettings(
          showMinimap: true,
          wordWrap: WordWrap.off,
          rulers: [80, 120],
          formatOnSave: true,
          renderWhitespace: RenderWhitespace.boundary,
        );

      case 'poweruser':
        return const EditorSettings(
          lineNumbersStyle: LineNumbersStyle.relative,
          showMinimap: true,
          fontSize: 13,
          wordWrap: WordWrap.off,
          rulers: [80, 100, 120],
          formatOnSave: true,
          formatOnType: true,
          stickyScroll: true,
          renderWhitespace: RenderWhitespace.all,
          cursorBlinking: CursorBlinking.smooth,
          multiCursorModifier: MultiCursorModifier.alt,
        );

      case 'accessibility':
        return const EditorSettings(
          fontSize: 18,
          lineHeight: 1.6,
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

  // === PROPERTIES ===
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

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      // General
      'editor_theme': theme,
      'editor_font_size': fontSize,
      'editor_font_family': fontFamily,
      'editor_line_height': lineHeight,
      'editor_letter_spacing': letterSpacing,

      // Display
      'editor_show_line_numbers': showLineNumbers,
      'editor_line_numbers_style': lineNumbersStyle.name,
      'editor_show_minimap': showMinimap,
      'editor_minimap_side': minimapSide.name,
      'editor_minimap_render_characters': minimapRenderCharacters,
      'editor_minimap_size': minimapSize,
      'editor_show_indent_guides': showIndentGuides,
      'editor_render_whitespace': renderWhitespace.name,
      'editor_rulers': rulers,
      'editor_sticky_scroll': stickyScroll,
      'editor_show_folding_controls': showFoldingControls,
      'editor_glyph_margin': glyphMargin,
      'editor_render_line_highlight': renderLineHighlight,

      // Editor Behavior
      'editor_word_wrap': wordWrap.name,
      'editor_word_wrap_column': wordWrapColumn,
      'editor_tab_size': tabSize,
      'editor_insert_spaces': insertSpaces,
      'editor_auto_indent': autoIndent,
      'editor_auto_closing_brackets': autoClosingBrackets,
      'editor_auto_closing_quotes': autoClosingQuotes,
      'editor_auto_surround': autoSurround,
      'editor_bracket_pair_colorization': bracketPairColorization,
      'editor_code_folding': codeFolding,
      'editor_scroll_beyond_last_line': scrollBeyondLastLine,
      'editor_smooth_scrolling': smoothScrolling,
      'editor_fast_scroll_sensitivity': fastScrollSensitivity,
      'editor_scroll_predominant_axis': scrollPredominantAxis,

      // Cursor
      'editor_cursor_blinking': cursorBlinking.name,
      'editor_cursor_smooth_caret_animation': cursorSmoothCaretAnimation,
      'editor_cursor_style': cursorStyle.name,
      'editor_cursor_width': cursorWidth,
      'editor_multi_cursor_modifier': multiCursorModifier.name,
      'editor_multi_cursor_merge_overlapping': multiCursorMergeOverlapping,

      // Editing Features
      'editor_format_on_save': formatOnSave,
      'editor_format_on_paste': formatOnPaste,
      'editor_format_on_type': formatOnType,
      'editor_quick_suggestions': quickSuggestions,
      'editor_quick_suggestions_delay': quickSuggestionsDelay,
      'editor_suggest_on_trigger_characters': suggestOnTriggerCharacters,
      'editor_accept_suggestion_on_enter': acceptSuggestionOnEnter.name,
      'editor_accept_suggestion_on_commit_character':
          acceptSuggestionOnCommitCharacter,
      'editor_snippet_suggestions': snippetSuggestions.name,
      'editor_word_based_suggestions': wordBasedSuggestions.name,
      'editor_parameter_hints': parameterHints,
      'editor_hover': hover,
      'editor_context_menu': contextMenu,

      // Find & Replace
      'editor_find': find,
      'editor_seed_search_string_from_selection': seedSearchStringFromSelection,

      // Accessibility
      'editor_accessibility_support': accessibilitySupport.name,
      'editor_accessibility_page_size': accessibilityPageSize,

      // Performance
      'editor_render_validation_decorations': renderValidationDecorations,
      'editor_render_control_characters': renderControlCharacters,
      'editor_disable_layer_hinting': disableLayerHinting,
      'editor_disable_monospace_optimizations': disableMonospaceOptimizations,
      'editor_max_tokenization_line_length': maxTokenizationLineLength,

      // Language Configs
      'editor_language_configs': Map<String, dynamic>.fromEntries(
          languageConfigs.entries
              .map((e) => MapEntry(e.key, e.value.toJson()))),

      // Keybindings
      'editor_keybinding_preset': keybindingPreset.name,
      'editor_custom_keybindings': customKeybindings,

      // Advanced
      'editor_read_only': readOnly,
      'editor_dom_read_only': domReadOnly,
      'editor_drag_and_drop': dragAndDrop,
      'editor_links': links,
      'editor_mouse_wheel_zoom': mouseWheelZoom,
      'editor_mouse_wheel_scroll_sensitivity': mouseWheelScrollSensitivity,
      'editor_automatic_layout': automaticLayout,
      'editor_padding': padding,
      'editor_rounded_selection': roundedSelection,
      'editor_selection_highlight': selectionHighlight,
      'editor_occurrences_highlight': occurrencesHighlight,
      'editor_overview_ruler_border': overviewRulerBorder,
      'editor_hide_cursor_in_overview_ruler': hideCursorInOverviewRuler,
      'editor_scrollbar': scrollbar,
      'editor_experimental_features': experimentalFeatures,
    };
  }


  @override
  List<Object?> get props => [
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
      ];
}
