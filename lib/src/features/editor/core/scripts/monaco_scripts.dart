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
  static String languageCheckScript(String language) =>
      '''
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

  /// Script to scroll to bottom of editor
  static const String scrollToTopScript =
      'window.editor?.setScrollPosition({ scrollTop: 0 })';

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
  static String restoreEditorStateScript(String stateJson) =>
      '''
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

  /// Script to check Windows editor readiness and force ready event if needed
  static String windowsReadinessCheckScript(int checkCount) =>
      '''
    (function() {
      console.log('[Ready Check] Checking environment...');
      const status = {
        hasRequire: typeof require !== 'undefined',
        hasMonaco: typeof monaco !== 'undefined',
        hasEditor: typeof window.editor !== 'undefined',
        hasFlutterChannel: typeof window.flutterChannel !== 'undefined',
        documentReady: document.readyState === 'complete',
        monacoStatus: window.monacoStatus || {}
      };
      console.log('[Ready Check] Status:', JSON.stringify(status, null, 2));
      
      // If editor exists but we haven't sent ready event, force it
      if (status.hasEditor && status.hasFlutterChannel && window.editor) {
        console.log('[Ready Check] Editor found! Forcing ready event...');
        
        // Make sure all API functions are available
        if (!window.setEditorContent) {
          window.setEditorContent = function(content) {
            if (window.editor) window.editor.setValue(content || '');
          };
        }
        if (!window.getEditorContent) {
          window.getEditorContent = function() {
            return window.editor ? window.editor.getValue() : '';
          };
        }
        if (!window.setEditorLanguage) {
          window.setEditorLanguage = function(language) {
            if (window.editor && window.editor.getModel()) {
              monaco.editor.setModelLanguage(window.editor.getModel(), language);
            }
          };
        }
        if (!window.setEditorTheme) {
          window.setEditorTheme = function(theme) {
            if (monaco) monaco.editor.setTheme(theme);
          };
        }
        if (!window.setEditorOptions) {
          window.setEditorOptions = function(options) {
            if (window.editor) window.editor.updateOptions(options);
          };
        }
        
        // Send ready event
        window.flutterChannel.postMessage(JSON.stringify({
          event: 'onEditorReady',
          payload: {
            detail: 'Windows editor ready (forced)',
            checkCount: $checkCount
          }
        }));
        
        // Stop checking after sending ready
        return true;
      } else if (!status.hasRequire && status.documentReady) {
        console.error('[Ready Check] CRITICAL: require is not defined after document ready!');
        window.flutterChannel.postMessage(JSON.stringify({
          event: 'error',
          message: 'require is not defined - Monaco loader failed'
        }));
        return true; // Stop checking
      }
      
      return false; // Continue checking
    })();
  ''';

  /// Script to inject readiness detection for non-Windows platforms
  static const String nonWindowsReadinessDetectionScript = '''
    // Listen for console logs that indicate editor is ready
    const originalLog = console.log;
    console.log = function(...args) {
      originalLog.apply(console, args);
      const message = args.join(' ');
      
      // Check for various ready indicators
      if (message.includes('Monaco editor instance created') ||
          message.includes('ENHANCED_EDITOR_READY_EVENT_FIRED') ||
          message.includes('onEditorReady')) {
        if (window.flutterChannel) {
          window.flutterChannel.postMessage(JSON.stringify({
            event: 'onEditorReady',
            detail: 'Editor ready detected from console'
          }));
        }
      }
    };

    // Also check periodically
    setTimeout(function checkReady() {
      if (window.editor && window.flutterChannel) {
        window.flutterChannel.postMessage(JSON.stringify({
          event: 'onEditorReady',
          detail: 'Editor ready via periodic check'
        }));
      } else {
        setTimeout(checkReady, 1000);
      }
    }, 1000);
  ''';
}
