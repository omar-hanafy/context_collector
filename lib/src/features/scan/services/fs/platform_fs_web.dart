import 'dart:js_interop';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;

import '../../models/scan_result.dart';
import '../../models/scanned_file.dart';
import 'scan_filters.dart';

/// Web implementation of the scan platform primitives.
///
/// Browsers expose no filesystem paths, so [ScannedFile.fullPath] holds a
/// pseudo-path built from the drop/pick relative location (e.g.
/// `/my-project/lib/main.dart`). The actual browser file handles are kept in
/// an in-memory registry keyed by [ScannedFile.id] and read lazily.
class PlatformFs {
  const PlatformFs._();

  /// Browsers never expose real absolute paths.
  static const bool supportsAbsolutePaths = false;

  /// Web exports are assembled in memory and downloaded as a single blob.
  static const bool supportsStreamingExport = false;

  /// Registry of browser file handles backing non-virtual [ScannedFile]s.
  static final Map<String, XFile> _handles = <String, XFile>{};

  /// No home directory in a browser.
  static String? get userHomeDirectory => null;

  /// Arbitrary paths are never readable from a browser.
  static bool pathExists(String path) => false;

  /// Files cannot be created from bare paths on web.
  static ScannedFile scannedFileFromPathSync(
    String filePath, {
    String? relativePath,
    ScanSource source = ScanSource.browse,
  }) {
    throw UnsupportedError(
      'ScannedFile creation from a filesystem path is not supported on web',
    );
  }

  /// Size recorded when the file was dropped/picked; null when the browser
  /// handle is gone (e.g. after a session restore).
  static Future<int?> fileSizeOf(ScannedFile file) async {
    if (!_handles.containsKey(file.id)) return null;
    return file.size;
  }

  /// Bytes of the browser file handle backing [file], or null when the
  /// handle is unknown.
  static Future<Uint8List?> readFileBytes(ScannedFile file) async {
    final handle = _handles[file.id];
    if (handle == null) return null;
    return handle.readAsBytes();
  }

  /// Directory paths cannot be scanned on web; folders arrive pre-expanded
  /// through drag-and-drop instead.
  static Future<void> scanDirectory({
    required String directoryPath,
    required Set<String> blacklist,
    required void Function(List<ScannedFile> files) onBatchFound,
    required ScanSource source,
  }) {
    throw UnsupportedError('Directory scanning is not supported on web');
  }

  /// Expands dropped/picked items into [ScannedFile] batches.
  ///
  /// Directory drops arrive as [DropItemDirectory] trees (desktop_drop reads
  /// them via the browser's webkit directory entries), so the walk happens
  /// over the already-materialized tree rather than a filesystem.
  static Future<void> expandDroppedItems({
    required List<XFile> items,
    required Set<String> blacklist,
    required ScanSource source,
    required void Function(List<ScannedFile> files) onBatchFound,
    required void Function(List<String> sourcePaths) onScanComplete,
  }) async {
    final sourcePaths = <String>{};
    final seenPseudoPaths = <String>{};
    final batch = <ScannedFile>[];

    void flush() {
      if (batch.isNotEmpty) {
        onBatchFound(List.from(batch));
        batch.clear();
      }
    }

    Future<void> walk(XFile item, String parentPath) async {
      final name = item.name.isNotEmpty ? item.name : p.basename(item.path);

      if (item is DropItemDirectory) {
        if (name.startsWith('.') || kIgnoredDirectoryNames.contains(name)) {
          return;
        }
        final dirPath = parentPath.isEmpty ? name : '$parentPath/$name';
        for (final child in item.children) {
          await walk(child, dirPath);
        }
        return;
      }

      if (name.startsWith('.')) return;
      if (isBlacklistedFileName(name, blacklist)) return;

      final relativePath = parentPath.isEmpty ? name : '$parentPath/$name';
      final file = await _fromXFile(
        item,
        relativePath: relativePath,
        source: source,
      );
      if (!seenPseudoPaths.add(file.fullPath)) return;

      batch.add(file);
      if (batch.length >= 200) flush();
    }

    for (final item in items) {
      if (item is DropItemDirectory) {
        sourcePaths.add('/${item.name}');
      } else {
        sourcePaths.add('/');
      }
      await walk(item, '');
    }

    flush();
    onScanComplete(sourcePaths.toList());
  }

  /// Triggers a browser download of [content] named [suggestedName].
  static Future<void> saveTextFile({
    required String suggestedName,
    required String content,
  }) async {
    final blob = web.Blob(
      <JSAny>[content.toJS].toJS,
      web.BlobPropertyBag(type: 'text/markdown'),
    );
    final url = web.URL.createObjectURL(blob);
    try {
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = suggestedName
        ..style.display = 'none';
      web.document.body?.append(anchor);
      anchor
        ..click()
        ..remove();
    } finally {
      web.URL.revokeObjectURL(url);
    }
  }

  /// Never called on web: `supportsStreamingExport` is false, so callers
  /// build the content in memory and use [saveTextFile] instead.
  static Future<void> exportCollectionStreaming(List<ScannedFile> files) {
    throw UnsupportedError('Streaming export is not supported on web');
  }

  static Future<ScannedFile> _fromXFile(
    XFile item, {
    required String relativePath,
    required ScanSource source,
  }) async {
    var size = 0;
    var modified = DateTime.now();
    try {
      size = await item.length();
    } catch (_) {}
    try {
      modified = await item.lastModified();
    } catch (_) {}

    final name = item.name.isNotEmpty ? item.name : p.basename(item.path);
    final pseudoPath = p.posix.normalize('/$relativePath');
    final id =
        'web_${pseudoPath.hashCode.toUnsigned(32).toRadixString(16)}_$size';

    _handles[id] = item;

    return ScannedFile(
      id: id,
      name: name,
      fullPath: pseudoPath,
      relativePath: relativePath,
      extension: p.extension(name).toLowerCase(),
      size: size,
      lastModified: modified,
      source: source,
    );
  }
}
