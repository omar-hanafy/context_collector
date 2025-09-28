// ignore_for_file: avoid_dynamic_calls

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';

/// Result of splitting a drop into filesystem-backed files and pure text payloads.
class DropSplitResult {
  DropSplitResult({
    required this.files,
    required this.texts,
  });

  /// Unique files/directories detected in the drop.
  final List<XFile> files;

  /// Unique, trimmed text payloads (for memory-backed / clipboard drops).
  final List<String> texts;

  bool get hasFiles => files.isNotEmpty;

  bool get hasTextOnly => files.isEmpty && texts.isNotEmpty;

  bool get isEmpty => files.isEmpty && texts.isEmpty;
}

/// Utility that normalises desktop_drop payloads into files vs text.
class DropPayloadSplitter {
  const DropPayloadSplitter._();

  /// Split a [DropDoneDetails] payload originating from a widget DropTarget.
  static Future<DropSplitResult> fromDetails(DropDoneDetails details) {
    return _split(details.files);
  }

  /// Split a raw app-level [DropDoneEvent] payload (e.g. Dock/Finder drop).
  static Future<DropSplitResult> fromRawEvent(DropDoneEvent event) {
    return _split(event.files);
  }

  static Future<DropSplitResult> _split(Iterable<DropItem> items) async {
    final files = <XFile>[];
    final filePaths = <String>{};
    final texts = <String>{};

    for (final item in items) {
      if (item.isMemoryBacked && item.isTextLike) {
        try {
          final text = (await item.readAsText())?.trim();
          if (text != null && text.isNotEmpty) {
            texts.add(text);
          }
        } catch (_) {
          // Ignore text payloads we fail to read.
        }
        continue;
      }

      if (item.path.isNotEmpty && filePaths.add(item.path)) {
        files.add(item);
      }
    }

    return DropSplitResult(
      files: files,
      texts: texts.toList(),
    );
  }
}
