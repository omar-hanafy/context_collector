import 'package:shared_preferences/shared_preferences.dart';

/// Editor configuration settings
class EditorSettings {
  const EditorSettings({
    this.fontSize = defaultFontSize,
    this.showLineNumbers = defaultShowLineNumbers,
    this.wordWrap = defaultWordWrap,
  });

  static const String keyFontSize = 'editor_font_size';
  static const String keyShowLineNumbers = 'editor_show_line_numbers';
  static const String keyWordWrap = 'editor_word_wrap';

  static const double defaultFontSize = 13;
  static const bool defaultShowLineNumbers = true;
  static const bool defaultWordWrap = false;

  final double fontSize;
  final bool showLineNumbers;
  final bool wordWrap;

  EditorSettings copyWith({
    double? fontSize,
    bool? showLineNumbers,
    bool? wordWrap,
  }) {
    return EditorSettings(
      fontSize: fontSize ?? this.fontSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wordWrap: wordWrap ?? this.wordWrap,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyFontSize, fontSize);
    await prefs.setBool(keyShowLineNumbers, showLineNumbers);
    await prefs.setBool(keyWordWrap, wordWrap);
  }

  static Future<EditorSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return EditorSettings(
      fontSize: prefs.getDouble(keyFontSize) ?? defaultFontSize,
      showLineNumbers:
          prefs.getBool(keyShowLineNumbers) ?? defaultShowLineNumbers,
      wordWrap: prefs.getBool(keyWordWrap) ?? defaultWordWrap,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditorSettings &&
        other.fontSize == fontSize &&
        other.showLineNumbers == showLineNumbers &&
        other.wordWrap == wordWrap;
  }

  @override
  int get hashCode => Object.hash(fontSize, showLineNumbers, wordWrap);

  @override
  String toString() => 'EditorSettings(fontSize: $fontSize, showLineNumbers: $showLineNumbers, wordWrap: $wordWrap)';
}
