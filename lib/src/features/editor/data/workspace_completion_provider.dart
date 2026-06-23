import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scan/models/scanned_file.dart';
import '../../scan/state/file_list_state.dart';
import '../../scan/ui/file_display_helper.dart';
import 'providers.dart';

/// Keeps Monaco wired to workspace-wide completions for the current session.
final workspaceCompletionProvider =
    AutoDisposeProvider<WorkspaceCompletionService>(
      (ref) {
        final service = WorkspaceCompletionService(ref);
        ref.onDispose(service.dispose);
        return service;
      },
      dependencies: [selectionProvider, monacoControllerProvider],
    );

class WorkspaceCompletionService {
  WorkspaceCompletionService(this.ref) {
    _selectionSub = ref.listen<SelectionState>(
      selectionProvider,
      _handleSelectionChanged,
    );

    _controllerSub = ref.listen<MonacoController?>(
      monacoControllerProvider,
      _handleControllerChanged,
    );

    _reindexWorkspace(ref.read(selectionProvider));
    final controller = ref.read(monacoControllerProvider);
    if (controller != null) {
      unawaited(_attachToController(controller));
    }
  }

  final Ref ref;
  ProviderSubscription<SelectionState>? _selectionSub;
  ProviderSubscription<MonacoController?>? _controllerSub;

  final Map<String, _IndexedFile> _indexedFiles = {};
  final Map<String, String> _fileSignatures = {};

  MonacoController? _controller;
  String? _completionId;
  VoidCallback? _liveStatsDispose;
  Timer? _typingDebounce;
  bool _isDisposed = false;

  static final List<String> _allLanguages = MonacoLanguage.values
      .map((lang) => lang.id)
      .toList(growable: false);
  static final List<String> _triggerCharacters = const [
    46,
    95,
    45,
    47,
    92,
    39,
    34,
    58,
  ].map(String.fromCharCode).toList(growable: false);

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _selectionSub?.close();
    _selectionSub = null;
    _controllerSub?.close();
    _controllerSub = null;
    _typingDebounce?.cancel();
    _typingDebounce = null;
    _liveStatsDispose?.call();
    _liveStatsDispose = null;
    unawaited(_detachFromController(_controller));
  }

  void _handleSelectionChanged(SelectionState? previous, SelectionState next) {
    if (_isDisposed) return;
    _pruneMissingFiles(next);

    for (final entry in next.fileMap.entries) {
      final file = entry.value;
      // Optimization: Skip re-indexing if the file object instance hasn't changed.
      // ScannedFile is immutable, so identical instance means identical content.
      if (previous != null) {
        final prevFile = previous.fileMap[file.id];
        if (identical(prevFile, file)) continue;
      }
      _indexFileIfNeeded(file);
    }
  }

  void _pruneMissingFiles(SelectionState state) {
    final removed = _indexedFiles.keys
        .where((id) => !state.fileMap.containsKey(id))
        .toList(growable: false);
    for (final id in removed) {
      _indexedFiles.remove(id);
      _fileSignatures.remove(id);
    }
  }

  void _reindexWorkspace(SelectionState state) {
    for (final file in state.fileMap.values) {
      _indexFileIfNeeded(file, force: true);
    }
  }

  void _handleControllerChanged(
    MonacoController? previous,
    MonacoController? next,
  ) {
    if (previous == next || _isDisposed) return;
    unawaited(_swapControllers(previous, next));
  }

  Future<void> _swapControllers(
    MonacoController? previous,
    MonacoController? next,
  ) async {
    await _detachFromController(previous);
    if (next != null && !_isDisposed) {
      await _attachToController(next);
    }
  }

  Future<void> _detachFromController(MonacoController? controller) async {
    if (controller == null) return;
    if (identical(controller, _controller)) {
      _controller = null;
    }
    final id = _completionId;
    _completionId = null;
    _liveStatsDispose?.call();
    _liveStatsDispose = null;
    if (id != null) {
      try {
        await controller.unregisterCompletionSource(id);
      } catch (err) {
        debugPrint('workspace completions: detach failed ($err)');
      }
    }
  }

  Future<void> _attachToController(MonacoController controller) async {
    _controller = controller;
    _liveStatsDispose?.call();
    controller.liveStats.addListener(_handleLiveStatsEvent);
    _liveStatsDispose = () =>
        controller.liveStats.removeListener(_handleLiveStatsEvent);

    try {
      _completionId = await controller.registerCompletionSource(
        languages: _allLanguages,
        triggerCharacters: _triggerCharacters,
        provider: _provideCompletions,
      );
    } catch (err) {
      debugPrint('workspace completions: registration failed ($err)');
      _completionId = null;
    }
  }

  void _handleLiveStatsEvent() {
    _scheduleLiveReindex();
  }

  Future<void> _scheduleLiveReindex() async {
    if (_isDisposed) return;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(
      const Duration(milliseconds: 220),
      () => unawaited(_captureActiveEditorText()),
    );
  }

  Future<void> _captureActiveEditorText() async {
    if (_isDisposed) return;
    final controller = _controller;
    if (controller == null) return;
    final selection = ref.read(selectionProvider);
    if (selection.viewingAll) return;
    if (!selection.editorIsBoundToActiveFile) return;
    final activeId = selection.activeFileId;
    if (activeId == null) return;
    final file = selection.fileMap[activeId];
    if (file == null) return;
    try {
      final text = await controller.getValue();
      _indexFileIfNeeded(file, overrideText: text, force: true);
    } catch (_) {
      // Ignore transient webview read failures.
    }
  }

  void _indexFileIfNeeded(
    ScannedFile file, {
    bool force = false,
    String? overrideText,
  }) {
    final text = overrideText ?? file.effectiveContent;
    final languageId = FileDisplayHelper.getLanguageFromFile(file);
    final signature = _signatureFor(file, text, languageId);
    if (!force && _fileSignatures[file.id] == signature) {
      return;
    }
    _fileSignatures[file.id] = signature;

    final symbols = _extractSymbols(
      file: file,
      languageId: languageId,
      text: text,
    );

    _indexedFiles[file.id] = _IndexedFile(
      fileId: file.id,
      fileName: file.name,
      relativePath: file.relativePath,
      languageId: languageId,
      symbols: symbols,
    );
  }

  Future<CompletionList> _provideCompletions(CompletionRequest request) async {
    final selection = ref.read(selectionProvider);
    final activeId = selection.activeFileId;
    final word = _currentWord(request);
    final normalized = word.toLowerCase();
    final language = request.language.isEmpty ? 'plaintext' : request.language;

    final filtered = <_ScoredSymbol>[];
    final seen = <String>{};
    final bool hasPrefix = normalized.isNotEmpty;
    final selectedIds = selection.selectedFileIds;

    for (final entry in _prioritizedSymbols(selection)) {
      if (hasPrefix && !entry.normalized.startsWith(normalized)) {
        continue;
      }
      final dedupeKey = '${entry.fileId}::${entry.normalized}';
      if (!seen.add(dedupeKey)) continue;
      var score = entry.weight;
      final indexed = _indexedFiles[entry.fileId];
      if (indexed?.languageId == language) {
        score += 1.5;
      }
      if (selectedIds.contains(entry.fileId)) {
        score += 1.0;
      }
      if (entry.fileId == activeId) {
        score += 2.0;
      }
      filtered.add(_ScoredSymbol(entry, score));
    }

    if (filtered.isEmpty) {
      return const CompletionList(suggestions: []);
    }

    filtered.sort((a, b) => b.score.compareTo(a.score));
    final items = filtered
        .take(60)
        .map((scored) {
          final entry = scored.entry;
          return CompletionItem(
            label: entry.label,
            insertText: entry.label,
            kind: entry.kind,
            detail: entry.relativePath,
            sortText: _sortForScore(scored.score),
            range: request.defaultRange,
          );
        })
        .toList(growable: false);

    return CompletionList(suggestions: items, isIncomplete: false);
  }

  Iterable<_SymbolEntry> _prioritizedSymbols(SelectionState selection) sync* {
    final yieldedFileIds = <String>{};
    if (selection.selectedFileIds.isNotEmpty) {
      for (final id in selection.selectedFileIds) {
        final entry = _indexedFiles[id];
        if (entry == null) continue;
        if (!yieldedFileIds.add(id)) continue;
        yield* entry.symbols;
      }
    }
    for (final entry in _indexedFiles.values) {
      if (yieldedFileIds.contains(entry.fileId)) continue;
      yieldedFileIds.add(entry.fileId);
      yield* entry.symbols;
    }
  }

  String _signatureFor(ScannedFile file, String text, String languageId) {
    return '${text.length}:${text.hashCode}:${file.name}:${file.relativePath}:$languageId';
  }

  String _currentWord(CompletionRequest request) {
    final line = request.lineText ?? '';
    if (line.isEmpty) return '';
    var index = request.position.column - 1;
    if (index < 0) index = 0;
    if (index > line.length) index = line.length;
    final prefix = line.substring(0, index);
    final match = RegExp(r'([A-Za-z0-9_./\\-]+)$').firstMatch(prefix);
    return match?.group(1) ?? '';
  }
}

class _IndexedFile {
  const _IndexedFile({
    required this.fileId,
    required this.fileName,
    required this.relativePath,
    required this.languageId,
    required this.symbols,
  });

  final String fileId;
  final String fileName;
  final String relativePath;
  final String languageId;
  final List<_SymbolEntry> symbols;
}

class _SymbolEntry {
  const _SymbolEntry({
    required this.fileId,
    required this.relativePath,
    required this.label,
    required this.normalized,
    required this.kind,
    required this.weight,
  });

  final String fileId;
  final String relativePath;
  final String label;
  final String normalized;
  final CompletionItemKind kind;
  final double weight;
}

class _ScoredSymbol {
  const _ScoredSymbol(this.entry, this.score);
  final _SymbolEntry entry;
  final double score;
}

class _SymbolAccumulator {
  _SymbolAccumulator({
    required this.label,
    required this.normalized,
    required this.kind,
  });

  String label;
  final String normalized;
  CompletionItemKind kind;
  double weight = 0;

  void bump(CompletionItemKind candidate, double delta) {
    weight += delta;
    if (candidate != CompletionItemKind.text &&
        kind == CompletionItemKind.text) {
      kind = candidate;
    }
  }
}

const _maxSymbolsPerFile = 200;

List<_SymbolEntry> _extractSymbols({
  required ScannedFile file,
  required String languageId,
  required String text,
}) {
  final accumulator = <String, _SymbolAccumulator>{};

  void record(String value, CompletionItemKind kind, {double weight = 1}) {
    final trimmed = value.trim();
    if (trimmed.length < 2) return;
    final normalized = trimmed.toLowerCase();
    accumulator
        .putIfAbsent(
          normalized,
          () => _SymbolAccumulator(
            label: trimmed,
            normalized: normalized,
            kind: kind,
          ),
        )
        .bump(kind, weight);
  }

  record(file.name, CompletionItemKind.file, weight: 3);
  for (final segment
      in file.relativePath.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty)) {
    record(segment, CompletionItemKind.folder, weight: 1.5);
  }

  void scan(RegExp pattern, CompletionItemKind kind, {double weight = 2.5}) {
    for (final match in pattern.allMatches(text)) {
      if (accumulator.length >= _maxSymbolsPerFile) break;
      final label = match.groupCount >= 1
          ? (match.group(1) ?? match.group(0) ?? '')
          : (match.group(0) ?? '');
      if (label.isEmpty) continue;
      record(label, kind, weight: weight);
    }
  }

  switch (languageId) {
    case 'dart':
    case 'kotlin':
    case 'swift':
      scan(
        RegExp(r'\bclass\s+([A-Za-z_]\w*)'),
        CompletionItemKind.classType,
        weight: 3,
      );
      scan(
        RegExp(r'\b(?:void|final|var|late|const)?\s*([A-Za-z_]\w*)\s*\('),
        CompletionItemKind.functionType,
        weight: 2.5,
      );
    case 'typescript':
    case 'javascript':
      scan(
        RegExp(r'\bclass\s+([A-Za-z_]\w*)'),
        CompletionItemKind.classType,
        weight: 3,
      );
      scan(
        RegExp(r'\bfunction\s+([A-Za-z_]\w*)'),
        CompletionItemKind.functionType,
        weight: 2.5,
      );
      scan(
        RegExp(r'\b(const|let|var)\s+([A-Za-z_]\w*)'),
        CompletionItemKind.variable,
        weight: 2,
      );
    case 'python':
      scan(
        RegExp(r'\bclass\s+([A-Za-z_]\w*)'),
        CompletionItemKind.classType,
        weight: 3,
      );
      scan(
        RegExp(r'\bdef\s+([A-Za-z_]\w*)'),
        CompletionItemKind.functionType,
        weight: 2.5,
      );
    case 'markdown':
      scan(
        RegExp(r'^\s{0,3}#{1,6}\s+(.+)$', multiLine: true),
        CompletionItemKind.keyword,
        weight: 2.5,
      );
  }

  final wordPattern = RegExp(r'[A-Za-z_][A-Za-z0-9_\-]{2,}');
  for (final match in wordPattern.allMatches(text)) {
    if (accumulator.length >= _maxSymbolsPerFile) break;
    final label = match.group(0);
    if (label == null) continue;
    record(label, CompletionItemKind.text, weight: 1);
  }

  return accumulator.values
      .map(
        (entry) => _SymbolEntry(
          fileId: file.id,
          relativePath: file.relativePath,
          label: entry.label,
          normalized: entry.normalized,
          kind: entry.kind,
          weight: entry.weight,
        ),
      )
      .toList(growable: false);
}

String _sortForScore(double score) {
  final raw = 100000 - (score * 1000).round();
  final clamped = raw.clamp(0, 999999) as num;
  final value = clamped.toInt();
  return value.toString().padLeft(6, '0');
}
