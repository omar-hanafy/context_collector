enum MonacoActions {
  format('editor.action.formatDocument'),
  find('actions.find'),
  replace('editor.action.startFindReplaceAction'),
  gotoLine('editor.action.gotoLine'),
  toggleWordWrap('editor.action.toggleWordWrap'),
  toggleMinimap('editor.action.toggleMinimap'),
  toggleLineComment('editor.action.commentLine'),
  toggleBlockComment('editor.action.blockComment'),
  triggerSuggest('editor.action.triggerSuggest'),
  showCommandPalette('editor.action.quickCommand'),
  foldAll('editor.foldAll'),
  unfoldAll('editor.unfoldAll'),
  selectAll('editor.action.selectAll'),
  undo('undo'),
  redo('redo'),
  cut('editor.action.clipboardCutAction'),
  copy('editor.action.clipboardCopyAction'),
  paste('editor.action.clipboardPasteAction'),
  increaseFontSize('editor.action.fontZoomIn'),
  decreaseFontSize('editor.action.fontZoomOut'),
  resetFontSize('editor.action.fontZoomReset');

  const MonacoActions(this.command);

  final String command;
}

/// Monaco editor JavaScript scripts used in the editor feature
class MonacoScripts {
  // Private constructor to prevent instantiation
  MonacoScripts._();

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

  /// Script to scroll to bottom of editor
  static const String scrollToBottomScript = '''
    if (window.editor && window.editor.getModel()) {
      const lineCount = window.editor.getModel().getLineCount();
      window.editor.revealLineInCenterIfOutsideViewport(lineCount);
      window.editor.setPosition({ lineNumber: lineCount, column: 1 });
    }
  ''';

  /// Script to scroll to top of editor
  static const String scrollToTopScript = '''
    if (window.editor) {
      window.editor.setScrollPosition({ scrollTop: 0, scrollLeft: 0 });
      window.editor.setPosition({ lineNumber: 1, column: 1 });
      window.editor.revealLineInCenterIfOutsideViewport(1);
    }
  ''';

  /// Script to go to a specific line
  static String goToLineScript(int line) =>
      'if (window.editor) { window.editor.revealLineInCenter($line); window.editor.setPosition({ lineNumber: $line, column: 1 }); }';

  /// Script to create flutterChannel for Windows WebView2
  static const String windowsFlutterChannelScript = '''
    // Create flutterChannel immediately when document is created
    console.log('[Windows Init] Creating flutterChannel on document creation');
    window.flutterChannel = {
      postMessage: function(msg) {
        console.log('[flutterChannel] Posting message:', msg);
        if (window.chrome && window.chrome.webview) {
          window.chrome.webview.postMessage(msg);
        } else {
          console.error('[flutterChannel] WebView2 API not available!');
        }
      }
    };
    console.log('[Windows Init] flutterChannel created successfully');
  ''';
}
