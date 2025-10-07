// Path: lib/src/features/editor/data/token_count_provider.dart
import 'dart:async';

import 'package:context_collector/context_collector.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_count_isolate.dart';

class TokenCountState {
  const TokenCountState({
    this.totalTokens,
    this.computing = false,
  });

  final int? totalTokens;
  final bool computing;

  TokenCountState copyWith({int? totalTokens, bool? computing}) {
    return TokenCountState(
      totalTokens: totalTokens ?? this.totalTokens,
      computing: computing ?? this.computing,
    );
  }
}

final tokenCountProvider =
    AutoDisposeStateNotifierProvider<TokenCountNotifier, TokenCountState>(
      TokenCountNotifier.new,
      dependencies: [
        selectionProvider,
        monacoControllerProvider,
      ],
    );

class TokenCountNotifier extends StateNotifier<TokenCountState> {
  TokenCountNotifier(this.ref) : super(const TokenCountState()) {
    _worker = TokenCounterIsolate();

    // React to editor + selection changes.
    _selSub = ref.listen<SelectionState>(
      selectionProvider,
      _onSelectionChanged,
    );
    _ctrlSub = ref.listen<MonacoController?>(
      monacoControllerProvider,
      _onControllerChanged,
    );

    // Kick once in case we already have data.
    _recomputeBaseCombinedTokens();
  }

  final Ref ref;
  late final TokenCounterIsolate _worker;
  ProviderSubscription<SelectionState>? _selSub;
  ProviderSubscription<MonacoController?>? _ctrlSub;

  Timer? _debounce;
  int _epoch = 0;

  // Cached pieces for fast recompute during typing:
  int? _combinedTokens; // tokens(selection.combinedContent)
  int? _activeStaleTokens; // tokens(file.effectiveContent for active file)
  final String _model = 'gpt-4';

  // --------------------------------------------------------------------------
  // Public: notify that user typed; schedule a delta recompute.
  // Called by the StatsRow widget when char/line counts change.
  void notifyUserTyped() {
    _scheduleDeltaRecompute();
  }

  // --------------------------------------------------------------------------
  void _onSelectionChanged(SelectionState? prev, SelectionState next) {
    final combinedChanged = prev?.combinedContent != next.combinedContent;
    final activeChanged = prev?.activeFileId != next.activeFileId;
    final viewingAllChanged = prev?.viewingAll != next.viewingAll;

    if (combinedChanged || activeChanged || viewingAllChanged) {
      _recomputeBaseCombinedTokens();
    }
  }

  void _onControllerChanged(MonacoController? prev, MonacoController? next) {
    // When controller becomes ready or swapped (rare), refresh our caches.
    if (prev != next) {
      _recomputeBaseCombinedTokens();
    }
  }

  // --------------------------------------------------------------------------
  // (1) Recompute the heavy base terms on selection structure changes:
  //     - combinedTokens = tokens(combinedContent)
  //     - activeStaleTokens (if not viewingAll) = tokens(effectiveContent for active file)
  Future<void> _recomputeBaseCombinedTokens() async {
    final s = ref.read(selectionProvider);
    final combined = s.combinedContent; // Whole (selected) content
    final activeId = s.activeFileId;
    final viewingAll = s.viewingAll;

    final myEpoch = ++_epoch;
    state = state.copyWith(computing: true);

    try {
      final futures = <Future<int>>[
        _worker.computeTotal([combined], model: _model),
      ];

      final String? staleActive = (!viewingAll && activeId != null)
          ? s.fileMap[activeId]?.effectiveContent
          : null;

      if (staleActive != null) {
        futures.add(_worker.computeTotal([staleActive], model: _model));
      }

      final results = await Future.wait(futures);
      if (myEpoch != _epoch) return; // stale

      _combinedTokens = results[0];
      _activeStaleTokens = (results.length > 1) ? results[1] : 0;

      // Immediately show an accurate total by also calculating live tokens once.
      await _recomputeDeltaImmediate();
    } catch (_) {
      if (myEpoch != _epoch) return;
      // Keep previous visible; drop computing flag.
      state = state.copyWith(computing: false);
    }
  }

  // (2) Recompute delta quickly while typing (debounced).
  void _scheduleDeltaRecompute() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 220),
      _recomputeDeltaImmediate,
    );
  }

  Future<void> _recomputeDeltaImmediate() async {
    final s = ref.read(selectionProvider);
    final controller = ref.read(monacoControllerProvider);
    final viewingAll = s.viewingAll;

    final base = _combinedTokens ?? 0;
    final stale = (!viewingAll) ? (_activeStaleTokens ?? 0) : 0;

    int live = 0;
    if (!viewingAll && controller != null && s.activeFileId != null) {
      try {
        // Grabbing editor text is async but cheap compared to tokenization.
        final text = await controller.getValue();
        live = await _worker.computeTotal([text], model: _model);
      } catch (_) {
        // If webview read fails, fall back to stale (no live adjustment).
        live = stale;
      }
    } else {
      // In "View all", combined already includes everything that is shown.
      live = 0;
    }

    final total = base - stale + live;
    state = state.copyWith(totalTokens: total, computing: false);
  }

  @override
  Future<void> dispose() async {
    _debounce?.cancel();
    _selSub?.close();
    _ctrlSub?.close();
    await _worker.dispose();
    super.dispose();
  }
}
