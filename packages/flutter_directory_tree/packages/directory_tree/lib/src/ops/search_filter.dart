// lib/src/ops/search_filter.dart
typedef Predicate = bool Function(String name, String? ext);

/// Parse a query like "foo ext:dart !bar" into a predicate:
/// - plain tokens => substring (case-insensitive)
/// - ext:xyz       => file extension equals ".xyz"
/// - !token        => negated substring
Predicate compileFilter(String? query) {
  if (query == null) return _alwaysTrue;
  final raw = query.trim();
  if (raw.isEmpty) return _alwaysTrue;

  final tokens = raw.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final checks = <Predicate>[];

  for (final t in tokens) {
    if (t.startsWith('ext:')) {
      final want = '.${t.substring(4).toLowerCase()}';
      checks.add((_, ext) => ext?.toLowerCase() == want);
    } else if (t.startsWith('!')) {
      final s = t.substring(1).toLowerCase();
      checks.add((name, _) => !name.toLowerCase().contains(s));
    } else {
      final s = t.toLowerCase();
      checks.add((name, _) => name.toLowerCase().contains(s));
    }
  }

  return (name, ext) => checks.every((c) => c(name, ext));
}

bool _alwaysTrue(String _, String? extensionName) => true;
