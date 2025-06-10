import 'package:context_collector/context_collector.dart';

/// Mixin containing a comprehensive set of Monaco Editor action methods.
///
/// By using this mixin, a class gains a rich API for controlling the editor
/// without needing to know the underlying command IDs or JavaScript implementation.
mixin MonacoEditorActions {
  /// Executes a specific editor action by its ID, with optional arguments.
  ///
  /// This method must be implemented by the class using the mixin. It serves
  /// as the core bridge to the editor's action system.
  ///
  /// - [actionId]: The command identifier for the action (e.g., 'editor.action.formatDocument').
  /// - [args]: An optional payload for actions that require it (e.g., line number).
  Future<void> executeEditorAction(String actionId, [dynamic args]);

  /// Format the entire document.
  Future<void> format() async =>
      executeEditorAction(MonacoActions.format.command);

  /// Open the find widget.
  Future<void> find() async => executeEditorAction(MonacoActions.find.command);

  /// Open the replace widget.
  Future<void> replace() async =>
      executeEditorAction(MonacoActions.replace.command);

  /// Open the "Go to Line" dialog.
  /// To programmatically go to a line, use `executeEditorAction` directly:
  /// `executeEditorAction('editor.action.revealLine', {'lineNumber': 10})`
  Future<void> gotoLine() async =>
      executeEditorAction(MonacoActions.gotoLine.command);

  /// Toggle word wrap.
  Future<void> toggleWordWrap() async =>
      executeEditorAction(MonacoActions.toggleWordWrap.command);

  /// Toggle the minimap.
  Future<void> toggleMinimap() async =>
      executeEditorAction(MonacoActions.toggleMinimap.command);

  /// Toggle a line comment.
  Future<void> toggleLineComment() async =>
      executeEditorAction(MonacoActions.toggleLineComment.command);

  /// Toggle a block comment.
  Future<void> toggleBlockComment() async =>
      executeEditorAction(MonacoActions.toggleBlockComment.command);

  /// Trigger the auto-completion suggestion box.
  Future<void> triggerSuggest() async =>
      executeEditorAction(MonacoActions.triggerSuggest.command);

  /// Show the command palette.
  Future<void> showCommandPalette() async =>
      executeEditorAction(MonacoActions.showCommandPalette.command);

  /// Fold all collapsible code blocks.
  Future<void> foldAll() async =>
      executeEditorAction(MonacoActions.foldAll.command);

  /// Unfold all folded code blocks.
  Future<void> unfoldAll() async =>
      executeEditorAction(MonacoActions.unfoldAll.command);

  /// Select all content in the editor.
  Future<void> selectAll() async =>
      executeEditorAction(MonacoActions.selectAll.command);

  /// Undo the last action.
  Future<void> undo() async => executeEditorAction(MonacoActions.undo.command);

  /// Redo the last undone action.
  Future<void> redo() async => executeEditorAction(MonacoActions.redo.command);

  /// Cut the selected content.
  Future<void> cut() async => executeEditorAction(MonacoActions.cut.command);

  /// Copy the selected content.
  Future<void> copy() async => executeEditorAction(MonacoActions.copy.command);

  /// Paste content from the clipboard.
  Future<void> paste() async =>
      executeEditorAction(MonacoActions.paste.command);

  /// Increase the editor's font size.
  Future<void> increaseFontSize() async =>
      executeEditorAction(MonacoActions.increaseFontSize.command);

  /// Decrease the editor's font size.
  Future<void> decreaseFontSize() async =>
      executeEditorAction(MonacoActions.decreaseFontSize.command);

  /// Reset the editor's font size to its default.
  Future<void> resetFontSize() async =>
      executeEditorAction(MonacoActions.resetFontSize.command);
}
