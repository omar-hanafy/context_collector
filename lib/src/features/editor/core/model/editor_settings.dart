// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_settings.freezed.dart';
part 'editor_settings.g.dart';

// --- ENUMS (Unchanged) ---
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
  underlineThin,
}

enum MultiCursorModifier { ctrlCmd, alt }

enum AcceptSuggestionOnEnter { on, off, smart }

enum SnippetSuggestions { top, bottom, inline, none }

enum WordBasedSuggestions {
  off,
  currentDocument,
  matchingDocuments,
  allDocuments,
}

enum AccessibilitySupport { auto, off, on }

enum KeybindingPresetEnum {
  vscode,
  intellij,
  vim,
  emacs,
  custom;

  String get monacoPreset => name;
}

// --- MODELS (Refactored for Freezed 3) ---

@freezed
abstract class LanguageConfig with _$LanguageConfig {
  const factory LanguageConfig({
    int? tabSize,
    bool? insertSpaces,
    WordWrap? wordWrap,
    @Default([]) List<int> rulers,
    bool? formatOnSave,
    bool? formatOnPaste,
    bool? formatOnType,
    String? autoClosingBrackets,
    String? autoClosingQuotes,
    bool? bracketPairColorization,
    Map<String, dynamic>? customTheme,
  }) = _LanguageConfig;

  factory LanguageConfig.fromJson(Map<String, dynamic> json) =>
      _$LanguageConfigFromJson(json);
}

@freezed
abstract class EditorSettings with _$EditorSettings {
  const factory EditorSettings({
    // General Settings
    @JsonKey(name: 'editor_theme') @Default('vs-dark') String theme,
    @JsonKey(name: 'editor_font_size') @Default(14) double fontSize,
    @JsonKey(name: 'editor_font_family')
    @Default(
      'JetBrains Mono, SF Mono, Menlo, Consolas, "Courier New", monospace',
    )
    String fontFamily,
    @JsonKey(name: 'editor_line_height') @Default(1.4) double lineHeight,
    @JsonKey(name: 'editor_letter_spacing') @Default(0) double letterSpacing,

    // Display Settings
    @JsonKey(name: 'editor_show_line_numbers')
    @Default(true)
    bool showLineNumbers,
    @JsonKey(name: 'editor_line_numbers_style')
    @Default(LineNumbersStyle.on)
    LineNumbersStyle lineNumbersStyle,
    @JsonKey(name: 'editor_show_minimap') @Default(false) bool showMinimap,
    @JsonKey(name: 'editor_minimap_side')
    @Default(MinimapSide.right)
    MinimapSide minimapSide,
    @JsonKey(name: 'editor_minimap_render_characters')
    @Default(false)
    bool minimapRenderCharacters,
    @JsonKey(name: 'editor_minimap_size') @Default(1) int minimapSize,
    @JsonKey(name: 'editor_show_indent_guides')
    @Default(true)
    bool showIndentGuides,
    @JsonKey(name: 'editor_render_whitespace')
    @Default(RenderWhitespace.selection)
    RenderWhitespace renderWhitespace,
    @JsonKey(name: 'editor_rulers') @Default([]) List<int> rulers,
    @JsonKey(name: 'editor_sticky_scroll') @Default(false) bool stickyScroll,
    @JsonKey(name: 'editor_show_folding_controls')
    @Default('mouseover')
    String showFoldingControls,
    @JsonKey(name: 'editor_glyph_margin') @Default(true) bool glyphMargin,
    @JsonKey(name: 'editor_render_line_highlight')
    @Default('line')
    String renderLineHighlight,

    // Editor Behavior
    @JsonKey(name: 'editor_word_wrap') @Default(WordWrap.on) WordWrap wordWrap,
    @JsonKey(name: 'editor_word_wrap_column') @Default(80) int wordWrapColumn,
    @JsonKey(name: 'editor_tab_size') @Default(4) int tabSize,
    @JsonKey(name: 'editor_insert_spaces') @Default(true) bool insertSpaces,
    @JsonKey(name: 'editor_auto_indent') @Default('advanced') String autoIndent,
    @JsonKey(name: 'editor_auto_closing_brackets')
    @Default('languageDefined')
    String autoClosingBrackets,
    @JsonKey(name: 'editor_auto_closing_quotes')
    @Default('languageDefined')
    String autoClosingQuotes,
    @JsonKey(name: 'editor_auto_surround')
    @Default('languageDefined')
    String autoSurround,
    @JsonKey(name: 'editor_bracket_pair_colorization')
    @Default(true)
    bool bracketPairColorization,
    @JsonKey(name: 'editor_code_folding') @Default(true) bool codeFolding,
    @JsonKey(name: 'editor_scroll_beyond_last_line')
    @Default(true)
    bool scrollBeyondLastLine,
    @JsonKey(name: 'editor_smooth_scrolling')
    @Default(false)
    bool smoothScrolling,
    @JsonKey(name: 'editor_fast_scroll_sensitivity')
    @Default(5)
    double fastScrollSensitivity,
    @JsonKey(name: 'editor_scroll_predominant_axis')
    @Default(true)
    bool scrollPredominantAxis,

    // Cursor Settings
    @JsonKey(name: 'editor_cursor_blinking')
    @Default(CursorBlinking.blink)
    CursorBlinking cursorBlinking,
    @JsonKey(name: 'editor_cursor_smooth_caret_animation')
    @Default('off')
    String cursorSmoothCaretAnimation,
    @JsonKey(name: 'editor_cursor_style')
    @Default(CursorStyle.line)
    CursorStyle cursorStyle,
    @JsonKey(name: 'editor_cursor_width') @Default(0) int cursorWidth,
    @JsonKey(name: 'editor_multi_cursor_modifier')
    @Default(MultiCursorModifier.ctrlCmd)
    MultiCursorModifier multiCursorModifier,
    @JsonKey(name: 'editor_multi_cursor_merge_overlapping')
    @Default(true)
    bool multiCursorMergeOverlapping,

    // Editing Features
    @JsonKey(name: 'editor_format_on_save') @Default(false) bool formatOnSave,
    @JsonKey(name: 'editor_format_on_paste') @Default(false) bool formatOnPaste,
    @JsonKey(name: 'editor_format_on_type') @Default(false) bool formatOnType,
    @JsonKey(name: 'editor_quick_suggestions')
    @Default(true)
    bool quickSuggestions,
    @JsonKey(name: 'editor_quick_suggestions_delay')
    @Default(10)
    int quickSuggestionsDelay,
    @JsonKey(name: 'editor_suggest_on_trigger_characters')
    @Default(true)
    bool suggestOnTriggerCharacters,
    @JsonKey(name: 'editor_accept_suggestion_on_enter')
    @Default(AcceptSuggestionOnEnter.on)
    AcceptSuggestionOnEnter acceptSuggestionOnEnter,
    @JsonKey(name: 'editor_accept_suggestion_on_commit_character')
    @Default(true)
    bool acceptSuggestionOnCommitCharacter,
    @JsonKey(name: 'editor_snippet_suggestions')
    @Default(SnippetSuggestions.inline)
    SnippetSuggestions snippetSuggestions,
    @JsonKey(name: 'editor_word_based_suggestions')
    @Default(WordBasedSuggestions.currentDocument)
    WordBasedSuggestions wordBasedSuggestions,
    @JsonKey(name: 'editor_parameter_hints') @Default(true) bool parameterHints,
    @JsonKey(name: 'editor_hover') @Default(true) bool hover,
    @JsonKey(name: 'editor_context_menu') @Default(true) bool contextMenu,

    // Find & Replace
    @JsonKey(name: 'editor_find') @Default(true) bool find,
    @JsonKey(name: 'editor_seed_search_string_from_selection')
    @Default('selection')
    String seedSearchStringFromSelection,

    // Accessibility
    @JsonKey(name: 'editor_accessibility_support')
    @Default(AccessibilitySupport.auto)
    AccessibilitySupport accessibilitySupport,
    @JsonKey(name: 'editor_accessibility_page_size')
    @Default(10)
    int accessibilityPageSize,

    // Performance
    @JsonKey(name: 'editor_render_validation_decorations')
    @Default('editable')
    String renderValidationDecorations,
    @JsonKey(name: 'editor_render_control_characters')
    @Default(false)
    bool renderControlCharacters,
    @JsonKey(name: 'editor_disable_layer_hinting')
    @Default(false)
    bool disableLayerHinting,
    @JsonKey(name: 'editor_disable_monospace_optimizations')
    @Default(false)
    bool disableMonospaceOptimizations,
    @JsonKey(name: 'editor_max_tokenization_line_length')
    @Default(20000)
    int maxTokenizationLineLength,

    // Language Specific
    @JsonKey(name: 'editor_language_configs')
    @Default({})
    Map<String, LanguageConfig> languageConfigs,

    // Keybindings
    @JsonKey(name: 'editor_keybinding_preset')
    @Default(KeybindingPresetEnum.vscode)
    KeybindingPresetEnum keybindingPreset,
    @JsonKey(name: 'editor_custom_keybindings')
    @Default({})
    Map<String, String> customKeybindings,

    // Advanced
    @JsonKey(name: 'editor_read_only') @Default(false) bool readOnly,
    @JsonKey(name: 'editor_dom_read_only') @Default(false) bool domReadOnly,
    @JsonKey(name: 'editor_drag_and_drop') @Default(true) bool dragAndDrop,
    @JsonKey(name: 'editor_links') @Default(true) bool links,
    @JsonKey(name: 'editor_mouse_wheel_zoom')
    @Default(false)
    bool mouseWheelZoom,
    @JsonKey(name: 'editor_mouse_wheel_scroll_sensitivity')
    @Default(1)
    double mouseWheelScrollSensitivity,
    @JsonKey(name: 'editor_automatic_layout')
    @Default(true)
    bool automaticLayout,
    @JsonKey(name: 'editor_padding')
    @Default({'top': 10, 'bottom': 10, 'start': 10, 'end': 10})
    Map<String, int> padding,
    @JsonKey(name: 'editor_rounded_selection')
    @Default(true)
    bool roundedSelection,
    @JsonKey(name: 'editor_selection_highlight')
    @Default(true)
    bool selectionHighlight,
    @JsonKey(name: 'editor_occurrences_highlight')
    @Default('singleFile')
    String occurrencesHighlight,
    @JsonKey(name: 'editor_overview_ruler_border')
    @Default(true)
    bool overviewRulerBorder,
    @JsonKey(name: 'editor_hide_cursor_in_overview_ruler')
    @Default(false)
    bool hideCursorInOverviewRuler,
    @JsonKey(name: 'editor_scrollbar')
    @Default({
      'vertical': 'auto',
      'horizontal': 'auto',
      'arrowSize': 11,
      'useShadows': true,
      'verticalScrollbarSize': 14,
      'horizontalScrollbarSize': 10,
      'scrollByPage': false,
    })
    Map<String, dynamic> scrollbar,
    @JsonKey(name: 'editor_experimental_features')
    @Default({})
    Map<String, dynamic> experimentalFeatures,
  }) = _EditorSettings;
  // Private constructor enables "mixed mode" for adding custom logic.
  const EditorSettings._();

  /// Handles JSON conversion.
  factory EditorSettings.fromJson(Map<String, dynamic> json) =>
      _$EditorSettingsFromJson(json);

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

  /// Get settings for a specific language, merging global and language-specific settings.
  EditorSettings getLanguageSettings(String language) {
    final langConfig = languageConfigs[language];
    if (langConfig == null) return this;

    return copyWith(
      tabSize: langConfig.tabSize ?? tabSize,
      insertSpaces: langConfig.insertSpaces ?? insertSpaces,
      wordWrap: langConfig.wordWrap ?? wordWrap,
      rulers: langConfig.rulers,
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

  /// Convert to Monaco editor options format (without prefixes)
  Map<String, dynamic> toMonacoOptions() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': lineHeight,
      'letterSpacing': letterSpacing,
      'lineNumbers': showLineNumbers ? lineNumbersStyle.name : 'off',
      'minimap': {
        'enabled': showMinimap,
        'side': minimapSide.name,
        'renderCharacters': minimapRenderCharacters,
        'size': minimapSize == 1
            ? 'proportional'
            : (minimapSize == 2 ? 'fill' : 'fit'),
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
      'multiCursorModifier': multiCursorModifier == MultiCursorModifier.ctrlCmd
          ? 'ctrlCmd'
          : 'alt',
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
      'occurrencesHighlight': occurrencesHighlight == 'singleFile',
      'overviewRulerBorder': overviewRulerBorder,
      'hideCursorInOverviewRuler': hideCursorInOverviewRuler,
      'scrollbar': scrollbar,
    };
  }
}
