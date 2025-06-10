// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LanguageConfig _$LanguageConfigFromJson(Map<String, dynamic> json) =>
    _LanguageConfig(
      tabSize: (json['tabSize'] as num?)?.toInt(),
      insertSpaces: json['insertSpaces'] as bool?,
      wordWrap: $enumDecodeNullable(_$WordWrapEnumMap, json['wordWrap']),
      rulers:
          (json['rulers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      formatOnSave: json['formatOnSave'] as bool?,
      formatOnPaste: json['formatOnPaste'] as bool?,
      formatOnType: json['formatOnType'] as bool?,
      autoClosingBrackets: json['autoClosingBrackets'] as String?,
      autoClosingQuotes: json['autoClosingQuotes'] as String?,
      bracketPairColorization: json['bracketPairColorization'] as bool?,
      customTheme: json['customTheme'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$LanguageConfigToJson(_LanguageConfig instance) =>
    <String, dynamic>{
      'tabSize': instance.tabSize,
      'insertSpaces': instance.insertSpaces,
      'wordWrap': _$WordWrapEnumMap[instance.wordWrap],
      'rulers': instance.rulers,
      'formatOnSave': instance.formatOnSave,
      'formatOnPaste': instance.formatOnPaste,
      'formatOnType': instance.formatOnType,
      'autoClosingBrackets': instance.autoClosingBrackets,
      'autoClosingQuotes': instance.autoClosingQuotes,
      'bracketPairColorization': instance.bracketPairColorization,
      'customTheme': instance.customTheme,
    };

const _$WordWrapEnumMap = {
  WordWrap.off: 'off',
  WordWrap.on: 'on',
  WordWrap.wordWrapColumn: 'wordWrapColumn',
  WordWrap.bounded: 'bounded',
};

_EditorSettings _$EditorSettingsFromJson(
  Map<String, dynamic> json,
) => _EditorSettings(
  theme: json['editor_theme'] as String? ?? 'vs-dark',
  fontSize: (json['editor_font_size'] as num?)?.toDouble() ?? 14,
  fontFamily:
      json['editor_font_family'] as String? ??
      'JetBrains Mono, SF Mono, Menlo, Consolas, "Courier New", monospace',
  lineHeight: (json['editor_line_height'] as num?)?.toDouble() ?? 1.4,
  letterSpacing: (json['editor_letter_spacing'] as num?)?.toDouble() ?? 0,
  showLineNumbers: json['editor_show_line_numbers'] as bool? ?? true,
  lineNumbersStyle:
      $enumDecodeNullable(
        _$LineNumbersStyleEnumMap,
        json['editor_line_numbers_style'],
      ) ??
      LineNumbersStyle.on,
  showMinimap: json['editor_show_minimap'] as bool? ?? false,
  minimapSide:
      $enumDecodeNullable(_$MinimapSideEnumMap, json['editor_minimap_side']) ??
      MinimapSide.right,
  minimapRenderCharacters:
      json['editor_minimap_render_characters'] as bool? ?? false,
  minimapSize: (json['editor_minimap_size'] as num?)?.toInt() ?? 1,
  showIndentGuides: json['editor_show_indent_guides'] as bool? ?? true,
  renderWhitespace:
      $enumDecodeNullable(
        _$RenderWhitespaceEnumMap,
        json['editor_render_whitespace'],
      ) ??
      RenderWhitespace.selection,
  rulers:
      (json['editor_rulers'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  stickyScroll: json['editor_sticky_scroll'] as bool? ?? false,
  showFoldingControls:
      json['editor_show_folding_controls'] as String? ?? 'mouseover',
  glyphMargin: json['editor_glyph_margin'] as bool? ?? true,
  renderLineHighlight:
      json['editor_render_line_highlight'] as String? ?? 'line',
  wordWrap:
      $enumDecodeNullable(_$WordWrapEnumMap, json['editor_word_wrap']) ??
      WordWrap.on,
  wordWrapColumn: (json['editor_word_wrap_column'] as num?)?.toInt() ?? 80,
  tabSize: (json['editor_tab_size'] as num?)?.toInt() ?? 4,
  insertSpaces: json['editor_insert_spaces'] as bool? ?? true,
  autoIndent: json['editor_auto_indent'] as String? ?? 'advanced',
  autoClosingBrackets:
      json['editor_auto_closing_brackets'] as String? ?? 'languageDefined',
  autoClosingQuotes:
      json['editor_auto_closing_quotes'] as String? ?? 'languageDefined',
  autoSurround: json['editor_auto_surround'] as String? ?? 'languageDefined',
  bracketPairColorization:
      json['editor_bracket_pair_colorization'] as bool? ?? true,
  codeFolding: json['editor_code_folding'] as bool? ?? true,
  scrollBeyondLastLine: json['editor_scroll_beyond_last_line'] as bool? ?? true,
  smoothScrolling: json['editor_smooth_scrolling'] as bool? ?? false,
  fastScrollSensitivity:
      (json['editor_fast_scroll_sensitivity'] as num?)?.toDouble() ?? 5,
  scrollPredominantAxis:
      json['editor_scroll_predominant_axis'] as bool? ?? true,
  cursorBlinking:
      $enumDecodeNullable(
        _$CursorBlinkingEnumMap,
        json['editor_cursor_blinking'],
      ) ??
      CursorBlinking.blink,
  cursorSmoothCaretAnimation:
      json['editor_cursor_smooth_caret_animation'] as String? ?? 'off',
  cursorStyle:
      $enumDecodeNullable(_$CursorStyleEnumMap, json['editor_cursor_style']) ??
      CursorStyle.line,
  cursorWidth: (json['editor_cursor_width'] as num?)?.toInt() ?? 0,
  multiCursorModifier:
      $enumDecodeNullable(
        _$MultiCursorModifierEnumMap,
        json['editor_multi_cursor_modifier'],
      ) ??
      MultiCursorModifier.ctrlCmd,
  multiCursorMergeOverlapping:
      json['editor_multi_cursor_merge_overlapping'] as bool? ?? true,
  formatOnSave: json['editor_format_on_save'] as bool? ?? false,
  formatOnPaste: json['editor_format_on_paste'] as bool? ?? false,
  formatOnType: json['editor_format_on_type'] as bool? ?? false,
  quickSuggestions: json['editor_quick_suggestions'] as bool? ?? true,
  quickSuggestionsDelay:
      (json['editor_quick_suggestions_delay'] as num?)?.toInt() ?? 10,
  suggestOnTriggerCharacters:
      json['editor_suggest_on_trigger_characters'] as bool? ?? true,
  acceptSuggestionOnEnter:
      $enumDecodeNullable(
        _$AcceptSuggestionOnEnterEnumMap,
        json['editor_accept_suggestion_on_enter'],
      ) ??
      AcceptSuggestionOnEnter.on,
  acceptSuggestionOnCommitCharacter:
      json['editor_accept_suggestion_on_commit_character'] as bool? ?? true,
  snippetSuggestions:
      $enumDecodeNullable(
        _$SnippetSuggestionsEnumMap,
        json['editor_snippet_suggestions'],
      ) ??
      SnippetSuggestions.inline,
  wordBasedSuggestions:
      $enumDecodeNullable(
        _$WordBasedSuggestionsEnumMap,
        json['editor_word_based_suggestions'],
      ) ??
      WordBasedSuggestions.currentDocument,
  parameterHints: json['editor_parameter_hints'] as bool? ?? true,
  hover: json['editor_hover'] as bool? ?? true,
  contextMenu: json['editor_context_menu'] as bool? ?? true,
  find: json['editor_find'] as bool? ?? true,
  seedSearchStringFromSelection:
      json['editor_seed_search_string_from_selection'] as String? ??
      'selection',
  accessibilitySupport:
      $enumDecodeNullable(
        _$AccessibilitySupportEnumMap,
        json['editor_accessibility_support'],
      ) ??
      AccessibilitySupport.auto,
  accessibilityPageSize:
      (json['editor_accessibility_page_size'] as num?)?.toInt() ?? 10,
  renderValidationDecorations:
      json['editor_render_validation_decorations'] as String? ?? 'editable',
  renderControlCharacters:
      json['editor_render_control_characters'] as bool? ?? false,
  disableLayerHinting: json['editor_disable_layer_hinting'] as bool? ?? false,
  disableMonospaceOptimizations:
      json['editor_disable_monospace_optimizations'] as bool? ?? false,
  maxTokenizationLineLength:
      (json['editor_max_tokenization_line_length'] as num?)?.toInt() ?? 20000,
  languageConfigs:
      (json['editor_language_configs'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, LanguageConfig.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
  keybindingPreset:
      $enumDecodeNullable(
        _$KeybindingPresetEnumEnumMap,
        json['editor_keybinding_preset'],
      ) ??
      KeybindingPresetEnum.vscode,
  customKeybindings:
      (json['editor_custom_keybindings'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  readOnly: json['editor_read_only'] as bool? ?? false,
  domReadOnly: json['editor_dom_read_only'] as bool? ?? false,
  dragAndDrop: json['editor_drag_and_drop'] as bool? ?? true,
  links: json['editor_links'] as bool? ?? true,
  mouseWheelZoom: json['editor_mouse_wheel_zoom'] as bool? ?? false,
  mouseWheelScrollSensitivity:
      (json['editor_mouse_wheel_scroll_sensitivity'] as num?)?.toDouble() ?? 1,
  automaticLayout: json['editor_automatic_layout'] as bool? ?? true,
  padding:
      (json['editor_padding'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {'top': 10, 'bottom': 10, 'start': 10, 'end': 10},
  roundedSelection: json['editor_rounded_selection'] as bool? ?? true,
  selectionHighlight: json['editor_selection_highlight'] as bool? ?? true,
  occurrencesHighlight:
      json['editor_occurrences_highlight'] as String? ?? 'singleFile',
  overviewRulerBorder: json['editor_overview_ruler_border'] as bool? ?? true,
  hideCursorInOverviewRuler:
      json['editor_hide_cursor_in_overview_ruler'] as bool? ?? false,
  scrollbar:
      json['editor_scrollbar'] as Map<String, dynamic>? ??
      const {
        'vertical': 'auto',
        'horizontal': 'auto',
        'arrowSize': 11,
        'useShadows': true,
        'verticalScrollbarSize': 14,
        'horizontalScrollbarSize': 10,
        'scrollByPage': false,
      },
  experimentalFeatures:
      json['editor_experimental_features'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$EditorSettingsToJson(
  _EditorSettings instance,
) => <String, dynamic>{
  'editor_theme': instance.theme,
  'editor_font_size': instance.fontSize,
  'editor_font_family': instance.fontFamily,
  'editor_line_height': instance.lineHeight,
  'editor_letter_spacing': instance.letterSpacing,
  'editor_show_line_numbers': instance.showLineNumbers,
  'editor_line_numbers_style':
      _$LineNumbersStyleEnumMap[instance.lineNumbersStyle]!,
  'editor_show_minimap': instance.showMinimap,
  'editor_minimap_side': _$MinimapSideEnumMap[instance.minimapSide]!,
  'editor_minimap_render_characters': instance.minimapRenderCharacters,
  'editor_minimap_size': instance.minimapSize,
  'editor_show_indent_guides': instance.showIndentGuides,
  'editor_render_whitespace':
      _$RenderWhitespaceEnumMap[instance.renderWhitespace]!,
  'editor_rulers': instance.rulers,
  'editor_sticky_scroll': instance.stickyScroll,
  'editor_show_folding_controls': instance.showFoldingControls,
  'editor_glyph_margin': instance.glyphMargin,
  'editor_render_line_highlight': instance.renderLineHighlight,
  'editor_word_wrap': _$WordWrapEnumMap[instance.wordWrap]!,
  'editor_word_wrap_column': instance.wordWrapColumn,
  'editor_tab_size': instance.tabSize,
  'editor_insert_spaces': instance.insertSpaces,
  'editor_auto_indent': instance.autoIndent,
  'editor_auto_closing_brackets': instance.autoClosingBrackets,
  'editor_auto_closing_quotes': instance.autoClosingQuotes,
  'editor_auto_surround': instance.autoSurround,
  'editor_bracket_pair_colorization': instance.bracketPairColorization,
  'editor_code_folding': instance.codeFolding,
  'editor_scroll_beyond_last_line': instance.scrollBeyondLastLine,
  'editor_smooth_scrolling': instance.smoothScrolling,
  'editor_fast_scroll_sensitivity': instance.fastScrollSensitivity,
  'editor_scroll_predominant_axis': instance.scrollPredominantAxis,
  'editor_cursor_blinking': _$CursorBlinkingEnumMap[instance.cursorBlinking]!,
  'editor_cursor_smooth_caret_animation': instance.cursorSmoothCaretAnimation,
  'editor_cursor_style': _$CursorStyleEnumMap[instance.cursorStyle]!,
  'editor_cursor_width': instance.cursorWidth,
  'editor_multi_cursor_modifier':
      _$MultiCursorModifierEnumMap[instance.multiCursorModifier]!,
  'editor_multi_cursor_merge_overlapping': instance.multiCursorMergeOverlapping,
  'editor_format_on_save': instance.formatOnSave,
  'editor_format_on_paste': instance.formatOnPaste,
  'editor_format_on_type': instance.formatOnType,
  'editor_quick_suggestions': instance.quickSuggestions,
  'editor_quick_suggestions_delay': instance.quickSuggestionsDelay,
  'editor_suggest_on_trigger_characters': instance.suggestOnTriggerCharacters,
  'editor_accept_suggestion_on_enter':
      _$AcceptSuggestionOnEnterEnumMap[instance.acceptSuggestionOnEnter]!,
  'editor_accept_suggestion_on_commit_character':
      instance.acceptSuggestionOnCommitCharacter,
  'editor_snippet_suggestions':
      _$SnippetSuggestionsEnumMap[instance.snippetSuggestions]!,
  'editor_word_based_suggestions':
      _$WordBasedSuggestionsEnumMap[instance.wordBasedSuggestions]!,
  'editor_parameter_hints': instance.parameterHints,
  'editor_hover': instance.hover,
  'editor_context_menu': instance.contextMenu,
  'editor_find': instance.find,
  'editor_seed_search_string_from_selection':
      instance.seedSearchStringFromSelection,
  'editor_accessibility_support':
      _$AccessibilitySupportEnumMap[instance.accessibilitySupport]!,
  'editor_accessibility_page_size': instance.accessibilityPageSize,
  'editor_render_validation_decorations': instance.renderValidationDecorations,
  'editor_render_control_characters': instance.renderControlCharacters,
  'editor_disable_layer_hinting': instance.disableLayerHinting,
  'editor_disable_monospace_optimizations':
      instance.disableMonospaceOptimizations,
  'editor_max_tokenization_line_length': instance.maxTokenizationLineLength,
  'editor_language_configs': instance.languageConfigs.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'editor_keybinding_preset':
      _$KeybindingPresetEnumEnumMap[instance.keybindingPreset]!,
  'editor_custom_keybindings': instance.customKeybindings,
  'editor_read_only': instance.readOnly,
  'editor_dom_read_only': instance.domReadOnly,
  'editor_drag_and_drop': instance.dragAndDrop,
  'editor_links': instance.links,
  'editor_mouse_wheel_zoom': instance.mouseWheelZoom,
  'editor_mouse_wheel_scroll_sensitivity': instance.mouseWheelScrollSensitivity,
  'editor_automatic_layout': instance.automaticLayout,
  'editor_padding': instance.padding,
  'editor_rounded_selection': instance.roundedSelection,
  'editor_selection_highlight': instance.selectionHighlight,
  'editor_occurrences_highlight': instance.occurrencesHighlight,
  'editor_overview_ruler_border': instance.overviewRulerBorder,
  'editor_hide_cursor_in_overview_ruler': instance.hideCursorInOverviewRuler,
  'editor_scrollbar': instance.scrollbar,
  'editor_experimental_features': instance.experimentalFeatures,
};

const _$LineNumbersStyleEnumMap = {
  LineNumbersStyle.off: 'off',
  LineNumbersStyle.on: 'on',
  LineNumbersStyle.relative: 'relative',
  LineNumbersStyle.interval: 'interval',
};

const _$MinimapSideEnumMap = {
  MinimapSide.left: 'left',
  MinimapSide.right: 'right',
};

const _$RenderWhitespaceEnumMap = {
  RenderWhitespace.none: 'none',
  RenderWhitespace.boundary: 'boundary',
  RenderWhitespace.selection: 'selection',
  RenderWhitespace.trailing: 'trailing',
  RenderWhitespace.all: 'all',
};

const _$CursorBlinkingEnumMap = {
  CursorBlinking.blink: 'blink',
  CursorBlinking.smooth: 'smooth',
  CursorBlinking.phase: 'phase',
  CursorBlinking.expand: 'expand',
  CursorBlinking.solid: 'solid',
};

const _$CursorStyleEnumMap = {
  CursorStyle.line: 'line',
  CursorStyle.block: 'block',
  CursorStyle.underline: 'underline',
  CursorStyle.lineThin: 'lineThin',
  CursorStyle.blockOutline: 'blockOutline',
  CursorStyle.underlineThin: 'underlineThin',
};

const _$MultiCursorModifierEnumMap = {
  MultiCursorModifier.ctrlCmd: 'ctrlCmd',
  MultiCursorModifier.alt: 'alt',
};

const _$AcceptSuggestionOnEnterEnumMap = {
  AcceptSuggestionOnEnter.on: 'on',
  AcceptSuggestionOnEnter.off: 'off',
  AcceptSuggestionOnEnter.smart: 'smart',
};

const _$SnippetSuggestionsEnumMap = {
  SnippetSuggestions.top: 'top',
  SnippetSuggestions.bottom: 'bottom',
  SnippetSuggestions.inline: 'inline',
  SnippetSuggestions.none: 'none',
};

const _$WordBasedSuggestionsEnumMap = {
  WordBasedSuggestions.off: 'off',
  WordBasedSuggestions.currentDocument: 'currentDocument',
  WordBasedSuggestions.matchingDocuments: 'matchingDocuments',
  WordBasedSuggestions.allDocuments: 'allDocuments',
};

const _$AccessibilitySupportEnumMap = {
  AccessibilitySupport.auto: 'auto',
  AccessibilitySupport.off: 'off',
  AccessibilitySupport.on: 'on',
};

const _$KeybindingPresetEnumEnumMap = {
  KeybindingPresetEnum.vscode: 'vscode',
  KeybindingPresetEnum.intellij: 'intellij',
  KeybindingPresetEnum.vim: 'vim',
  KeybindingPresetEnum.emacs: 'emacs',
  KeybindingPresetEnum.custom: 'custom',
};
