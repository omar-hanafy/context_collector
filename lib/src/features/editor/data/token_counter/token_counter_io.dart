import 'dart:async';
import 'dart:isolate';

import 'package:context_collector/src/features/editor/data/token_utils.dart';

/// Messages sent to the worker are simple Maps to stay isolate-safe.
/// `{type: 'compute', id: int, model: String, chunks: List<String>}`
void tokenCountWorker(SendPort mainPort) {
  final commandPort = ReceivePort();
  // Tell main how to send commands to this worker.
  mainPort.send(commandPort.sendPort);

  // Warm the encoder once to reduce first-use latency.
  // (Safe to ignore - it's just priming caches)
  unawaited(
    Future(() {
      // A small call so _encodingForModel() runs in this isolate
      countTokens('', model: 'gpt-4');
    }),
  );

  commandPort.listen((message) async {
    if (message is! Map) return;
    final type = message['type'] as String? ?? '';
    if (type == 'dispose') {
      commandPort.close();
      Isolate.current.kill(priority: Isolate.immediate);
      return;
    }
    if (type != 'compute') return;

    final int id = message['id'] as int;
    final String model = (message['model'] as String?) ?? 'gpt-4';
    final List<dynamic> raw = message['chunks'] as List<dynamic>? ?? const [];
    final List<String> chunks = raw.cast<String>();

    int total = 0;
    try {
      // Sum over chunks to avoid building one gigantic string.
      for (final s in chunks) {
        total += countTokens(s, model: model);
      }
      mainPort.send(<String, Object?>{'id': id, 'ok': true, 'total': total});
    } catch (e) {
      mainPort.send(<String, Object?>{
        'id': id,
        'ok': false,
        'error': e.toString(),
      });
    }
  });
}

/// Isolate-backed token counter: manages the worker lifecycle and requests.
class TokenCounter {
  TokenCounter();

  Isolate? _isolate;
  ReceivePort? _receive;
  SendPort? _command;
  int _nextId = 0;
  final Map<int, Completer<int>> _inflight = {};

  Future<void> start() async {
    if (_isolate != null) return;
    _receive = ReceivePort();
    _isolate = await Isolate.spawn(tokenCountWorker, _receive!.sendPort);

    // The first message from the worker is its command SendPort.
    final completer = Completer<void>();
    _receive!.listen((msg) {
      if (_command == null && msg is SendPort) {
        _command = msg;
        completer.complete();
        return;
      }
      if (msg is Map) {
        final int id = msg['id'] as int;
        final ok = msg['ok'] == true;
        final c = _inflight.remove(id);
        if (c == null) return;
        if (ok) {
          c.complete(msg['total'] as int);
        } else {
          c.completeError(
            StateError(msg['error']?.toString() ?? 'Token worker error'),
          );
        }
      }
    });

    await completer.future;
  }

  Future<int> computeTotal(
    List<String> chunks, {
    String model = 'gpt-4',
  }) async {
    await start();
    final id = ++_nextId;
    final c = Completer<int>();
    _inflight[id] = c;
    _command!.send(<String, Object?>{
      'type': 'compute',
      'id': id,
      'model': model,
      'chunks': chunks,
    });
    return c.future;
  }

  Future<void> dispose() async {
    if (_isolate == null) return;
    try {
      _command?.send(<String, Object?>{'type': 'dispose'});
    } catch (_) {}
    _receive?.close();
    for (final c in _inflight.values) {
      if (!c.isCompleted) c.completeError(StateError('Token worker disposed'));
    }
    _inflight.clear();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receive = null;
    _command = null;
  }
}
