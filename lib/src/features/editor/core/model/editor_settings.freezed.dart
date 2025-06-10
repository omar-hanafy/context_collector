// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LanguageConfig {

 int? get tabSize; bool? get insertSpaces; WordWrap? get wordWrap; List<int> get rulers; bool? get formatOnSave; bool? get formatOnPaste; bool? get formatOnType; String? get autoClosingBrackets; String? get autoClosingQuotes; bool? get bracketPairColorization; Map<String, dynamic>? get customTheme;
/// Create a copy of LanguageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanguageConfigCopyWith<LanguageConfig> get copyWith => _$LanguageConfigCopyWithImpl<LanguageConfig>(this as LanguageConfig, _$identity);

  /// Serializes this LanguageConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanguageConfig&&(identical(other.tabSize, tabSize) || other.tabSize == tabSize)&&(identical(other.insertSpaces, insertSpaces) || other.insertSpaces == insertSpaces)&&(identical(other.wordWrap, wordWrap) || other.wordWrap == wordWrap)&&const DeepCollectionEquality().equals(other.rulers, rulers)&&(identical(other.formatOnSave, formatOnSave) || other.formatOnSave == formatOnSave)&&(identical(other.formatOnPaste, formatOnPaste) || other.formatOnPaste == formatOnPaste)&&(identical(other.formatOnType, formatOnType) || other.formatOnType == formatOnType)&&(identical(other.autoClosingBrackets, autoClosingBrackets) || other.autoClosingBrackets == autoClosingBrackets)&&(identical(other.autoClosingQuotes, autoClosingQuotes) || other.autoClosingQuotes == autoClosingQuotes)&&(identical(other.bracketPairColorization, bracketPairColorization) || other.bracketPairColorization == bracketPairColorization)&&const DeepCollectionEquality().equals(other.customTheme, customTheme));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tabSize,insertSpaces,wordWrap,const DeepCollectionEquality().hash(rulers),formatOnSave,formatOnPaste,formatOnType,autoClosingBrackets,autoClosingQuotes,bracketPairColorization,const DeepCollectionEquality().hash(customTheme));

@override
String toString() {
  return 'LanguageConfig(tabSize: $tabSize, insertSpaces: $insertSpaces, wordWrap: $wordWrap, rulers: $rulers, formatOnSave: $formatOnSave, formatOnPaste: $formatOnPaste, formatOnType: $formatOnType, autoClosingBrackets: $autoClosingBrackets, autoClosingQuotes: $autoClosingQuotes, bracketPairColorization: $bracketPairColorization, customTheme: $customTheme)';
}


}

/// @nodoc
abstract mixin class $LanguageConfigCopyWith<$Res>  {
  factory $LanguageConfigCopyWith(LanguageConfig value, $Res Function(LanguageConfig) _then) = _$LanguageConfigCopyWithImpl;
@useResult
$Res call({
 int? tabSize, bool? insertSpaces, WordWrap? wordWrap, List<int> rulers, bool? formatOnSave, bool? formatOnPaste, bool? formatOnType, String? autoClosingBrackets, String? autoClosingQuotes, bool? bracketPairColorization, Map<String, dynamic>? customTheme
});




}
/// @nodoc
class _$LanguageConfigCopyWithImpl<$Res>
    implements $LanguageConfigCopyWith<$Res> {
  _$LanguageConfigCopyWithImpl(this._self, this._then);

  final LanguageConfig _self;
  final $Res Function(LanguageConfig) _then;

/// Create a copy of LanguageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tabSize = freezed,Object? insertSpaces = freezed,Object? wordWrap = freezed,Object? rulers = null,Object? formatOnSave = freezed,Object? formatOnPaste = freezed,Object? formatOnType = freezed,Object? autoClosingBrackets = freezed,Object? autoClosingQuotes = freezed,Object? bracketPairColorization = freezed,Object? customTheme = freezed,}) {
  return _then(_self.copyWith(
tabSize: freezed == tabSize ? _self.tabSize : tabSize // ignore: cast_nullable_to_non_nullable
as int?,insertSpaces: freezed == insertSpaces ? _self.insertSpaces : insertSpaces // ignore: cast_nullable_to_non_nullable
as bool?,wordWrap: freezed == wordWrap ? _self.wordWrap : wordWrap // ignore: cast_nullable_to_non_nullable
as WordWrap?,rulers: null == rulers ? _self.rulers : rulers // ignore: cast_nullable_to_non_nullable
as List<int>,formatOnSave: freezed == formatOnSave ? _self.formatOnSave : formatOnSave // ignore: cast_nullable_to_non_nullable
as bool?,formatOnPaste: freezed == formatOnPaste ? _self.formatOnPaste : formatOnPaste // ignore: cast_nullable_to_non_nullable
as bool?,formatOnType: freezed == formatOnType ? _self.formatOnType : formatOnType // ignore: cast_nullable_to_non_nullable
as bool?,autoClosingBrackets: freezed == autoClosingBrackets ? _self.autoClosingBrackets : autoClosingBrackets // ignore: cast_nullable_to_non_nullable
as String?,autoClosingQuotes: freezed == autoClosingQuotes ? _self.autoClosingQuotes : autoClosingQuotes // ignore: cast_nullable_to_non_nullable
as String?,bracketPairColorization: freezed == bracketPairColorization ? _self.bracketPairColorization : bracketPairColorization // ignore: cast_nullable_to_non_nullable
as bool?,customTheme: freezed == customTheme ? _self.customTheme : customTheme // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _LanguageConfig implements LanguageConfig {
  const _LanguageConfig({this.tabSize, this.insertSpaces, this.wordWrap, final  List<int> rulers = const [], this.formatOnSave, this.formatOnPaste, this.formatOnType, this.autoClosingBrackets, this.autoClosingQuotes, this.bracketPairColorization, final  Map<String, dynamic>? customTheme}): _rulers = rulers,_customTheme = customTheme;
  factory _LanguageConfig.fromJson(Map<String, dynamic> json) => _$LanguageConfigFromJson(json);

@override final  int? tabSize;
@override final  bool? insertSpaces;
@override final  WordWrap? wordWrap;
 final  List<int> _rulers;
@override@JsonKey() List<int> get rulers {
  if (_rulers is EqualUnmodifiableListView) return _rulers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rulers);
}

@override final  bool? formatOnSave;
@override final  bool? formatOnPaste;
@override final  bool? formatOnType;
@override final  String? autoClosingBrackets;
@override final  String? autoClosingQuotes;
@override final  bool? bracketPairColorization;
 final  Map<String, dynamic>? _customTheme;
@override Map<String, dynamic>? get customTheme {
  final value = _customTheme;
  if (value == null) return null;
  if (_customTheme is EqualUnmodifiableMapView) return _customTheme;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of LanguageConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanguageConfigCopyWith<_LanguageConfig> get copyWith => __$LanguageConfigCopyWithImpl<_LanguageConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LanguageConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LanguageConfig&&(identical(other.tabSize, tabSize) || other.tabSize == tabSize)&&(identical(other.insertSpaces, insertSpaces) || other.insertSpaces == insertSpaces)&&(identical(other.wordWrap, wordWrap) || other.wordWrap == wordWrap)&&const DeepCollectionEquality().equals(other._rulers, _rulers)&&(identical(other.formatOnSave, formatOnSave) || other.formatOnSave == formatOnSave)&&(identical(other.formatOnPaste, formatOnPaste) || other.formatOnPaste == formatOnPaste)&&(identical(other.formatOnType, formatOnType) || other.formatOnType == formatOnType)&&(identical(other.autoClosingBrackets, autoClosingBrackets) || other.autoClosingBrackets == autoClosingBrackets)&&(identical(other.autoClosingQuotes, autoClosingQuotes) || other.autoClosingQuotes == autoClosingQuotes)&&(identical(other.bracketPairColorization, bracketPairColorization) || other.bracketPairColorization == bracketPairColorization)&&const DeepCollectionEquality().equals(other._customTheme, _customTheme));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tabSize,insertSpaces,wordWrap,const DeepCollectionEquality().hash(_rulers),formatOnSave,formatOnPaste,formatOnType,autoClosingBrackets,autoClosingQuotes,bracketPairColorization,const DeepCollectionEquality().hash(_customTheme));

@override
String toString() {
  return 'LanguageConfig(tabSize: $tabSize, insertSpaces: $insertSpaces, wordWrap: $wordWrap, rulers: $rulers, formatOnSave: $formatOnSave, formatOnPaste: $formatOnPaste, formatOnType: $formatOnType, autoClosingBrackets: $autoClosingBrackets, autoClosingQuotes: $autoClosingQuotes, bracketPairColorization: $bracketPairColorization, customTheme: $customTheme)';
}


}

/// @nodoc
abstract mixin class _$LanguageConfigCopyWith<$Res> implements $LanguageConfigCopyWith<$Res> {
  factory _$LanguageConfigCopyWith(_LanguageConfig value, $Res Function(_LanguageConfig) _then) = __$LanguageConfigCopyWithImpl;
@override @useResult
$Res call({
 int? tabSize, bool? insertSpaces, WordWrap? wordWrap, List<int> rulers, bool? formatOnSave, bool? formatOnPaste, bool? formatOnType, String? autoClosingBrackets, String? autoClosingQuotes, bool? bracketPairColorization, Map<String, dynamic>? customTheme
});




}
/// @nodoc
class __$LanguageConfigCopyWithImpl<$Res>
    implements _$LanguageConfigCopyWith<$Res> {
  __$LanguageConfigCopyWithImpl(this._self, this._then);

  final _LanguageConfig _self;
  final $Res Function(_LanguageConfig) _then;

/// Create a copy of LanguageConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tabSize = freezed,Object? insertSpaces = freezed,Object? wordWrap = freezed,Object? rulers = null,Object? formatOnSave = freezed,Object? formatOnPaste = freezed,Object? formatOnType = freezed,Object? autoClosingBrackets = freezed,Object? autoClosingQuotes = freezed,Object? bracketPairColorization = freezed,Object? customTheme = freezed,}) {
  return _then(_LanguageConfig(
tabSize: freezed == tabSize ? _self.tabSize : tabSize // ignore: cast_nullable_to_non_nullable
as int?,insertSpaces: freezed == insertSpaces ? _self.insertSpaces : insertSpaces // ignore: cast_nullable_to_non_nullable
as bool?,wordWrap: freezed == wordWrap ? _self.wordWrap : wordWrap // ignore: cast_nullable_to_non_nullable
as WordWrap?,rulers: null == rulers ? _self._rulers : rulers // ignore: cast_nullable_to_non_nullable
as List<int>,formatOnSave: freezed == formatOnSave ? _self.formatOnSave : formatOnSave // ignore: cast_nullable_to_non_nullable
as bool?,formatOnPaste: freezed == formatOnPaste ? _self.formatOnPaste : formatOnPaste // ignore: cast_nullable_to_non_nullable
as bool?,formatOnType: freezed == formatOnType ? _self.formatOnType : formatOnType // ignore: cast_nullable_to_non_nullable
as bool?,autoClosingBrackets: freezed == autoClosingBrackets ? _self.autoClosingBrackets : autoClosingBrackets // ignore: cast_nullable_to_non_nullable
as String?,autoClosingQuotes: freezed == autoClosingQuotes ? _self.autoClosingQuotes : autoClosingQuotes // ignore: cast_nullable_to_non_nullable
as String?,bracketPairColorization: freezed == bracketPairColorization ? _self.bracketPairColorization : bracketPairColorization // ignore: cast_nullable_to_non_nullable
as bool?,customTheme: freezed == customTheme ? _self._customTheme : customTheme // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$EditorSettings {

// General Settings
@JsonKey(name: 'editor_theme') String get theme;@JsonKey(name: 'editor_font_size') double get fontSize;@JsonKey(name: 'editor_font_family') String get fontFamily;@JsonKey(name: 'editor_line_height') double get lineHeight;@JsonKey(name: 'editor_letter_spacing') double get letterSpacing;// Display Settings
@JsonKey(name: 'editor_show_line_numbers') bool get showLineNumbers;@JsonKey(name: 'editor_line_numbers_style') LineNumbersStyle get lineNumbersStyle;@JsonKey(name: 'editor_show_minimap') bool get showMinimap;@JsonKey(name: 'editor_minimap_side') MinimapSide get minimapSide;@JsonKey(name: 'editor_minimap_render_characters') bool get minimapRenderCharacters;@JsonKey(name: 'editor_minimap_size') int get minimapSize;@JsonKey(name: 'editor_show_indent_guides') bool get showIndentGuides;@JsonKey(name: 'editor_render_whitespace') RenderWhitespace get renderWhitespace;@JsonKey(name: 'editor_rulers') List<int> get rulers;@JsonKey(name: 'editor_sticky_scroll') bool get stickyScroll;@JsonKey(name: 'editor_show_folding_controls') String get showFoldingControls;@JsonKey(name: 'editor_glyph_margin') bool get glyphMargin;@JsonKey(name: 'editor_render_line_highlight') String get renderLineHighlight;// Editor Behavior
@JsonKey(name: 'editor_word_wrap') WordWrap get wordWrap;@JsonKey(name: 'editor_word_wrap_column') int get wordWrapColumn;@JsonKey(name: 'editor_tab_size') int get tabSize;@JsonKey(name: 'editor_insert_spaces') bool get insertSpaces;@JsonKey(name: 'editor_auto_indent') String get autoIndent;@JsonKey(name: 'editor_auto_closing_brackets') String get autoClosingBrackets;@JsonKey(name: 'editor_auto_closing_quotes') String get autoClosingQuotes;@JsonKey(name: 'editor_auto_surround') String get autoSurround;@JsonKey(name: 'editor_bracket_pair_colorization') bool get bracketPairColorization;@JsonKey(name: 'editor_code_folding') bool get codeFolding;@JsonKey(name: 'editor_scroll_beyond_last_line') bool get scrollBeyondLastLine;@JsonKey(name: 'editor_smooth_scrolling') bool get smoothScrolling;@JsonKey(name: 'editor_fast_scroll_sensitivity') double get fastScrollSensitivity;@JsonKey(name: 'editor_scroll_predominant_axis') bool get scrollPredominantAxis;// Cursor Settings
@JsonKey(name: 'editor_cursor_blinking') CursorBlinking get cursorBlinking;@JsonKey(name: 'editor_cursor_smooth_caret_animation') String get cursorSmoothCaretAnimation;@JsonKey(name: 'editor_cursor_style') CursorStyle get cursorStyle;@JsonKey(name: 'editor_cursor_width') int get cursorWidth;@JsonKey(name: 'editor_multi_cursor_modifier') MultiCursorModifier get multiCursorModifier;@JsonKey(name: 'editor_multi_cursor_merge_overlapping') bool get multiCursorMergeOverlapping;// Editing Features
@JsonKey(name: 'editor_format_on_save') bool get formatOnSave;@JsonKey(name: 'editor_format_on_paste') bool get formatOnPaste;@JsonKey(name: 'editor_format_on_type') bool get formatOnType;@JsonKey(name: 'editor_quick_suggestions') bool get quickSuggestions;@JsonKey(name: 'editor_quick_suggestions_delay') int get quickSuggestionsDelay;@JsonKey(name: 'editor_suggest_on_trigger_characters') bool get suggestOnTriggerCharacters;@JsonKey(name: 'editor_accept_suggestion_on_enter') AcceptSuggestionOnEnter get acceptSuggestionOnEnter;@JsonKey(name: 'editor_accept_suggestion_on_commit_character') bool get acceptSuggestionOnCommitCharacter;@JsonKey(name: 'editor_snippet_suggestions') SnippetSuggestions get snippetSuggestions;@JsonKey(name: 'editor_word_based_suggestions') WordBasedSuggestions get wordBasedSuggestions;@JsonKey(name: 'editor_parameter_hints') bool get parameterHints;@JsonKey(name: 'editor_hover') bool get hover;@JsonKey(name: 'editor_context_menu') bool get contextMenu;// Find & Replace
@JsonKey(name: 'editor_find') bool get find;@JsonKey(name: 'editor_seed_search_string_from_selection') String get seedSearchStringFromSelection;// Accessibility
@JsonKey(name: 'editor_accessibility_support') AccessibilitySupport get accessibilitySupport;@JsonKey(name: 'editor_accessibility_page_size') int get accessibilityPageSize;// Performance
@JsonKey(name: 'editor_render_validation_decorations') String get renderValidationDecorations;@JsonKey(name: 'editor_render_control_characters') bool get renderControlCharacters;@JsonKey(name: 'editor_disable_layer_hinting') bool get disableLayerHinting;@JsonKey(name: 'editor_disable_monospace_optimizations') bool get disableMonospaceOptimizations;@JsonKey(name: 'editor_max_tokenization_line_length') int get maxTokenizationLineLength;// Language Specific
@JsonKey(name: 'editor_language_configs') Map<String, LanguageConfig> get languageConfigs;// Keybindings
@JsonKey(name: 'editor_keybinding_preset') KeybindingPresetEnum get keybindingPreset;@JsonKey(name: 'editor_custom_keybindings') Map<String, String> get customKeybindings;// Advanced
@JsonKey(name: 'editor_read_only') bool get readOnly;@JsonKey(name: 'editor_dom_read_only') bool get domReadOnly;@JsonKey(name: 'editor_drag_and_drop') bool get dragAndDrop;@JsonKey(name: 'editor_links') bool get links;@JsonKey(name: 'editor_mouse_wheel_zoom') bool get mouseWheelZoom;@JsonKey(name: 'editor_mouse_wheel_scroll_sensitivity') double get mouseWheelScrollSensitivity;@JsonKey(name: 'editor_automatic_layout') bool get automaticLayout;@JsonKey(name: 'editor_padding') Map<String, int> get padding;@JsonKey(name: 'editor_rounded_selection') bool get roundedSelection;@JsonKey(name: 'editor_selection_highlight') bool get selectionHighlight;@JsonKey(name: 'editor_occurrences_highlight') String get occurrencesHighlight;@JsonKey(name: 'editor_overview_ruler_border') bool get overviewRulerBorder;@JsonKey(name: 'editor_hide_cursor_in_overview_ruler') bool get hideCursorInOverviewRuler;@JsonKey(name: 'editor_scrollbar') Map<String, dynamic> get scrollbar;@JsonKey(name: 'editor_experimental_features') Map<String, dynamic> get experimentalFeatures;
/// Create a copy of EditorSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorSettingsCopyWith<EditorSettings> get copyWith => _$EditorSettingsCopyWithImpl<EditorSettings>(this as EditorSettings, _$identity);

  /// Serializes this EditorSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorSettings&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.lineHeight, lineHeight) || other.lineHeight == lineHeight)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.showLineNumbers, showLineNumbers) || other.showLineNumbers == showLineNumbers)&&(identical(other.lineNumbersStyle, lineNumbersStyle) || other.lineNumbersStyle == lineNumbersStyle)&&(identical(other.showMinimap, showMinimap) || other.showMinimap == showMinimap)&&(identical(other.minimapSide, minimapSide) || other.minimapSide == minimapSide)&&(identical(other.minimapRenderCharacters, minimapRenderCharacters) || other.minimapRenderCharacters == minimapRenderCharacters)&&(identical(other.minimapSize, minimapSize) || other.minimapSize == minimapSize)&&(identical(other.showIndentGuides, showIndentGuides) || other.showIndentGuides == showIndentGuides)&&(identical(other.renderWhitespace, renderWhitespace) || other.renderWhitespace == renderWhitespace)&&const DeepCollectionEquality().equals(other.rulers, rulers)&&(identical(other.stickyScroll, stickyScroll) || other.stickyScroll == stickyScroll)&&(identical(other.showFoldingControls, showFoldingControls) || other.showFoldingControls == showFoldingControls)&&(identical(other.glyphMargin, glyphMargin) || other.glyphMargin == glyphMargin)&&(identical(other.renderLineHighlight, renderLineHighlight) || other.renderLineHighlight == renderLineHighlight)&&(identical(other.wordWrap, wordWrap) || other.wordWrap == wordWrap)&&(identical(other.wordWrapColumn, wordWrapColumn) || other.wordWrapColumn == wordWrapColumn)&&(identical(other.tabSize, tabSize) || other.tabSize == tabSize)&&(identical(other.insertSpaces, insertSpaces) || other.insertSpaces == insertSpaces)&&(identical(other.autoIndent, autoIndent) || other.autoIndent == autoIndent)&&(identical(other.autoClosingBrackets, autoClosingBrackets) || other.autoClosingBrackets == autoClosingBrackets)&&(identical(other.autoClosingQuotes, autoClosingQuotes) || other.autoClosingQuotes == autoClosingQuotes)&&(identical(other.autoSurround, autoSurround) || other.autoSurround == autoSurround)&&(identical(other.bracketPairColorization, bracketPairColorization) || other.bracketPairColorization == bracketPairColorization)&&(identical(other.codeFolding, codeFolding) || other.codeFolding == codeFolding)&&(identical(other.scrollBeyondLastLine, scrollBeyondLastLine) || other.scrollBeyondLastLine == scrollBeyondLastLine)&&(identical(other.smoothScrolling, smoothScrolling) || other.smoothScrolling == smoothScrolling)&&(identical(other.fastScrollSensitivity, fastScrollSensitivity) || other.fastScrollSensitivity == fastScrollSensitivity)&&(identical(other.scrollPredominantAxis, scrollPredominantAxis) || other.scrollPredominantAxis == scrollPredominantAxis)&&(identical(other.cursorBlinking, cursorBlinking) || other.cursorBlinking == cursorBlinking)&&(identical(other.cursorSmoothCaretAnimation, cursorSmoothCaretAnimation) || other.cursorSmoothCaretAnimation == cursorSmoothCaretAnimation)&&(identical(other.cursorStyle, cursorStyle) || other.cursorStyle == cursorStyle)&&(identical(other.cursorWidth, cursorWidth) || other.cursorWidth == cursorWidth)&&(identical(other.multiCursorModifier, multiCursorModifier) || other.multiCursorModifier == multiCursorModifier)&&(identical(other.multiCursorMergeOverlapping, multiCursorMergeOverlapping) || other.multiCursorMergeOverlapping == multiCursorMergeOverlapping)&&(identical(other.formatOnSave, formatOnSave) || other.formatOnSave == formatOnSave)&&(identical(other.formatOnPaste, formatOnPaste) || other.formatOnPaste == formatOnPaste)&&(identical(other.formatOnType, formatOnType) || other.formatOnType == formatOnType)&&(identical(other.quickSuggestions, quickSuggestions) || other.quickSuggestions == quickSuggestions)&&(identical(other.quickSuggestionsDelay, quickSuggestionsDelay) || other.quickSuggestionsDelay == quickSuggestionsDelay)&&(identical(other.suggestOnTriggerCharacters, suggestOnTriggerCharacters) || other.suggestOnTriggerCharacters == suggestOnTriggerCharacters)&&(identical(other.acceptSuggestionOnEnter, acceptSuggestionOnEnter) || other.acceptSuggestionOnEnter == acceptSuggestionOnEnter)&&(identical(other.acceptSuggestionOnCommitCharacter, acceptSuggestionOnCommitCharacter) || other.acceptSuggestionOnCommitCharacter == acceptSuggestionOnCommitCharacter)&&(identical(other.snippetSuggestions, snippetSuggestions) || other.snippetSuggestions == snippetSuggestions)&&(identical(other.wordBasedSuggestions, wordBasedSuggestions) || other.wordBasedSuggestions == wordBasedSuggestions)&&(identical(other.parameterHints, parameterHints) || other.parameterHints == parameterHints)&&(identical(other.hover, hover) || other.hover == hover)&&(identical(other.contextMenu, contextMenu) || other.contextMenu == contextMenu)&&(identical(other.find, find) || other.find == find)&&(identical(other.seedSearchStringFromSelection, seedSearchStringFromSelection) || other.seedSearchStringFromSelection == seedSearchStringFromSelection)&&(identical(other.accessibilitySupport, accessibilitySupport) || other.accessibilitySupport == accessibilitySupport)&&(identical(other.accessibilityPageSize, accessibilityPageSize) || other.accessibilityPageSize == accessibilityPageSize)&&(identical(other.renderValidationDecorations, renderValidationDecorations) || other.renderValidationDecorations == renderValidationDecorations)&&(identical(other.renderControlCharacters, renderControlCharacters) || other.renderControlCharacters == renderControlCharacters)&&(identical(other.disableLayerHinting, disableLayerHinting) || other.disableLayerHinting == disableLayerHinting)&&(identical(other.disableMonospaceOptimizations, disableMonospaceOptimizations) || other.disableMonospaceOptimizations == disableMonospaceOptimizations)&&(identical(other.maxTokenizationLineLength, maxTokenizationLineLength) || other.maxTokenizationLineLength == maxTokenizationLineLength)&&const DeepCollectionEquality().equals(other.languageConfigs, languageConfigs)&&(identical(other.keybindingPreset, keybindingPreset) || other.keybindingPreset == keybindingPreset)&&const DeepCollectionEquality().equals(other.customKeybindings, customKeybindings)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.domReadOnly, domReadOnly) || other.domReadOnly == domReadOnly)&&(identical(other.dragAndDrop, dragAndDrop) || other.dragAndDrop == dragAndDrop)&&(identical(other.links, links) || other.links == links)&&(identical(other.mouseWheelZoom, mouseWheelZoom) || other.mouseWheelZoom == mouseWheelZoom)&&(identical(other.mouseWheelScrollSensitivity, mouseWheelScrollSensitivity) || other.mouseWheelScrollSensitivity == mouseWheelScrollSensitivity)&&(identical(other.automaticLayout, automaticLayout) || other.automaticLayout == automaticLayout)&&const DeepCollectionEquality().equals(other.padding, padding)&&(identical(other.roundedSelection, roundedSelection) || other.roundedSelection == roundedSelection)&&(identical(other.selectionHighlight, selectionHighlight) || other.selectionHighlight == selectionHighlight)&&(identical(other.occurrencesHighlight, occurrencesHighlight) || other.occurrencesHighlight == occurrencesHighlight)&&(identical(other.overviewRulerBorder, overviewRulerBorder) || other.overviewRulerBorder == overviewRulerBorder)&&(identical(other.hideCursorInOverviewRuler, hideCursorInOverviewRuler) || other.hideCursorInOverviewRuler == hideCursorInOverviewRuler)&&const DeepCollectionEquality().equals(other.scrollbar, scrollbar)&&const DeepCollectionEquality().equals(other.experimentalFeatures, experimentalFeatures));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,theme,fontSize,fontFamily,lineHeight,letterSpacing,showLineNumbers,lineNumbersStyle,showMinimap,minimapSide,minimapRenderCharacters,minimapSize,showIndentGuides,renderWhitespace,const DeepCollectionEquality().hash(rulers),stickyScroll,showFoldingControls,glyphMargin,renderLineHighlight,wordWrap,wordWrapColumn,tabSize,insertSpaces,autoIndent,autoClosingBrackets,autoClosingQuotes,autoSurround,bracketPairColorization,codeFolding,scrollBeyondLastLine,smoothScrolling,fastScrollSensitivity,scrollPredominantAxis,cursorBlinking,cursorSmoothCaretAnimation,cursorStyle,cursorWidth,multiCursorModifier,multiCursorMergeOverlapping,formatOnSave,formatOnPaste,formatOnType,quickSuggestions,quickSuggestionsDelay,suggestOnTriggerCharacters,acceptSuggestionOnEnter,acceptSuggestionOnCommitCharacter,snippetSuggestions,wordBasedSuggestions,parameterHints,hover,contextMenu,find,seedSearchStringFromSelection,accessibilitySupport,accessibilityPageSize,renderValidationDecorations,renderControlCharacters,disableLayerHinting,disableMonospaceOptimizations,maxTokenizationLineLength,const DeepCollectionEquality().hash(languageConfigs),keybindingPreset,const DeepCollectionEquality().hash(customKeybindings),readOnly,domReadOnly,dragAndDrop,links,mouseWheelZoom,mouseWheelScrollSensitivity,automaticLayout,const DeepCollectionEquality().hash(padding),roundedSelection,selectionHighlight,occurrencesHighlight,overviewRulerBorder,hideCursorInOverviewRuler,const DeepCollectionEquality().hash(scrollbar),const DeepCollectionEquality().hash(experimentalFeatures)]);

@override
String toString() {
  return 'EditorSettings(theme: $theme, fontSize: $fontSize, fontFamily: $fontFamily, lineHeight: $lineHeight, letterSpacing: $letterSpacing, showLineNumbers: $showLineNumbers, lineNumbersStyle: $lineNumbersStyle, showMinimap: $showMinimap, minimapSide: $minimapSide, minimapRenderCharacters: $minimapRenderCharacters, minimapSize: $minimapSize, showIndentGuides: $showIndentGuides, renderWhitespace: $renderWhitespace, rulers: $rulers, stickyScroll: $stickyScroll, showFoldingControls: $showFoldingControls, glyphMargin: $glyphMargin, renderLineHighlight: $renderLineHighlight, wordWrap: $wordWrap, wordWrapColumn: $wordWrapColumn, tabSize: $tabSize, insertSpaces: $insertSpaces, autoIndent: $autoIndent, autoClosingBrackets: $autoClosingBrackets, autoClosingQuotes: $autoClosingQuotes, autoSurround: $autoSurround, bracketPairColorization: $bracketPairColorization, codeFolding: $codeFolding, scrollBeyondLastLine: $scrollBeyondLastLine, smoothScrolling: $smoothScrolling, fastScrollSensitivity: $fastScrollSensitivity, scrollPredominantAxis: $scrollPredominantAxis, cursorBlinking: $cursorBlinking, cursorSmoothCaretAnimation: $cursorSmoothCaretAnimation, cursorStyle: $cursorStyle, cursorWidth: $cursorWidth, multiCursorModifier: $multiCursorModifier, multiCursorMergeOverlapping: $multiCursorMergeOverlapping, formatOnSave: $formatOnSave, formatOnPaste: $formatOnPaste, formatOnType: $formatOnType, quickSuggestions: $quickSuggestions, quickSuggestionsDelay: $quickSuggestionsDelay, suggestOnTriggerCharacters: $suggestOnTriggerCharacters, acceptSuggestionOnEnter: $acceptSuggestionOnEnter, acceptSuggestionOnCommitCharacter: $acceptSuggestionOnCommitCharacter, snippetSuggestions: $snippetSuggestions, wordBasedSuggestions: $wordBasedSuggestions, parameterHints: $parameterHints, hover: $hover, contextMenu: $contextMenu, find: $find, seedSearchStringFromSelection: $seedSearchStringFromSelection, accessibilitySupport: $accessibilitySupport, accessibilityPageSize: $accessibilityPageSize, renderValidationDecorations: $renderValidationDecorations, renderControlCharacters: $renderControlCharacters, disableLayerHinting: $disableLayerHinting, disableMonospaceOptimizations: $disableMonospaceOptimizations, maxTokenizationLineLength: $maxTokenizationLineLength, languageConfigs: $languageConfigs, keybindingPreset: $keybindingPreset, customKeybindings: $customKeybindings, readOnly: $readOnly, domReadOnly: $domReadOnly, dragAndDrop: $dragAndDrop, links: $links, mouseWheelZoom: $mouseWheelZoom, mouseWheelScrollSensitivity: $mouseWheelScrollSensitivity, automaticLayout: $automaticLayout, padding: $padding, roundedSelection: $roundedSelection, selectionHighlight: $selectionHighlight, occurrencesHighlight: $occurrencesHighlight, overviewRulerBorder: $overviewRulerBorder, hideCursorInOverviewRuler: $hideCursorInOverviewRuler, scrollbar: $scrollbar, experimentalFeatures: $experimentalFeatures)';
}


}

/// @nodoc
abstract mixin class $EditorSettingsCopyWith<$Res>  {
  factory $EditorSettingsCopyWith(EditorSettings value, $Res Function(EditorSettings) _then) = _$EditorSettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'editor_theme') String theme,@JsonKey(name: 'editor_font_size') double fontSize,@JsonKey(name: 'editor_font_family') String fontFamily,@JsonKey(name: 'editor_line_height') double lineHeight,@JsonKey(name: 'editor_letter_spacing') double letterSpacing,@JsonKey(name: 'editor_show_line_numbers') bool showLineNumbers,@JsonKey(name: 'editor_line_numbers_style') LineNumbersStyle lineNumbersStyle,@JsonKey(name: 'editor_show_minimap') bool showMinimap,@JsonKey(name: 'editor_minimap_side') MinimapSide minimapSide,@JsonKey(name: 'editor_minimap_render_characters') bool minimapRenderCharacters,@JsonKey(name: 'editor_minimap_size') int minimapSize,@JsonKey(name: 'editor_show_indent_guides') bool showIndentGuides,@JsonKey(name: 'editor_render_whitespace') RenderWhitespace renderWhitespace,@JsonKey(name: 'editor_rulers') List<int> rulers,@JsonKey(name: 'editor_sticky_scroll') bool stickyScroll,@JsonKey(name: 'editor_show_folding_controls') String showFoldingControls,@JsonKey(name: 'editor_glyph_margin') bool glyphMargin,@JsonKey(name: 'editor_render_line_highlight') String renderLineHighlight,@JsonKey(name: 'editor_word_wrap') WordWrap wordWrap,@JsonKey(name: 'editor_word_wrap_column') int wordWrapColumn,@JsonKey(name: 'editor_tab_size') int tabSize,@JsonKey(name: 'editor_insert_spaces') bool insertSpaces,@JsonKey(name: 'editor_auto_indent') String autoIndent,@JsonKey(name: 'editor_auto_closing_brackets') String autoClosingBrackets,@JsonKey(name: 'editor_auto_closing_quotes') String autoClosingQuotes,@JsonKey(name: 'editor_auto_surround') String autoSurround,@JsonKey(name: 'editor_bracket_pair_colorization') bool bracketPairColorization,@JsonKey(name: 'editor_code_folding') bool codeFolding,@JsonKey(name: 'editor_scroll_beyond_last_line') bool scrollBeyondLastLine,@JsonKey(name: 'editor_smooth_scrolling') bool smoothScrolling,@JsonKey(name: 'editor_fast_scroll_sensitivity') double fastScrollSensitivity,@JsonKey(name: 'editor_scroll_predominant_axis') bool scrollPredominantAxis,@JsonKey(name: 'editor_cursor_blinking') CursorBlinking cursorBlinking,@JsonKey(name: 'editor_cursor_smooth_caret_animation') String cursorSmoothCaretAnimation,@JsonKey(name: 'editor_cursor_style') CursorStyle cursorStyle,@JsonKey(name: 'editor_cursor_width') int cursorWidth,@JsonKey(name: 'editor_multi_cursor_modifier') MultiCursorModifier multiCursorModifier,@JsonKey(name: 'editor_multi_cursor_merge_overlapping') bool multiCursorMergeOverlapping,@JsonKey(name: 'editor_format_on_save') bool formatOnSave,@JsonKey(name: 'editor_format_on_paste') bool formatOnPaste,@JsonKey(name: 'editor_format_on_type') bool formatOnType,@JsonKey(name: 'editor_quick_suggestions') bool quickSuggestions,@JsonKey(name: 'editor_quick_suggestions_delay') int quickSuggestionsDelay,@JsonKey(name: 'editor_suggest_on_trigger_characters') bool suggestOnTriggerCharacters,@JsonKey(name: 'editor_accept_suggestion_on_enter') AcceptSuggestionOnEnter acceptSuggestionOnEnter,@JsonKey(name: 'editor_accept_suggestion_on_commit_character') bool acceptSuggestionOnCommitCharacter,@JsonKey(name: 'editor_snippet_suggestions') SnippetSuggestions snippetSuggestions,@JsonKey(name: 'editor_word_based_suggestions') WordBasedSuggestions wordBasedSuggestions,@JsonKey(name: 'editor_parameter_hints') bool parameterHints,@JsonKey(name: 'editor_hover') bool hover,@JsonKey(name: 'editor_context_menu') bool contextMenu,@JsonKey(name: 'editor_find') bool find,@JsonKey(name: 'editor_seed_search_string_from_selection') String seedSearchStringFromSelection,@JsonKey(name: 'editor_accessibility_support') AccessibilitySupport accessibilitySupport,@JsonKey(name: 'editor_accessibility_page_size') int accessibilityPageSize,@JsonKey(name: 'editor_render_validation_decorations') String renderValidationDecorations,@JsonKey(name: 'editor_render_control_characters') bool renderControlCharacters,@JsonKey(name: 'editor_disable_layer_hinting') bool disableLayerHinting,@JsonKey(name: 'editor_disable_monospace_optimizations') bool disableMonospaceOptimizations,@JsonKey(name: 'editor_max_tokenization_line_length') int maxTokenizationLineLength,@JsonKey(name: 'editor_language_configs') Map<String, LanguageConfig> languageConfigs,@JsonKey(name: 'editor_keybinding_preset') KeybindingPresetEnum keybindingPreset,@JsonKey(name: 'editor_custom_keybindings') Map<String, String> customKeybindings,@JsonKey(name: 'editor_read_only') bool readOnly,@JsonKey(name: 'editor_dom_read_only') bool domReadOnly,@JsonKey(name: 'editor_drag_and_drop') bool dragAndDrop,@JsonKey(name: 'editor_links') bool links,@JsonKey(name: 'editor_mouse_wheel_zoom') bool mouseWheelZoom,@JsonKey(name: 'editor_mouse_wheel_scroll_sensitivity') double mouseWheelScrollSensitivity,@JsonKey(name: 'editor_automatic_layout') bool automaticLayout,@JsonKey(name: 'editor_padding') Map<String, int> padding,@JsonKey(name: 'editor_rounded_selection') bool roundedSelection,@JsonKey(name: 'editor_selection_highlight') bool selectionHighlight,@JsonKey(name: 'editor_occurrences_highlight') String occurrencesHighlight,@JsonKey(name: 'editor_overview_ruler_border') bool overviewRulerBorder,@JsonKey(name: 'editor_hide_cursor_in_overview_ruler') bool hideCursorInOverviewRuler,@JsonKey(name: 'editor_scrollbar') Map<String, dynamic> scrollbar,@JsonKey(name: 'editor_experimental_features') Map<String, dynamic> experimentalFeatures
});




}
/// @nodoc
class _$EditorSettingsCopyWithImpl<$Res>
    implements $EditorSettingsCopyWith<$Res> {
  _$EditorSettingsCopyWithImpl(this._self, this._then);

  final EditorSettings _self;
  final $Res Function(EditorSettings) _then;

/// Create a copy of EditorSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? fontSize = null,Object? fontFamily = null,Object? lineHeight = null,Object? letterSpacing = null,Object? showLineNumbers = null,Object? lineNumbersStyle = null,Object? showMinimap = null,Object? minimapSide = null,Object? minimapRenderCharacters = null,Object? minimapSize = null,Object? showIndentGuides = null,Object? renderWhitespace = null,Object? rulers = null,Object? stickyScroll = null,Object? showFoldingControls = null,Object? glyphMargin = null,Object? renderLineHighlight = null,Object? wordWrap = null,Object? wordWrapColumn = null,Object? tabSize = null,Object? insertSpaces = null,Object? autoIndent = null,Object? autoClosingBrackets = null,Object? autoClosingQuotes = null,Object? autoSurround = null,Object? bracketPairColorization = null,Object? codeFolding = null,Object? scrollBeyondLastLine = null,Object? smoothScrolling = null,Object? fastScrollSensitivity = null,Object? scrollPredominantAxis = null,Object? cursorBlinking = null,Object? cursorSmoothCaretAnimation = null,Object? cursorStyle = null,Object? cursorWidth = null,Object? multiCursorModifier = null,Object? multiCursorMergeOverlapping = null,Object? formatOnSave = null,Object? formatOnPaste = null,Object? formatOnType = null,Object? quickSuggestions = null,Object? quickSuggestionsDelay = null,Object? suggestOnTriggerCharacters = null,Object? acceptSuggestionOnEnter = null,Object? acceptSuggestionOnCommitCharacter = null,Object? snippetSuggestions = null,Object? wordBasedSuggestions = null,Object? parameterHints = null,Object? hover = null,Object? contextMenu = null,Object? find = null,Object? seedSearchStringFromSelection = null,Object? accessibilitySupport = null,Object? accessibilityPageSize = null,Object? renderValidationDecorations = null,Object? renderControlCharacters = null,Object? disableLayerHinting = null,Object? disableMonospaceOptimizations = null,Object? maxTokenizationLineLength = null,Object? languageConfigs = null,Object? keybindingPreset = null,Object? customKeybindings = null,Object? readOnly = null,Object? domReadOnly = null,Object? dragAndDrop = null,Object? links = null,Object? mouseWheelZoom = null,Object? mouseWheelScrollSensitivity = null,Object? automaticLayout = null,Object? padding = null,Object? roundedSelection = null,Object? selectionHighlight = null,Object? occurrencesHighlight = null,Object? overviewRulerBorder = null,Object? hideCursorInOverviewRuler = null,Object? scrollbar = null,Object? experimentalFeatures = null,}) {
  return _then(_self.copyWith(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,lineHeight: null == lineHeight ? _self.lineHeight : lineHeight // ignore: cast_nullable_to_non_nullable
as double,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double,showLineNumbers: null == showLineNumbers ? _self.showLineNumbers : showLineNumbers // ignore: cast_nullable_to_non_nullable
as bool,lineNumbersStyle: null == lineNumbersStyle ? _self.lineNumbersStyle : lineNumbersStyle // ignore: cast_nullable_to_non_nullable
as LineNumbersStyle,showMinimap: null == showMinimap ? _self.showMinimap : showMinimap // ignore: cast_nullable_to_non_nullable
as bool,minimapSide: null == minimapSide ? _self.minimapSide : minimapSide // ignore: cast_nullable_to_non_nullable
as MinimapSide,minimapRenderCharacters: null == minimapRenderCharacters ? _self.minimapRenderCharacters : minimapRenderCharacters // ignore: cast_nullable_to_non_nullable
as bool,minimapSize: null == minimapSize ? _self.minimapSize : minimapSize // ignore: cast_nullable_to_non_nullable
as int,showIndentGuides: null == showIndentGuides ? _self.showIndentGuides : showIndentGuides // ignore: cast_nullable_to_non_nullable
as bool,renderWhitespace: null == renderWhitespace ? _self.renderWhitespace : renderWhitespace // ignore: cast_nullable_to_non_nullable
as RenderWhitespace,rulers: null == rulers ? _self.rulers : rulers // ignore: cast_nullable_to_non_nullable
as List<int>,stickyScroll: null == stickyScroll ? _self.stickyScroll : stickyScroll // ignore: cast_nullable_to_non_nullable
as bool,showFoldingControls: null == showFoldingControls ? _self.showFoldingControls : showFoldingControls // ignore: cast_nullable_to_non_nullable
as String,glyphMargin: null == glyphMargin ? _self.glyphMargin : glyphMargin // ignore: cast_nullable_to_non_nullable
as bool,renderLineHighlight: null == renderLineHighlight ? _self.renderLineHighlight : renderLineHighlight // ignore: cast_nullable_to_non_nullable
as String,wordWrap: null == wordWrap ? _self.wordWrap : wordWrap // ignore: cast_nullable_to_non_nullable
as WordWrap,wordWrapColumn: null == wordWrapColumn ? _self.wordWrapColumn : wordWrapColumn // ignore: cast_nullable_to_non_nullable
as int,tabSize: null == tabSize ? _self.tabSize : tabSize // ignore: cast_nullable_to_non_nullable
as int,insertSpaces: null == insertSpaces ? _self.insertSpaces : insertSpaces // ignore: cast_nullable_to_non_nullable
as bool,autoIndent: null == autoIndent ? _self.autoIndent : autoIndent // ignore: cast_nullable_to_non_nullable
as String,autoClosingBrackets: null == autoClosingBrackets ? _self.autoClosingBrackets : autoClosingBrackets // ignore: cast_nullable_to_non_nullable
as String,autoClosingQuotes: null == autoClosingQuotes ? _self.autoClosingQuotes : autoClosingQuotes // ignore: cast_nullable_to_non_nullable
as String,autoSurround: null == autoSurround ? _self.autoSurround : autoSurround // ignore: cast_nullable_to_non_nullable
as String,bracketPairColorization: null == bracketPairColorization ? _self.bracketPairColorization : bracketPairColorization // ignore: cast_nullable_to_non_nullable
as bool,codeFolding: null == codeFolding ? _self.codeFolding : codeFolding // ignore: cast_nullable_to_non_nullable
as bool,scrollBeyondLastLine: null == scrollBeyondLastLine ? _self.scrollBeyondLastLine : scrollBeyondLastLine // ignore: cast_nullable_to_non_nullable
as bool,smoothScrolling: null == smoothScrolling ? _self.smoothScrolling : smoothScrolling // ignore: cast_nullable_to_non_nullable
as bool,fastScrollSensitivity: null == fastScrollSensitivity ? _self.fastScrollSensitivity : fastScrollSensitivity // ignore: cast_nullable_to_non_nullable
as double,scrollPredominantAxis: null == scrollPredominantAxis ? _self.scrollPredominantAxis : scrollPredominantAxis // ignore: cast_nullable_to_non_nullable
as bool,cursorBlinking: null == cursorBlinking ? _self.cursorBlinking : cursorBlinking // ignore: cast_nullable_to_non_nullable
as CursorBlinking,cursorSmoothCaretAnimation: null == cursorSmoothCaretAnimation ? _self.cursorSmoothCaretAnimation : cursorSmoothCaretAnimation // ignore: cast_nullable_to_non_nullable
as String,cursorStyle: null == cursorStyle ? _self.cursorStyle : cursorStyle // ignore: cast_nullable_to_non_nullable
as CursorStyle,cursorWidth: null == cursorWidth ? _self.cursorWidth : cursorWidth // ignore: cast_nullable_to_non_nullable
as int,multiCursorModifier: null == multiCursorModifier ? _self.multiCursorModifier : multiCursorModifier // ignore: cast_nullable_to_non_nullable
as MultiCursorModifier,multiCursorMergeOverlapping: null == multiCursorMergeOverlapping ? _self.multiCursorMergeOverlapping : multiCursorMergeOverlapping // ignore: cast_nullable_to_non_nullable
as bool,formatOnSave: null == formatOnSave ? _self.formatOnSave : formatOnSave // ignore: cast_nullable_to_non_nullable
as bool,formatOnPaste: null == formatOnPaste ? _self.formatOnPaste : formatOnPaste // ignore: cast_nullable_to_non_nullable
as bool,formatOnType: null == formatOnType ? _self.formatOnType : formatOnType // ignore: cast_nullable_to_non_nullable
as bool,quickSuggestions: null == quickSuggestions ? _self.quickSuggestions : quickSuggestions // ignore: cast_nullable_to_non_nullable
as bool,quickSuggestionsDelay: null == quickSuggestionsDelay ? _self.quickSuggestionsDelay : quickSuggestionsDelay // ignore: cast_nullable_to_non_nullable
as int,suggestOnTriggerCharacters: null == suggestOnTriggerCharacters ? _self.suggestOnTriggerCharacters : suggestOnTriggerCharacters // ignore: cast_nullable_to_non_nullable
as bool,acceptSuggestionOnEnter: null == acceptSuggestionOnEnter ? _self.acceptSuggestionOnEnter : acceptSuggestionOnEnter // ignore: cast_nullable_to_non_nullable
as AcceptSuggestionOnEnter,acceptSuggestionOnCommitCharacter: null == acceptSuggestionOnCommitCharacter ? _self.acceptSuggestionOnCommitCharacter : acceptSuggestionOnCommitCharacter // ignore: cast_nullable_to_non_nullable
as bool,snippetSuggestions: null == snippetSuggestions ? _self.snippetSuggestions : snippetSuggestions // ignore: cast_nullable_to_non_nullable
as SnippetSuggestions,wordBasedSuggestions: null == wordBasedSuggestions ? _self.wordBasedSuggestions : wordBasedSuggestions // ignore: cast_nullable_to_non_nullable
as WordBasedSuggestions,parameterHints: null == parameterHints ? _self.parameterHints : parameterHints // ignore: cast_nullable_to_non_nullable
as bool,hover: null == hover ? _self.hover : hover // ignore: cast_nullable_to_non_nullable
as bool,contextMenu: null == contextMenu ? _self.contextMenu : contextMenu // ignore: cast_nullable_to_non_nullable
as bool,find: null == find ? _self.find : find // ignore: cast_nullable_to_non_nullable
as bool,seedSearchStringFromSelection: null == seedSearchStringFromSelection ? _self.seedSearchStringFromSelection : seedSearchStringFromSelection // ignore: cast_nullable_to_non_nullable
as String,accessibilitySupport: null == accessibilitySupport ? _self.accessibilitySupport : accessibilitySupport // ignore: cast_nullable_to_non_nullable
as AccessibilitySupport,accessibilityPageSize: null == accessibilityPageSize ? _self.accessibilityPageSize : accessibilityPageSize // ignore: cast_nullable_to_non_nullable
as int,renderValidationDecorations: null == renderValidationDecorations ? _self.renderValidationDecorations : renderValidationDecorations // ignore: cast_nullable_to_non_nullable
as String,renderControlCharacters: null == renderControlCharacters ? _self.renderControlCharacters : renderControlCharacters // ignore: cast_nullable_to_non_nullable
as bool,disableLayerHinting: null == disableLayerHinting ? _self.disableLayerHinting : disableLayerHinting // ignore: cast_nullable_to_non_nullable
as bool,disableMonospaceOptimizations: null == disableMonospaceOptimizations ? _self.disableMonospaceOptimizations : disableMonospaceOptimizations // ignore: cast_nullable_to_non_nullable
as bool,maxTokenizationLineLength: null == maxTokenizationLineLength ? _self.maxTokenizationLineLength : maxTokenizationLineLength // ignore: cast_nullable_to_non_nullable
as int,languageConfigs: null == languageConfigs ? _self.languageConfigs : languageConfigs // ignore: cast_nullable_to_non_nullable
as Map<String, LanguageConfig>,keybindingPreset: null == keybindingPreset ? _self.keybindingPreset : keybindingPreset // ignore: cast_nullable_to_non_nullable
as KeybindingPresetEnum,customKeybindings: null == customKeybindings ? _self.customKeybindings : customKeybindings // ignore: cast_nullable_to_non_nullable
as Map<String, String>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,domReadOnly: null == domReadOnly ? _self.domReadOnly : domReadOnly // ignore: cast_nullable_to_non_nullable
as bool,dragAndDrop: null == dragAndDrop ? _self.dragAndDrop : dragAndDrop // ignore: cast_nullable_to_non_nullable
as bool,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as bool,mouseWheelZoom: null == mouseWheelZoom ? _self.mouseWheelZoom : mouseWheelZoom // ignore: cast_nullable_to_non_nullable
as bool,mouseWheelScrollSensitivity: null == mouseWheelScrollSensitivity ? _self.mouseWheelScrollSensitivity : mouseWheelScrollSensitivity // ignore: cast_nullable_to_non_nullable
as double,automaticLayout: null == automaticLayout ? _self.automaticLayout : automaticLayout // ignore: cast_nullable_to_non_nullable
as bool,padding: null == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as Map<String, int>,roundedSelection: null == roundedSelection ? _self.roundedSelection : roundedSelection // ignore: cast_nullable_to_non_nullable
as bool,selectionHighlight: null == selectionHighlight ? _self.selectionHighlight : selectionHighlight // ignore: cast_nullable_to_non_nullable
as bool,occurrencesHighlight: null == occurrencesHighlight ? _self.occurrencesHighlight : occurrencesHighlight // ignore: cast_nullable_to_non_nullable
as String,overviewRulerBorder: null == overviewRulerBorder ? _self.overviewRulerBorder : overviewRulerBorder // ignore: cast_nullable_to_non_nullable
as bool,hideCursorInOverviewRuler: null == hideCursorInOverviewRuler ? _self.hideCursorInOverviewRuler : hideCursorInOverviewRuler // ignore: cast_nullable_to_non_nullable
as bool,scrollbar: null == scrollbar ? _self.scrollbar : scrollbar // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,experimentalFeatures: null == experimentalFeatures ? _self.experimentalFeatures : experimentalFeatures // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _EditorSettings extends EditorSettings {
  const _EditorSettings({@JsonKey(name: 'editor_theme') this.theme = 'vs-dark', @JsonKey(name: 'editor_font_size') this.fontSize = 14, @JsonKey(name: 'editor_font_family') this.fontFamily = 'JetBrains Mono, SF Mono, Menlo, Consolas, "Courier New", monospace', @JsonKey(name: 'editor_line_height') this.lineHeight = 1.4, @JsonKey(name: 'editor_letter_spacing') this.letterSpacing = 0, @JsonKey(name: 'editor_show_line_numbers') this.showLineNumbers = true, @JsonKey(name: 'editor_line_numbers_style') this.lineNumbersStyle = LineNumbersStyle.on, @JsonKey(name: 'editor_show_minimap') this.showMinimap = false, @JsonKey(name: 'editor_minimap_side') this.minimapSide = MinimapSide.right, @JsonKey(name: 'editor_minimap_render_characters') this.minimapRenderCharacters = false, @JsonKey(name: 'editor_minimap_size') this.minimapSize = 1, @JsonKey(name: 'editor_show_indent_guides') this.showIndentGuides = true, @JsonKey(name: 'editor_render_whitespace') this.renderWhitespace = RenderWhitespace.selection, @JsonKey(name: 'editor_rulers') final  List<int> rulers = const [], @JsonKey(name: 'editor_sticky_scroll') this.stickyScroll = false, @JsonKey(name: 'editor_show_folding_controls') this.showFoldingControls = 'mouseover', @JsonKey(name: 'editor_glyph_margin') this.glyphMargin = true, @JsonKey(name: 'editor_render_line_highlight') this.renderLineHighlight = 'line', @JsonKey(name: 'editor_word_wrap') this.wordWrap = WordWrap.on, @JsonKey(name: 'editor_word_wrap_column') this.wordWrapColumn = 80, @JsonKey(name: 'editor_tab_size') this.tabSize = 4, @JsonKey(name: 'editor_insert_spaces') this.insertSpaces = true, @JsonKey(name: 'editor_auto_indent') this.autoIndent = 'advanced', @JsonKey(name: 'editor_auto_closing_brackets') this.autoClosingBrackets = 'languageDefined', @JsonKey(name: 'editor_auto_closing_quotes') this.autoClosingQuotes = 'languageDefined', @JsonKey(name: 'editor_auto_surround') this.autoSurround = 'languageDefined', @JsonKey(name: 'editor_bracket_pair_colorization') this.bracketPairColorization = true, @JsonKey(name: 'editor_code_folding') this.codeFolding = true, @JsonKey(name: 'editor_scroll_beyond_last_line') this.scrollBeyondLastLine = true, @JsonKey(name: 'editor_smooth_scrolling') this.smoothScrolling = false, @JsonKey(name: 'editor_fast_scroll_sensitivity') this.fastScrollSensitivity = 5, @JsonKey(name: 'editor_scroll_predominant_axis') this.scrollPredominantAxis = true, @JsonKey(name: 'editor_cursor_blinking') this.cursorBlinking = CursorBlinking.blink, @JsonKey(name: 'editor_cursor_smooth_caret_animation') this.cursorSmoothCaretAnimation = 'off', @JsonKey(name: 'editor_cursor_style') this.cursorStyle = CursorStyle.line, @JsonKey(name: 'editor_cursor_width') this.cursorWidth = 0, @JsonKey(name: 'editor_multi_cursor_modifier') this.multiCursorModifier = MultiCursorModifier.ctrlCmd, @JsonKey(name: 'editor_multi_cursor_merge_overlapping') this.multiCursorMergeOverlapping = true, @JsonKey(name: 'editor_format_on_save') this.formatOnSave = false, @JsonKey(name: 'editor_format_on_paste') this.formatOnPaste = false, @JsonKey(name: 'editor_format_on_type') this.formatOnType = false, @JsonKey(name: 'editor_quick_suggestions') this.quickSuggestions = true, @JsonKey(name: 'editor_quick_suggestions_delay') this.quickSuggestionsDelay = 10, @JsonKey(name: 'editor_suggest_on_trigger_characters') this.suggestOnTriggerCharacters = true, @JsonKey(name: 'editor_accept_suggestion_on_enter') this.acceptSuggestionOnEnter = AcceptSuggestionOnEnter.on, @JsonKey(name: 'editor_accept_suggestion_on_commit_character') this.acceptSuggestionOnCommitCharacter = true, @JsonKey(name: 'editor_snippet_suggestions') this.snippetSuggestions = SnippetSuggestions.inline, @JsonKey(name: 'editor_word_based_suggestions') this.wordBasedSuggestions = WordBasedSuggestions.currentDocument, @JsonKey(name: 'editor_parameter_hints') this.parameterHints = true, @JsonKey(name: 'editor_hover') this.hover = true, @JsonKey(name: 'editor_context_menu') this.contextMenu = true, @JsonKey(name: 'editor_find') this.find = true, @JsonKey(name: 'editor_seed_search_string_from_selection') this.seedSearchStringFromSelection = 'selection', @JsonKey(name: 'editor_accessibility_support') this.accessibilitySupport = AccessibilitySupport.auto, @JsonKey(name: 'editor_accessibility_page_size') this.accessibilityPageSize = 10, @JsonKey(name: 'editor_render_validation_decorations') this.renderValidationDecorations = 'editable', @JsonKey(name: 'editor_render_control_characters') this.renderControlCharacters = false, @JsonKey(name: 'editor_disable_layer_hinting') this.disableLayerHinting = false, @JsonKey(name: 'editor_disable_monospace_optimizations') this.disableMonospaceOptimizations = false, @JsonKey(name: 'editor_max_tokenization_line_length') this.maxTokenizationLineLength = 20000, @JsonKey(name: 'editor_language_configs') final  Map<String, LanguageConfig> languageConfigs = const {}, @JsonKey(name: 'editor_keybinding_preset') this.keybindingPreset = KeybindingPresetEnum.vscode, @JsonKey(name: 'editor_custom_keybindings') final  Map<String, String> customKeybindings = const {}, @JsonKey(name: 'editor_read_only') this.readOnly = false, @JsonKey(name: 'editor_dom_read_only') this.domReadOnly = false, @JsonKey(name: 'editor_drag_and_drop') this.dragAndDrop = true, @JsonKey(name: 'editor_links') this.links = true, @JsonKey(name: 'editor_mouse_wheel_zoom') this.mouseWheelZoom = false, @JsonKey(name: 'editor_mouse_wheel_scroll_sensitivity') this.mouseWheelScrollSensitivity = 1, @JsonKey(name: 'editor_automatic_layout') this.automaticLayout = true, @JsonKey(name: 'editor_padding') final  Map<String, int> padding = const {'top' : 10, 'bottom' : 10, 'start' : 10, 'end' : 10}, @JsonKey(name: 'editor_rounded_selection') this.roundedSelection = true, @JsonKey(name: 'editor_selection_highlight') this.selectionHighlight = true, @JsonKey(name: 'editor_occurrences_highlight') this.occurrencesHighlight = 'singleFile', @JsonKey(name: 'editor_overview_ruler_border') this.overviewRulerBorder = true, @JsonKey(name: 'editor_hide_cursor_in_overview_ruler') this.hideCursorInOverviewRuler = false, @JsonKey(name: 'editor_scrollbar') final  Map<String, dynamic> scrollbar = const {'vertical' : 'auto', 'horizontal' : 'auto', 'arrowSize' : 11, 'useShadows' : true, 'verticalScrollbarSize' : 14, 'horizontalScrollbarSize' : 10, 'scrollByPage' : false}, @JsonKey(name: 'editor_experimental_features') final  Map<String, dynamic> experimentalFeatures = const {}}): _rulers = rulers,_languageConfigs = languageConfigs,_customKeybindings = customKeybindings,_padding = padding,_scrollbar = scrollbar,_experimentalFeatures = experimentalFeatures,super._();
  factory _EditorSettings.fromJson(Map<String, dynamic> json) => _$EditorSettingsFromJson(json);

// General Settings
@override@JsonKey(name: 'editor_theme') final  String theme;
@override@JsonKey(name: 'editor_font_size') final  double fontSize;
@override@JsonKey(name: 'editor_font_family') final  String fontFamily;
@override@JsonKey(name: 'editor_line_height') final  double lineHeight;
@override@JsonKey(name: 'editor_letter_spacing') final  double letterSpacing;
// Display Settings
@override@JsonKey(name: 'editor_show_line_numbers') final  bool showLineNumbers;
@override@JsonKey(name: 'editor_line_numbers_style') final  LineNumbersStyle lineNumbersStyle;
@override@JsonKey(name: 'editor_show_minimap') final  bool showMinimap;
@override@JsonKey(name: 'editor_minimap_side') final  MinimapSide minimapSide;
@override@JsonKey(name: 'editor_minimap_render_characters') final  bool minimapRenderCharacters;
@override@JsonKey(name: 'editor_minimap_size') final  int minimapSize;
@override@JsonKey(name: 'editor_show_indent_guides') final  bool showIndentGuides;
@override@JsonKey(name: 'editor_render_whitespace') final  RenderWhitespace renderWhitespace;
 final  List<int> _rulers;
@override@JsonKey(name: 'editor_rulers') List<int> get rulers {
  if (_rulers is EqualUnmodifiableListView) return _rulers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rulers);
}

@override@JsonKey(name: 'editor_sticky_scroll') final  bool stickyScroll;
@override@JsonKey(name: 'editor_show_folding_controls') final  String showFoldingControls;
@override@JsonKey(name: 'editor_glyph_margin') final  bool glyphMargin;
@override@JsonKey(name: 'editor_render_line_highlight') final  String renderLineHighlight;
// Editor Behavior
@override@JsonKey(name: 'editor_word_wrap') final  WordWrap wordWrap;
@override@JsonKey(name: 'editor_word_wrap_column') final  int wordWrapColumn;
@override@JsonKey(name: 'editor_tab_size') final  int tabSize;
@override@JsonKey(name: 'editor_insert_spaces') final  bool insertSpaces;
@override@JsonKey(name: 'editor_auto_indent') final  String autoIndent;
@override@JsonKey(name: 'editor_auto_closing_brackets') final  String autoClosingBrackets;
@override@JsonKey(name: 'editor_auto_closing_quotes') final  String autoClosingQuotes;
@override@JsonKey(name: 'editor_auto_surround') final  String autoSurround;
@override@JsonKey(name: 'editor_bracket_pair_colorization') final  bool bracketPairColorization;
@override@JsonKey(name: 'editor_code_folding') final  bool codeFolding;
@override@JsonKey(name: 'editor_scroll_beyond_last_line') final  bool scrollBeyondLastLine;
@override@JsonKey(name: 'editor_smooth_scrolling') final  bool smoothScrolling;
@override@JsonKey(name: 'editor_fast_scroll_sensitivity') final  double fastScrollSensitivity;
@override@JsonKey(name: 'editor_scroll_predominant_axis') final  bool scrollPredominantAxis;
// Cursor Settings
@override@JsonKey(name: 'editor_cursor_blinking') final  CursorBlinking cursorBlinking;
@override@JsonKey(name: 'editor_cursor_smooth_caret_animation') final  String cursorSmoothCaretAnimation;
@override@JsonKey(name: 'editor_cursor_style') final  CursorStyle cursorStyle;
@override@JsonKey(name: 'editor_cursor_width') final  int cursorWidth;
@override@JsonKey(name: 'editor_multi_cursor_modifier') final  MultiCursorModifier multiCursorModifier;
@override@JsonKey(name: 'editor_multi_cursor_merge_overlapping') final  bool multiCursorMergeOverlapping;
// Editing Features
@override@JsonKey(name: 'editor_format_on_save') final  bool formatOnSave;
@override@JsonKey(name: 'editor_format_on_paste') final  bool formatOnPaste;
@override@JsonKey(name: 'editor_format_on_type') final  bool formatOnType;
@override@JsonKey(name: 'editor_quick_suggestions') final  bool quickSuggestions;
@override@JsonKey(name: 'editor_quick_suggestions_delay') final  int quickSuggestionsDelay;
@override@JsonKey(name: 'editor_suggest_on_trigger_characters') final  bool suggestOnTriggerCharacters;
@override@JsonKey(name: 'editor_accept_suggestion_on_enter') final  AcceptSuggestionOnEnter acceptSuggestionOnEnter;
@override@JsonKey(name: 'editor_accept_suggestion_on_commit_character') final  bool acceptSuggestionOnCommitCharacter;
@override@JsonKey(name: 'editor_snippet_suggestions') final  SnippetSuggestions snippetSuggestions;
@override@JsonKey(name: 'editor_word_based_suggestions') final  WordBasedSuggestions wordBasedSuggestions;
@override@JsonKey(name: 'editor_parameter_hints') final  bool parameterHints;
@override@JsonKey(name: 'editor_hover') final  bool hover;
@override@JsonKey(name: 'editor_context_menu') final  bool contextMenu;
// Find & Replace
@override@JsonKey(name: 'editor_find') final  bool find;
@override@JsonKey(name: 'editor_seed_search_string_from_selection') final  String seedSearchStringFromSelection;
// Accessibility
@override@JsonKey(name: 'editor_accessibility_support') final  AccessibilitySupport accessibilitySupport;
@override@JsonKey(name: 'editor_accessibility_page_size') final  int accessibilityPageSize;
// Performance
@override@JsonKey(name: 'editor_render_validation_decorations') final  String renderValidationDecorations;
@override@JsonKey(name: 'editor_render_control_characters') final  bool renderControlCharacters;
@override@JsonKey(name: 'editor_disable_layer_hinting') final  bool disableLayerHinting;
@override@JsonKey(name: 'editor_disable_monospace_optimizations') final  bool disableMonospaceOptimizations;
@override@JsonKey(name: 'editor_max_tokenization_line_length') final  int maxTokenizationLineLength;
// Language Specific
 final  Map<String, LanguageConfig> _languageConfigs;
// Language Specific
@override@JsonKey(name: 'editor_language_configs') Map<String, LanguageConfig> get languageConfigs {
  if (_languageConfigs is EqualUnmodifiableMapView) return _languageConfigs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_languageConfigs);
}

// Keybindings
@override@JsonKey(name: 'editor_keybinding_preset') final  KeybindingPresetEnum keybindingPreset;
 final  Map<String, String> _customKeybindings;
@override@JsonKey(name: 'editor_custom_keybindings') Map<String, String> get customKeybindings {
  if (_customKeybindings is EqualUnmodifiableMapView) return _customKeybindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customKeybindings);
}

// Advanced
@override@JsonKey(name: 'editor_read_only') final  bool readOnly;
@override@JsonKey(name: 'editor_dom_read_only') final  bool domReadOnly;
@override@JsonKey(name: 'editor_drag_and_drop') final  bool dragAndDrop;
@override@JsonKey(name: 'editor_links') final  bool links;
@override@JsonKey(name: 'editor_mouse_wheel_zoom') final  bool mouseWheelZoom;
@override@JsonKey(name: 'editor_mouse_wheel_scroll_sensitivity') final  double mouseWheelScrollSensitivity;
@override@JsonKey(name: 'editor_automatic_layout') final  bool automaticLayout;
 final  Map<String, int> _padding;
@override@JsonKey(name: 'editor_padding') Map<String, int> get padding {
  if (_padding is EqualUnmodifiableMapView) return _padding;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_padding);
}

@override@JsonKey(name: 'editor_rounded_selection') final  bool roundedSelection;
@override@JsonKey(name: 'editor_selection_highlight') final  bool selectionHighlight;
@override@JsonKey(name: 'editor_occurrences_highlight') final  String occurrencesHighlight;
@override@JsonKey(name: 'editor_overview_ruler_border') final  bool overviewRulerBorder;
@override@JsonKey(name: 'editor_hide_cursor_in_overview_ruler') final  bool hideCursorInOverviewRuler;
 final  Map<String, dynamic> _scrollbar;
@override@JsonKey(name: 'editor_scrollbar') Map<String, dynamic> get scrollbar {
  if (_scrollbar is EqualUnmodifiableMapView) return _scrollbar;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_scrollbar);
}

 final  Map<String, dynamic> _experimentalFeatures;
@override@JsonKey(name: 'editor_experimental_features') Map<String, dynamic> get experimentalFeatures {
  if (_experimentalFeatures is EqualUnmodifiableMapView) return _experimentalFeatures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_experimentalFeatures);
}


/// Create a copy of EditorSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorSettingsCopyWith<_EditorSettings> get copyWith => __$EditorSettingsCopyWithImpl<_EditorSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EditorSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorSettings&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.lineHeight, lineHeight) || other.lineHeight == lineHeight)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.showLineNumbers, showLineNumbers) || other.showLineNumbers == showLineNumbers)&&(identical(other.lineNumbersStyle, lineNumbersStyle) || other.lineNumbersStyle == lineNumbersStyle)&&(identical(other.showMinimap, showMinimap) || other.showMinimap == showMinimap)&&(identical(other.minimapSide, minimapSide) || other.minimapSide == minimapSide)&&(identical(other.minimapRenderCharacters, minimapRenderCharacters) || other.minimapRenderCharacters == minimapRenderCharacters)&&(identical(other.minimapSize, minimapSize) || other.minimapSize == minimapSize)&&(identical(other.showIndentGuides, showIndentGuides) || other.showIndentGuides == showIndentGuides)&&(identical(other.renderWhitespace, renderWhitespace) || other.renderWhitespace == renderWhitespace)&&const DeepCollectionEquality().equals(other._rulers, _rulers)&&(identical(other.stickyScroll, stickyScroll) || other.stickyScroll == stickyScroll)&&(identical(other.showFoldingControls, showFoldingControls) || other.showFoldingControls == showFoldingControls)&&(identical(other.glyphMargin, glyphMargin) || other.glyphMargin == glyphMargin)&&(identical(other.renderLineHighlight, renderLineHighlight) || other.renderLineHighlight == renderLineHighlight)&&(identical(other.wordWrap, wordWrap) || other.wordWrap == wordWrap)&&(identical(other.wordWrapColumn, wordWrapColumn) || other.wordWrapColumn == wordWrapColumn)&&(identical(other.tabSize, tabSize) || other.tabSize == tabSize)&&(identical(other.insertSpaces, insertSpaces) || other.insertSpaces == insertSpaces)&&(identical(other.autoIndent, autoIndent) || other.autoIndent == autoIndent)&&(identical(other.autoClosingBrackets, autoClosingBrackets) || other.autoClosingBrackets == autoClosingBrackets)&&(identical(other.autoClosingQuotes, autoClosingQuotes) || other.autoClosingQuotes == autoClosingQuotes)&&(identical(other.autoSurround, autoSurround) || other.autoSurround == autoSurround)&&(identical(other.bracketPairColorization, bracketPairColorization) || other.bracketPairColorization == bracketPairColorization)&&(identical(other.codeFolding, codeFolding) || other.codeFolding == codeFolding)&&(identical(other.scrollBeyondLastLine, scrollBeyondLastLine) || other.scrollBeyondLastLine == scrollBeyondLastLine)&&(identical(other.smoothScrolling, smoothScrolling) || other.smoothScrolling == smoothScrolling)&&(identical(other.fastScrollSensitivity, fastScrollSensitivity) || other.fastScrollSensitivity == fastScrollSensitivity)&&(identical(other.scrollPredominantAxis, scrollPredominantAxis) || other.scrollPredominantAxis == scrollPredominantAxis)&&(identical(other.cursorBlinking, cursorBlinking) || other.cursorBlinking == cursorBlinking)&&(identical(other.cursorSmoothCaretAnimation, cursorSmoothCaretAnimation) || other.cursorSmoothCaretAnimation == cursorSmoothCaretAnimation)&&(identical(other.cursorStyle, cursorStyle) || other.cursorStyle == cursorStyle)&&(identical(other.cursorWidth, cursorWidth) || other.cursorWidth == cursorWidth)&&(identical(other.multiCursorModifier, multiCursorModifier) || other.multiCursorModifier == multiCursorModifier)&&(identical(other.multiCursorMergeOverlapping, multiCursorMergeOverlapping) || other.multiCursorMergeOverlapping == multiCursorMergeOverlapping)&&(identical(other.formatOnSave, formatOnSave) || other.formatOnSave == formatOnSave)&&(identical(other.formatOnPaste, formatOnPaste) || other.formatOnPaste == formatOnPaste)&&(identical(other.formatOnType, formatOnType) || other.formatOnType == formatOnType)&&(identical(other.quickSuggestions, quickSuggestions) || other.quickSuggestions == quickSuggestions)&&(identical(other.quickSuggestionsDelay, quickSuggestionsDelay) || other.quickSuggestionsDelay == quickSuggestionsDelay)&&(identical(other.suggestOnTriggerCharacters, suggestOnTriggerCharacters) || other.suggestOnTriggerCharacters == suggestOnTriggerCharacters)&&(identical(other.acceptSuggestionOnEnter, acceptSuggestionOnEnter) || other.acceptSuggestionOnEnter == acceptSuggestionOnEnter)&&(identical(other.acceptSuggestionOnCommitCharacter, acceptSuggestionOnCommitCharacter) || other.acceptSuggestionOnCommitCharacter == acceptSuggestionOnCommitCharacter)&&(identical(other.snippetSuggestions, snippetSuggestions) || other.snippetSuggestions == snippetSuggestions)&&(identical(other.wordBasedSuggestions, wordBasedSuggestions) || other.wordBasedSuggestions == wordBasedSuggestions)&&(identical(other.parameterHints, parameterHints) || other.parameterHints == parameterHints)&&(identical(other.hover, hover) || other.hover == hover)&&(identical(other.contextMenu, contextMenu) || other.contextMenu == contextMenu)&&(identical(other.find, find) || other.find == find)&&(identical(other.seedSearchStringFromSelection, seedSearchStringFromSelection) || other.seedSearchStringFromSelection == seedSearchStringFromSelection)&&(identical(other.accessibilitySupport, accessibilitySupport) || other.accessibilitySupport == accessibilitySupport)&&(identical(other.accessibilityPageSize, accessibilityPageSize) || other.accessibilityPageSize == accessibilityPageSize)&&(identical(other.renderValidationDecorations, renderValidationDecorations) || other.renderValidationDecorations == renderValidationDecorations)&&(identical(other.renderControlCharacters, renderControlCharacters) || other.renderControlCharacters == renderControlCharacters)&&(identical(other.disableLayerHinting, disableLayerHinting) || other.disableLayerHinting == disableLayerHinting)&&(identical(other.disableMonospaceOptimizations, disableMonospaceOptimizations) || other.disableMonospaceOptimizations == disableMonospaceOptimizations)&&(identical(other.maxTokenizationLineLength, maxTokenizationLineLength) || other.maxTokenizationLineLength == maxTokenizationLineLength)&&const DeepCollectionEquality().equals(other._languageConfigs, _languageConfigs)&&(identical(other.keybindingPreset, keybindingPreset) || other.keybindingPreset == keybindingPreset)&&const DeepCollectionEquality().equals(other._customKeybindings, _customKeybindings)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.domReadOnly, domReadOnly) || other.domReadOnly == domReadOnly)&&(identical(other.dragAndDrop, dragAndDrop) || other.dragAndDrop == dragAndDrop)&&(identical(other.links, links) || other.links == links)&&(identical(other.mouseWheelZoom, mouseWheelZoom) || other.mouseWheelZoom == mouseWheelZoom)&&(identical(other.mouseWheelScrollSensitivity, mouseWheelScrollSensitivity) || other.mouseWheelScrollSensitivity == mouseWheelScrollSensitivity)&&(identical(other.automaticLayout, automaticLayout) || other.automaticLayout == automaticLayout)&&const DeepCollectionEquality().equals(other._padding, _padding)&&(identical(other.roundedSelection, roundedSelection) || other.roundedSelection == roundedSelection)&&(identical(other.selectionHighlight, selectionHighlight) || other.selectionHighlight == selectionHighlight)&&(identical(other.occurrencesHighlight, occurrencesHighlight) || other.occurrencesHighlight == occurrencesHighlight)&&(identical(other.overviewRulerBorder, overviewRulerBorder) || other.overviewRulerBorder == overviewRulerBorder)&&(identical(other.hideCursorInOverviewRuler, hideCursorInOverviewRuler) || other.hideCursorInOverviewRuler == hideCursorInOverviewRuler)&&const DeepCollectionEquality().equals(other._scrollbar, _scrollbar)&&const DeepCollectionEquality().equals(other._experimentalFeatures, _experimentalFeatures));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,theme,fontSize,fontFamily,lineHeight,letterSpacing,showLineNumbers,lineNumbersStyle,showMinimap,minimapSide,minimapRenderCharacters,minimapSize,showIndentGuides,renderWhitespace,const DeepCollectionEquality().hash(_rulers),stickyScroll,showFoldingControls,glyphMargin,renderLineHighlight,wordWrap,wordWrapColumn,tabSize,insertSpaces,autoIndent,autoClosingBrackets,autoClosingQuotes,autoSurround,bracketPairColorization,codeFolding,scrollBeyondLastLine,smoothScrolling,fastScrollSensitivity,scrollPredominantAxis,cursorBlinking,cursorSmoothCaretAnimation,cursorStyle,cursorWidth,multiCursorModifier,multiCursorMergeOverlapping,formatOnSave,formatOnPaste,formatOnType,quickSuggestions,quickSuggestionsDelay,suggestOnTriggerCharacters,acceptSuggestionOnEnter,acceptSuggestionOnCommitCharacter,snippetSuggestions,wordBasedSuggestions,parameterHints,hover,contextMenu,find,seedSearchStringFromSelection,accessibilitySupport,accessibilityPageSize,renderValidationDecorations,renderControlCharacters,disableLayerHinting,disableMonospaceOptimizations,maxTokenizationLineLength,const DeepCollectionEquality().hash(_languageConfigs),keybindingPreset,const DeepCollectionEquality().hash(_customKeybindings),readOnly,domReadOnly,dragAndDrop,links,mouseWheelZoom,mouseWheelScrollSensitivity,automaticLayout,const DeepCollectionEquality().hash(_padding),roundedSelection,selectionHighlight,occurrencesHighlight,overviewRulerBorder,hideCursorInOverviewRuler,const DeepCollectionEquality().hash(_scrollbar),const DeepCollectionEquality().hash(_experimentalFeatures)]);

@override
String toString() {
  return 'EditorSettings(theme: $theme, fontSize: $fontSize, fontFamily: $fontFamily, lineHeight: $lineHeight, letterSpacing: $letterSpacing, showLineNumbers: $showLineNumbers, lineNumbersStyle: $lineNumbersStyle, showMinimap: $showMinimap, minimapSide: $minimapSide, minimapRenderCharacters: $minimapRenderCharacters, minimapSize: $minimapSize, showIndentGuides: $showIndentGuides, renderWhitespace: $renderWhitespace, rulers: $rulers, stickyScroll: $stickyScroll, showFoldingControls: $showFoldingControls, glyphMargin: $glyphMargin, renderLineHighlight: $renderLineHighlight, wordWrap: $wordWrap, wordWrapColumn: $wordWrapColumn, tabSize: $tabSize, insertSpaces: $insertSpaces, autoIndent: $autoIndent, autoClosingBrackets: $autoClosingBrackets, autoClosingQuotes: $autoClosingQuotes, autoSurround: $autoSurround, bracketPairColorization: $bracketPairColorization, codeFolding: $codeFolding, scrollBeyondLastLine: $scrollBeyondLastLine, smoothScrolling: $smoothScrolling, fastScrollSensitivity: $fastScrollSensitivity, scrollPredominantAxis: $scrollPredominantAxis, cursorBlinking: $cursorBlinking, cursorSmoothCaretAnimation: $cursorSmoothCaretAnimation, cursorStyle: $cursorStyle, cursorWidth: $cursorWidth, multiCursorModifier: $multiCursorModifier, multiCursorMergeOverlapping: $multiCursorMergeOverlapping, formatOnSave: $formatOnSave, formatOnPaste: $formatOnPaste, formatOnType: $formatOnType, quickSuggestions: $quickSuggestions, quickSuggestionsDelay: $quickSuggestionsDelay, suggestOnTriggerCharacters: $suggestOnTriggerCharacters, acceptSuggestionOnEnter: $acceptSuggestionOnEnter, acceptSuggestionOnCommitCharacter: $acceptSuggestionOnCommitCharacter, snippetSuggestions: $snippetSuggestions, wordBasedSuggestions: $wordBasedSuggestions, parameterHints: $parameterHints, hover: $hover, contextMenu: $contextMenu, find: $find, seedSearchStringFromSelection: $seedSearchStringFromSelection, accessibilitySupport: $accessibilitySupport, accessibilityPageSize: $accessibilityPageSize, renderValidationDecorations: $renderValidationDecorations, renderControlCharacters: $renderControlCharacters, disableLayerHinting: $disableLayerHinting, disableMonospaceOptimizations: $disableMonospaceOptimizations, maxTokenizationLineLength: $maxTokenizationLineLength, languageConfigs: $languageConfigs, keybindingPreset: $keybindingPreset, customKeybindings: $customKeybindings, readOnly: $readOnly, domReadOnly: $domReadOnly, dragAndDrop: $dragAndDrop, links: $links, mouseWheelZoom: $mouseWheelZoom, mouseWheelScrollSensitivity: $mouseWheelScrollSensitivity, automaticLayout: $automaticLayout, padding: $padding, roundedSelection: $roundedSelection, selectionHighlight: $selectionHighlight, occurrencesHighlight: $occurrencesHighlight, overviewRulerBorder: $overviewRulerBorder, hideCursorInOverviewRuler: $hideCursorInOverviewRuler, scrollbar: $scrollbar, experimentalFeatures: $experimentalFeatures)';
}


}

/// @nodoc
abstract mixin class _$EditorSettingsCopyWith<$Res> implements $EditorSettingsCopyWith<$Res> {
  factory _$EditorSettingsCopyWith(_EditorSettings value, $Res Function(_EditorSettings) _then) = __$EditorSettingsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'editor_theme') String theme,@JsonKey(name: 'editor_font_size') double fontSize,@JsonKey(name: 'editor_font_family') String fontFamily,@JsonKey(name: 'editor_line_height') double lineHeight,@JsonKey(name: 'editor_letter_spacing') double letterSpacing,@JsonKey(name: 'editor_show_line_numbers') bool showLineNumbers,@JsonKey(name: 'editor_line_numbers_style') LineNumbersStyle lineNumbersStyle,@JsonKey(name: 'editor_show_minimap') bool showMinimap,@JsonKey(name: 'editor_minimap_side') MinimapSide minimapSide,@JsonKey(name: 'editor_minimap_render_characters') bool minimapRenderCharacters,@JsonKey(name: 'editor_minimap_size') int minimapSize,@JsonKey(name: 'editor_show_indent_guides') bool showIndentGuides,@JsonKey(name: 'editor_render_whitespace') RenderWhitespace renderWhitespace,@JsonKey(name: 'editor_rulers') List<int> rulers,@JsonKey(name: 'editor_sticky_scroll') bool stickyScroll,@JsonKey(name: 'editor_show_folding_controls') String showFoldingControls,@JsonKey(name: 'editor_glyph_margin') bool glyphMargin,@JsonKey(name: 'editor_render_line_highlight') String renderLineHighlight,@JsonKey(name: 'editor_word_wrap') WordWrap wordWrap,@JsonKey(name: 'editor_word_wrap_column') int wordWrapColumn,@JsonKey(name: 'editor_tab_size') int tabSize,@JsonKey(name: 'editor_insert_spaces') bool insertSpaces,@JsonKey(name: 'editor_auto_indent') String autoIndent,@JsonKey(name: 'editor_auto_closing_brackets') String autoClosingBrackets,@JsonKey(name: 'editor_auto_closing_quotes') String autoClosingQuotes,@JsonKey(name: 'editor_auto_surround') String autoSurround,@JsonKey(name: 'editor_bracket_pair_colorization') bool bracketPairColorization,@JsonKey(name: 'editor_code_folding') bool codeFolding,@JsonKey(name: 'editor_scroll_beyond_last_line') bool scrollBeyondLastLine,@JsonKey(name: 'editor_smooth_scrolling') bool smoothScrolling,@JsonKey(name: 'editor_fast_scroll_sensitivity') double fastScrollSensitivity,@JsonKey(name: 'editor_scroll_predominant_axis') bool scrollPredominantAxis,@JsonKey(name: 'editor_cursor_blinking') CursorBlinking cursorBlinking,@JsonKey(name: 'editor_cursor_smooth_caret_animation') String cursorSmoothCaretAnimation,@JsonKey(name: 'editor_cursor_style') CursorStyle cursorStyle,@JsonKey(name: 'editor_cursor_width') int cursorWidth,@JsonKey(name: 'editor_multi_cursor_modifier') MultiCursorModifier multiCursorModifier,@JsonKey(name: 'editor_multi_cursor_merge_overlapping') bool multiCursorMergeOverlapping,@JsonKey(name: 'editor_format_on_save') bool formatOnSave,@JsonKey(name: 'editor_format_on_paste') bool formatOnPaste,@JsonKey(name: 'editor_format_on_type') bool formatOnType,@JsonKey(name: 'editor_quick_suggestions') bool quickSuggestions,@JsonKey(name: 'editor_quick_suggestions_delay') int quickSuggestionsDelay,@JsonKey(name: 'editor_suggest_on_trigger_characters') bool suggestOnTriggerCharacters,@JsonKey(name: 'editor_accept_suggestion_on_enter') AcceptSuggestionOnEnter acceptSuggestionOnEnter,@JsonKey(name: 'editor_accept_suggestion_on_commit_character') bool acceptSuggestionOnCommitCharacter,@JsonKey(name: 'editor_snippet_suggestions') SnippetSuggestions snippetSuggestions,@JsonKey(name: 'editor_word_based_suggestions') WordBasedSuggestions wordBasedSuggestions,@JsonKey(name: 'editor_parameter_hints') bool parameterHints,@JsonKey(name: 'editor_hover') bool hover,@JsonKey(name: 'editor_context_menu') bool contextMenu,@JsonKey(name: 'editor_find') bool find,@JsonKey(name: 'editor_seed_search_string_from_selection') String seedSearchStringFromSelection,@JsonKey(name: 'editor_accessibility_support') AccessibilitySupport accessibilitySupport,@JsonKey(name: 'editor_accessibility_page_size') int accessibilityPageSize,@JsonKey(name: 'editor_render_validation_decorations') String renderValidationDecorations,@JsonKey(name: 'editor_render_control_characters') bool renderControlCharacters,@JsonKey(name: 'editor_disable_layer_hinting') bool disableLayerHinting,@JsonKey(name: 'editor_disable_monospace_optimizations') bool disableMonospaceOptimizations,@JsonKey(name: 'editor_max_tokenization_line_length') int maxTokenizationLineLength,@JsonKey(name: 'editor_language_configs') Map<String, LanguageConfig> languageConfigs,@JsonKey(name: 'editor_keybinding_preset') KeybindingPresetEnum keybindingPreset,@JsonKey(name: 'editor_custom_keybindings') Map<String, String> customKeybindings,@JsonKey(name: 'editor_read_only') bool readOnly,@JsonKey(name: 'editor_dom_read_only') bool domReadOnly,@JsonKey(name: 'editor_drag_and_drop') bool dragAndDrop,@JsonKey(name: 'editor_links') bool links,@JsonKey(name: 'editor_mouse_wheel_zoom') bool mouseWheelZoom,@JsonKey(name: 'editor_mouse_wheel_scroll_sensitivity') double mouseWheelScrollSensitivity,@JsonKey(name: 'editor_automatic_layout') bool automaticLayout,@JsonKey(name: 'editor_padding') Map<String, int> padding,@JsonKey(name: 'editor_rounded_selection') bool roundedSelection,@JsonKey(name: 'editor_selection_highlight') bool selectionHighlight,@JsonKey(name: 'editor_occurrences_highlight') String occurrencesHighlight,@JsonKey(name: 'editor_overview_ruler_border') bool overviewRulerBorder,@JsonKey(name: 'editor_hide_cursor_in_overview_ruler') bool hideCursorInOverviewRuler,@JsonKey(name: 'editor_scrollbar') Map<String, dynamic> scrollbar,@JsonKey(name: 'editor_experimental_features') Map<String, dynamic> experimentalFeatures
});




}
/// @nodoc
class __$EditorSettingsCopyWithImpl<$Res>
    implements _$EditorSettingsCopyWith<$Res> {
  __$EditorSettingsCopyWithImpl(this._self, this._then);

  final _EditorSettings _self;
  final $Res Function(_EditorSettings) _then;

/// Create a copy of EditorSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? theme = null,Object? fontSize = null,Object? fontFamily = null,Object? lineHeight = null,Object? letterSpacing = null,Object? showLineNumbers = null,Object? lineNumbersStyle = null,Object? showMinimap = null,Object? minimapSide = null,Object? minimapRenderCharacters = null,Object? minimapSize = null,Object? showIndentGuides = null,Object? renderWhitespace = null,Object? rulers = null,Object? stickyScroll = null,Object? showFoldingControls = null,Object? glyphMargin = null,Object? renderLineHighlight = null,Object? wordWrap = null,Object? wordWrapColumn = null,Object? tabSize = null,Object? insertSpaces = null,Object? autoIndent = null,Object? autoClosingBrackets = null,Object? autoClosingQuotes = null,Object? autoSurround = null,Object? bracketPairColorization = null,Object? codeFolding = null,Object? scrollBeyondLastLine = null,Object? smoothScrolling = null,Object? fastScrollSensitivity = null,Object? scrollPredominantAxis = null,Object? cursorBlinking = null,Object? cursorSmoothCaretAnimation = null,Object? cursorStyle = null,Object? cursorWidth = null,Object? multiCursorModifier = null,Object? multiCursorMergeOverlapping = null,Object? formatOnSave = null,Object? formatOnPaste = null,Object? formatOnType = null,Object? quickSuggestions = null,Object? quickSuggestionsDelay = null,Object? suggestOnTriggerCharacters = null,Object? acceptSuggestionOnEnter = null,Object? acceptSuggestionOnCommitCharacter = null,Object? snippetSuggestions = null,Object? wordBasedSuggestions = null,Object? parameterHints = null,Object? hover = null,Object? contextMenu = null,Object? find = null,Object? seedSearchStringFromSelection = null,Object? accessibilitySupport = null,Object? accessibilityPageSize = null,Object? renderValidationDecorations = null,Object? renderControlCharacters = null,Object? disableLayerHinting = null,Object? disableMonospaceOptimizations = null,Object? maxTokenizationLineLength = null,Object? languageConfigs = null,Object? keybindingPreset = null,Object? customKeybindings = null,Object? readOnly = null,Object? domReadOnly = null,Object? dragAndDrop = null,Object? links = null,Object? mouseWheelZoom = null,Object? mouseWheelScrollSensitivity = null,Object? automaticLayout = null,Object? padding = null,Object? roundedSelection = null,Object? selectionHighlight = null,Object? occurrencesHighlight = null,Object? overviewRulerBorder = null,Object? hideCursorInOverviewRuler = null,Object? scrollbar = null,Object? experimentalFeatures = null,}) {
  return _then(_EditorSettings(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,lineHeight: null == lineHeight ? _self.lineHeight : lineHeight // ignore: cast_nullable_to_non_nullable
as double,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double,showLineNumbers: null == showLineNumbers ? _self.showLineNumbers : showLineNumbers // ignore: cast_nullable_to_non_nullable
as bool,lineNumbersStyle: null == lineNumbersStyle ? _self.lineNumbersStyle : lineNumbersStyle // ignore: cast_nullable_to_non_nullable
as LineNumbersStyle,showMinimap: null == showMinimap ? _self.showMinimap : showMinimap // ignore: cast_nullable_to_non_nullable
as bool,minimapSide: null == minimapSide ? _self.minimapSide : minimapSide // ignore: cast_nullable_to_non_nullable
as MinimapSide,minimapRenderCharacters: null == minimapRenderCharacters ? _self.minimapRenderCharacters : minimapRenderCharacters // ignore: cast_nullable_to_non_nullable
as bool,minimapSize: null == minimapSize ? _self.minimapSize : minimapSize // ignore: cast_nullable_to_non_nullable
as int,showIndentGuides: null == showIndentGuides ? _self.showIndentGuides : showIndentGuides // ignore: cast_nullable_to_non_nullable
as bool,renderWhitespace: null == renderWhitespace ? _self.renderWhitespace : renderWhitespace // ignore: cast_nullable_to_non_nullable
as RenderWhitespace,rulers: null == rulers ? _self._rulers : rulers // ignore: cast_nullable_to_non_nullable
as List<int>,stickyScroll: null == stickyScroll ? _self.stickyScroll : stickyScroll // ignore: cast_nullable_to_non_nullable
as bool,showFoldingControls: null == showFoldingControls ? _self.showFoldingControls : showFoldingControls // ignore: cast_nullable_to_non_nullable
as String,glyphMargin: null == glyphMargin ? _self.glyphMargin : glyphMargin // ignore: cast_nullable_to_non_nullable
as bool,renderLineHighlight: null == renderLineHighlight ? _self.renderLineHighlight : renderLineHighlight // ignore: cast_nullable_to_non_nullable
as String,wordWrap: null == wordWrap ? _self.wordWrap : wordWrap // ignore: cast_nullable_to_non_nullable
as WordWrap,wordWrapColumn: null == wordWrapColumn ? _self.wordWrapColumn : wordWrapColumn // ignore: cast_nullable_to_non_nullable
as int,tabSize: null == tabSize ? _self.tabSize : tabSize // ignore: cast_nullable_to_non_nullable
as int,insertSpaces: null == insertSpaces ? _self.insertSpaces : insertSpaces // ignore: cast_nullable_to_non_nullable
as bool,autoIndent: null == autoIndent ? _self.autoIndent : autoIndent // ignore: cast_nullable_to_non_nullable
as String,autoClosingBrackets: null == autoClosingBrackets ? _self.autoClosingBrackets : autoClosingBrackets // ignore: cast_nullable_to_non_nullable
as String,autoClosingQuotes: null == autoClosingQuotes ? _self.autoClosingQuotes : autoClosingQuotes // ignore: cast_nullable_to_non_nullable
as String,autoSurround: null == autoSurround ? _self.autoSurround : autoSurround // ignore: cast_nullable_to_non_nullable
as String,bracketPairColorization: null == bracketPairColorization ? _self.bracketPairColorization : bracketPairColorization // ignore: cast_nullable_to_non_nullable
as bool,codeFolding: null == codeFolding ? _self.codeFolding : codeFolding // ignore: cast_nullable_to_non_nullable
as bool,scrollBeyondLastLine: null == scrollBeyondLastLine ? _self.scrollBeyondLastLine : scrollBeyondLastLine // ignore: cast_nullable_to_non_nullable
as bool,smoothScrolling: null == smoothScrolling ? _self.smoothScrolling : smoothScrolling // ignore: cast_nullable_to_non_nullable
as bool,fastScrollSensitivity: null == fastScrollSensitivity ? _self.fastScrollSensitivity : fastScrollSensitivity // ignore: cast_nullable_to_non_nullable
as double,scrollPredominantAxis: null == scrollPredominantAxis ? _self.scrollPredominantAxis : scrollPredominantAxis // ignore: cast_nullable_to_non_nullable
as bool,cursorBlinking: null == cursorBlinking ? _self.cursorBlinking : cursorBlinking // ignore: cast_nullable_to_non_nullable
as CursorBlinking,cursorSmoothCaretAnimation: null == cursorSmoothCaretAnimation ? _self.cursorSmoothCaretAnimation : cursorSmoothCaretAnimation // ignore: cast_nullable_to_non_nullable
as String,cursorStyle: null == cursorStyle ? _self.cursorStyle : cursorStyle // ignore: cast_nullable_to_non_nullable
as CursorStyle,cursorWidth: null == cursorWidth ? _self.cursorWidth : cursorWidth // ignore: cast_nullable_to_non_nullable
as int,multiCursorModifier: null == multiCursorModifier ? _self.multiCursorModifier : multiCursorModifier // ignore: cast_nullable_to_non_nullable
as MultiCursorModifier,multiCursorMergeOverlapping: null == multiCursorMergeOverlapping ? _self.multiCursorMergeOverlapping : multiCursorMergeOverlapping // ignore: cast_nullable_to_non_nullable
as bool,formatOnSave: null == formatOnSave ? _self.formatOnSave : formatOnSave // ignore: cast_nullable_to_non_nullable
as bool,formatOnPaste: null == formatOnPaste ? _self.formatOnPaste : formatOnPaste // ignore: cast_nullable_to_non_nullable
as bool,formatOnType: null == formatOnType ? _self.formatOnType : formatOnType // ignore: cast_nullable_to_non_nullable
as bool,quickSuggestions: null == quickSuggestions ? _self.quickSuggestions : quickSuggestions // ignore: cast_nullable_to_non_nullable
as bool,quickSuggestionsDelay: null == quickSuggestionsDelay ? _self.quickSuggestionsDelay : quickSuggestionsDelay // ignore: cast_nullable_to_non_nullable
as int,suggestOnTriggerCharacters: null == suggestOnTriggerCharacters ? _self.suggestOnTriggerCharacters : suggestOnTriggerCharacters // ignore: cast_nullable_to_non_nullable
as bool,acceptSuggestionOnEnter: null == acceptSuggestionOnEnter ? _self.acceptSuggestionOnEnter : acceptSuggestionOnEnter // ignore: cast_nullable_to_non_nullable
as AcceptSuggestionOnEnter,acceptSuggestionOnCommitCharacter: null == acceptSuggestionOnCommitCharacter ? _self.acceptSuggestionOnCommitCharacter : acceptSuggestionOnCommitCharacter // ignore: cast_nullable_to_non_nullable
as bool,snippetSuggestions: null == snippetSuggestions ? _self.snippetSuggestions : snippetSuggestions // ignore: cast_nullable_to_non_nullable
as SnippetSuggestions,wordBasedSuggestions: null == wordBasedSuggestions ? _self.wordBasedSuggestions : wordBasedSuggestions // ignore: cast_nullable_to_non_nullable
as WordBasedSuggestions,parameterHints: null == parameterHints ? _self.parameterHints : parameterHints // ignore: cast_nullable_to_non_nullable
as bool,hover: null == hover ? _self.hover : hover // ignore: cast_nullable_to_non_nullable
as bool,contextMenu: null == contextMenu ? _self.contextMenu : contextMenu // ignore: cast_nullable_to_non_nullable
as bool,find: null == find ? _self.find : find // ignore: cast_nullable_to_non_nullable
as bool,seedSearchStringFromSelection: null == seedSearchStringFromSelection ? _self.seedSearchStringFromSelection : seedSearchStringFromSelection // ignore: cast_nullable_to_non_nullable
as String,accessibilitySupport: null == accessibilitySupport ? _self.accessibilitySupport : accessibilitySupport // ignore: cast_nullable_to_non_nullable
as AccessibilitySupport,accessibilityPageSize: null == accessibilityPageSize ? _self.accessibilityPageSize : accessibilityPageSize // ignore: cast_nullable_to_non_nullable
as int,renderValidationDecorations: null == renderValidationDecorations ? _self.renderValidationDecorations : renderValidationDecorations // ignore: cast_nullable_to_non_nullable
as String,renderControlCharacters: null == renderControlCharacters ? _self.renderControlCharacters : renderControlCharacters // ignore: cast_nullable_to_non_nullable
as bool,disableLayerHinting: null == disableLayerHinting ? _self.disableLayerHinting : disableLayerHinting // ignore: cast_nullable_to_non_nullable
as bool,disableMonospaceOptimizations: null == disableMonospaceOptimizations ? _self.disableMonospaceOptimizations : disableMonospaceOptimizations // ignore: cast_nullable_to_non_nullable
as bool,maxTokenizationLineLength: null == maxTokenizationLineLength ? _self.maxTokenizationLineLength : maxTokenizationLineLength // ignore: cast_nullable_to_non_nullable
as int,languageConfigs: null == languageConfigs ? _self._languageConfigs : languageConfigs // ignore: cast_nullable_to_non_nullable
as Map<String, LanguageConfig>,keybindingPreset: null == keybindingPreset ? _self.keybindingPreset : keybindingPreset // ignore: cast_nullable_to_non_nullable
as KeybindingPresetEnum,customKeybindings: null == customKeybindings ? _self._customKeybindings : customKeybindings // ignore: cast_nullable_to_non_nullable
as Map<String, String>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,domReadOnly: null == domReadOnly ? _self.domReadOnly : domReadOnly // ignore: cast_nullable_to_non_nullable
as bool,dragAndDrop: null == dragAndDrop ? _self.dragAndDrop : dragAndDrop // ignore: cast_nullable_to_non_nullable
as bool,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as bool,mouseWheelZoom: null == mouseWheelZoom ? _self.mouseWheelZoom : mouseWheelZoom // ignore: cast_nullable_to_non_nullable
as bool,mouseWheelScrollSensitivity: null == mouseWheelScrollSensitivity ? _self.mouseWheelScrollSensitivity : mouseWheelScrollSensitivity // ignore: cast_nullable_to_non_nullable
as double,automaticLayout: null == automaticLayout ? _self.automaticLayout : automaticLayout // ignore: cast_nullable_to_non_nullable
as bool,padding: null == padding ? _self._padding : padding // ignore: cast_nullable_to_non_nullable
as Map<String, int>,roundedSelection: null == roundedSelection ? _self.roundedSelection : roundedSelection // ignore: cast_nullable_to_non_nullable
as bool,selectionHighlight: null == selectionHighlight ? _self.selectionHighlight : selectionHighlight // ignore: cast_nullable_to_non_nullable
as bool,occurrencesHighlight: null == occurrencesHighlight ? _self.occurrencesHighlight : occurrencesHighlight // ignore: cast_nullable_to_non_nullable
as String,overviewRulerBorder: null == overviewRulerBorder ? _self.overviewRulerBorder : overviewRulerBorder // ignore: cast_nullable_to_non_nullable
as bool,hideCursorInOverviewRuler: null == hideCursorInOverviewRuler ? _self.hideCursorInOverviewRuler : hideCursorInOverviewRuler // ignore: cast_nullable_to_non_nullable
as bool,scrollbar: null == scrollbar ? _self._scrollbar : scrollbar // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,experimentalFeatures: null == experimentalFeatures ? _self._experimentalFeatures : experimentalFeatures // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
