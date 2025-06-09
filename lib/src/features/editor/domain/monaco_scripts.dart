/// Monaco editor JavaScript scripts used in the editor feature
class MonacoScripts {
  // Private constructor to prevent instantiation
  MonacoScripts._();

  /// Script to check Monaco editor initialization status
  static const String editorReadyCheck = '''
    console.log('[MonacoBridge] Editor ready check:');
    console.log('  - window.editor exists:', !!window.editor);
    console.log('  - setEditorContent exists:', !!window.setEditorContent);
    console.log('  - setEditorLanguage exists:', !!window.setEditorLanguage);
    console.log('  - setEditorOptions exists:', !!window.setEditorOptions);
    if (window.editor) {
      console.log('  - editor model exists:', !!window.editor.getModel());
    }
  ''';

  /// Script to inject live statistics monitoring
  static const String liveStatsMonitoring = '''
    console.log('[Stats Script] Injecting live stats monitoring');
    if (window.__liveStatsHooked) {
      console.log('[Stats Script] Already hooked');
    } else {
      window.__liveStatsHooked = true;
      if (window.editor) {
        const sendStats = () => {
          const model = window.editor.getModel();
          const selection = window.editor.getSelection();
          const selections = window.editor.getSelections() || [];
          
          if (!model || !selection) return;
          
          const stats = {
            event: 'stats',
            lineCount: model.getLineCount(),
            charCount: model.getValueLength(),
            selLines: selection.isEmpty() ? 0 : selection.endLineNumber - selection.startLineNumber + 1,
            selChars: selection.isEmpty() ? 0 : model.getValueInRange(selection).length,
            caretCount: selections.length
          };
          
          if (window.flutterChannel && window.flutterChannel.postMessage) {
            window.flutterChannel.postMessage(JSON.stringify(stats));
          }
        };
        
        window.editor.onDidChangeModelContent(sendStats);
        window.editor.onDidChangeCursorSelection(sendStats);
        sendStats(); // Initial call
      }
    }
  ''';

  /// Script to check if Monaco is properly initialized before setting language
  static String languageCheckScript(String language) => '''
    if (!window.editor) {
      console.error('[MonacoBridge] Editor not found when setting language');
    } else if (!window.setEditorLanguage) {
      console.error('[MonacoBridge] setEditorLanguage function not found');
    } else {
      console.log('[MonacoBridge] Setting language to: $language');
    }
  ''';

  /// Script to verify language was set
  static const String verifyLanguageScript = '''
    if (window.editor && window.editor.getModel()) {
      const currentLang = window.editor.getModel().getLanguageId();
      console.log('[MonacoBridge] Current language after setting: ' + currentLang);
    }
  ''';

  /// Script to scroll to bottom of editor
  static const String scrollToBottomScript = '''
    if (window.editor) {
      const lineCount = window.editor.getModel()?.getLineCount() || 1;
      window.editor.revealLine(lineCount);
    }
  ''';

  /// Script to get editor statistics
  static const String getEditorStatsScript = r"""
    JSON.stringify({
      lineCount: window.editor?.getModel()?.getLineCount() || 0,
      characterCount: window.editor?.getValue()?.length || 0,
      wordCount: (window.editor?.getValue()?.match(/\b\w+\b/g) || []).length,
      selectedText: window.editor?.getSelection()?.isEmpty() === false,
      language: window.editor?.getModel()?.getLanguageId() || 'unknown',
      cursorPosition: window.editor?.getPosition(),
      viewState: {
        scrollTop: window.editor?.getScrollTop() || 0,
        scrollLeft: window.editor?.getScrollLeft() || 0
      },
      selectedLineCount: window.editor?.getSelection()?.isEmpty()
        ? 0
        : (window.editor?.getSelection()?.endLineNumber || 0) - (window.editor?.getSelection()?.startLineNumber || 0) + 1,
      selectedCharCount: window.editor?.getModel()?.getValueInRange(window.editor?.getSelection())?.length || 0
    })
  """;

  /// Script to get debug information about Monaco initialization
  static const String getDebugInfoScript = """
    JSON.stringify({
      editorExists: !!window.editor,
      editorReady: !!(window.editor && window.editor.getModel()),
      currentLanguage: window.editor?.getModel()?.getLanguageId() || 'none',
      availableLanguages: window.monaco?.languages?.getLanguages?.()?.map(l => l.id) || [],
      functionsAvailable: {
        setEditorContent: !!window.setEditorContent,
        setEditorLanguage: !!window.setEditorLanguage,
        setEditorOptions: !!window.setEditorOptions,
        setEditorTheme: !!window.setEditorTheme
      },
      monacoVersion: window.monaco?.editor?.VERSION || 'unknown'
    })
  """;

  /// Script to save editor state
  static const String saveEditorStateScript = '''
    JSON.stringify({
      position: window.editor?.getPosition(),
      selection: window.editor?.getSelection(),
      scrollTop: window.editor?.getScrollTop(),
      scrollLeft: window.editor?.getScrollLeft(),
      viewState: window.editor?.saveViewState()
    })
  ''';

  /// Script to restore editor state
  static String restoreEditorStateScript(String stateJson) => '''
    if (window.editor) {
      const state = $stateJson;
      if (state.viewState) {
        window.editor.restoreViewState(state.viewState);
      } else {
        if (state.position) {
          window.editor.setPosition(state.position);
        }
        if (state.selection) {
          window.editor.setSelection(state.selection);
        }
        if (state.scrollTop !== undefined) {
          window.editor.setScrollPosition({
            scrollTop: state.scrollTop,
            scrollLeft: state.scrollLeft || 0
          });
        }
      }
    }
  ''';

  /// Script to go to a specific line
  static String goToLineScript(int line) => 
    'if (window.editor) { window.editor.revealLineInCenter($line); window.editor.setPosition({ lineNumber: $line, column: 1 }); }';

  /// Generate script for executing Monaco editor actions
  static String executeActionScript(String actionId) => 
    'window.editor?.getAction("$actionId")?.run()';
}
