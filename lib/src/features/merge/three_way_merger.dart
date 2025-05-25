import 'dart:isolate';

import 'package:diff_match_patch/diff_match_patch.dart';

class ThreeWayMerger {
  factory ThreeWayMerger() => _instance;
  ThreeWayMerger._internal();
  static final _instance = ThreeWayMerger._internal();

  final _dmp = DiffMatchPatch(); // OO wrapper

  Future<(String, bool)> merge({
    required String base,
    required String local,
    required String remote,
  }) async {
    // fast outs
    if (base == local) return (remote, false);
    if (base == remote) return (local, false);
    if (local == remote) return (local, false);

    base = base.replaceAll('\r\n', '\n');
    local = local.replaceAll('\r\n', '\n');
    remote = remote.replaceAll('\r\n', '\n');

    // Run in isolate for large files, otherwise run directly
    if ([base, local, remote].any((t) => t.length > 300000)) {
      return Isolate.run<(String, bool)>(
        () => _inner(base, local, remote),
      );
    } else {
      return _inner(base, local, remote);
    }
  }

  Future<bool> wouldHaveConflicts({
    required String base,
    required String local,
    required String remote,
  }) async =>
      (await merge(base: base, local: local, remote: remote)).$2;

  // ------------------------------------------------------------------

  (String, bool) _inner(String base, String local, String remote) {
    try {
      final localPatches = _dmp.patch(base, local); // <-- wrapper call
      final localApplied = _dmp.patch_apply(localPatches, base);
      var merged = localApplied[0] as String;

      final remotePatches = _dmp.patch(base, remote); // <-- wrapper call
      final remoteApplied = _dmp.patch_apply(remotePatches, merged);
      merged = remoteApplied[0] as String;
      final hadConflicts = (remoteApplied[1] as List<bool>).contains(false);

      return (merged, hadConflicts);
    } catch (_) {
      // any unexpected failure ⇒ keep user text, flag conflict
      return (local, true);
    }
  }
}
