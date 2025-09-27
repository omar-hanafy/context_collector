// lib/src/ops/path_utils.dart
import 'package:path/path.dart' as p;

String basename(String pathOrName) => p.basename(pathOrName);
String extensionLower(String pathOrName) =>
    p.extension(pathOrName).toLowerCase();

/// Returns true if [candidate] ends with any of [extensions] (case-insensitive).
bool hasAnyExtension(String candidate, Iterable<String> extensions) {
  final ext = extensionLower(candidate);
  for (final e in extensions) {
    if (ext == e.toLowerCase()) return true;
  }
  return false;
}
