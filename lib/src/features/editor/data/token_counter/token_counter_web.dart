import 'dart:async';

import 'package:context_collector/src/features/editor/data/token_utils.dart';

/// Web token counter: `Isolate.spawn` is unavailable in browsers, so chunks
/// are tokenized on the main isolate with an event-loop yield between chunks
/// to keep the UI responsive.
class TokenCounter {
  TokenCounter();

  bool _disposed = false;
  bool _warmedUp = false;

  Future<void> start() async {
    if (_warmedUp) return;
    _warmedUp = true;
    // Warm the encoder once to reduce first-use latency.
    countTokens('', model: 'gpt-4');
  }

  Future<int> computeTotal(
    List<String> chunks, {
    String model = 'gpt-4',
  }) async {
    await start();
    var total = 0;
    for (final chunk in chunks) {
      if (_disposed) {
        throw StateError('Token worker disposed');
      }
      total += countTokens(chunk, model: model);
      // Yield so long token counts don't starve the event loop.
      await Future<void>.delayed(Duration.zero);
    }
    return total;
  }

  Future<void> dispose() async {
    _disposed = true;
  }
}
