import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:docx_to_markdown/docx_to_markdown.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

import '../../models/scan_result.dart';
import '../../models/scanned_file.dart';
import 'scan_filters.dart';

/// `dart:io` implementation of the scan platform primitives.
///
/// Everything here works with real filesystem paths; [ScannedFile.fullPath]
/// is always an absolute on-disk path on this platform.
class PlatformFs {
  const PlatformFs._();

  /// Real absolute paths exist on this platform.
  static const bool supportsAbsolutePaths = true;

  /// Exports can stream file contents from disk to disk.
  static const bool supportsStreamingExport = true;

  /// The user's home directory, used for `~/` expansion in pasted paths.
  static String? get userHomeDirectory =>
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

  /// True when [path] points at an existing file or directory.
  static bool pathExists(String path) =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  /// SYNC factory to create a ScannedFile from an on-disk path.
  /// This provides instant performance without async overhead.
  static ScannedFile scannedFileFromPathSync(
    String filePath, {
    String? relativePath,
    ScanSource source = ScanSource.browse,
  }) {
    final fileName = p.basename(filePath);

    // SYNC stat call - instant performance!
    final stat = File(filePath).statSync();

    // Handle temporary files from VS Code drag-and-drop.
    final displayPath = filePath.contains('/tmp/Drops/') ? fileName : null;

    // Generate a deterministic ID based on the normalized full path and size.
    // This ensures the same file always gets the same ID.
    final normalizedPath = p.normalize(filePath);
    final id =
        'file_${normalizedPath.hashCode.toUnsigned(32).toRadixString(16)}_${stat.size}';

    return ScannedFile(
      id: id,
      name: fileName,
      fullPath: filePath,
      relativePath: relativePath ?? fileName,
      extension: p.extension(fileName).toLowerCase(),
      size: stat.size,
      lastModified: stat.modified,
      source: source,
      displayPath: displayPath,
    );
  }

  /// Current on-disk size of [file], or null when it no longer exists.
  static Future<int?> fileSizeOf(ScannedFile file) async {
    final f = File(file.fullPath);
    if (!f.existsSync()) return null;
    return f.length();
  }

  /// Raw bytes of [file], or null when it no longer exists.
  static Future<Uint8List?> readFileBytes(ScannedFile file) async {
    final f = File(file.fullPath);
    if (!f.existsSync()) return null;
    return f.readAsBytes();
  }

  /// Scans a directory incrementally and efficiently, skipping heavy folders.
  static Future<void> scanDirectory({
    required String directoryPath,
    required Set<String> blacklist,
    required void Function(List<ScannedFile> files) onBatchFound,
    required ScanSource source,
  }) async {
    final rootDir = Directory(directoryPath);
    if (!rootDir.existsSync()) {
      return;
    }

    final List<Directory> stack = [rootDir];
    final List<ScannedFile> batch = [];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      try {
        // List non-recursively
        final entities = current.list(recursive: false, followLinks: false);

        await for (final entity in entities) {
          final name = p.basename(entity.path);

          if (entity is Directory) {
            // Skip ignored dirs
            if (!name.startsWith('.') &&
                !kIgnoredDirectoryNames.contains(name)) {
              stack.add(entity);
            }
          } else if (entity is File) {
            // Skip hidden files
            if (name.startsWith('.')) continue;

            // Check blacklist
            if (isBlacklistedFileName(name, blacklist)) {
              continue;
            }

            try {
              final relativePath = p.relative(entity.path, from: directoryPath);
              batch.add(
                scannedFileFromPathSync(
                  entity.path,
                  relativePath: relativePath,
                  source: source,
                ),
              );

              // Emit batch every 200 items
              if (batch.length >= 200) {
                onBatchFound(List.from(batch));
                batch.clear();
              }
            } catch (_) {
              // Skip problematic files
            }
          }
        }
      } catch (_) {
        // Access denied or other fs errors
      }
    }

    if (batch.isNotEmpty) {
      onBatchFound(batch);
    }
  }

  /// Expands dropped/picked items (files, directories, VS Code drops) into
  /// [ScannedFile] batches.
  static Future<void> expandDroppedItems({
    required List<XFile> items,
    required Set<String> blacklist,
    required ScanSource source,
    required void Function(List<ScannedFile> files) onBatchFound,
    required void Function(List<String> sourcePaths) onScanComplete,
  }) async {
    final processedPaths = <String>{};
    final sourcePaths = <String>{};

    // Remove duplicates
    final uniquePaths = <String>{};
    final uniqueItems = <XFile>[];
    for (final item in items) {
      if (!uniquePaths.contains(item.path)) {
        uniquePaths.add(item.path);
        uniqueItems.add(item);
      }
    }

    final filesByDirectory = <String, List<String>>{};
    final directories = <String>[];

    for (final item in uniqueItems) {
      final itemPath = item.path;

      // Check for VS Code directory drop
      if (await _isVSCodeDirectoryDrop(itemPath)) {
        final dirPath = await _extractVSCodeDirectory(itemPath);
        if (dirPath != null) directories.add(dirPath);
        continue;
      }

      if (item is DropItemDirectory) {
        directories.add(itemPath);
      } else {
        final entityType = FileSystemEntity.typeSync(itemPath);
        if (entityType == FileSystemEntityType.directory) {
          directories.add(itemPath);
        } else if (entityType == FileSystemEntityType.file) {
          final parentDir = p.dirname(itemPath);
          filesByDirectory.putIfAbsent(parentDir, () => []).add(itemPath);
        }
      }
    }

    // Process directories
    for (final dirPath in directories) {
      sourcePaths.add(dirPath);
      await scanDirectory(
        directoryPath: dirPath,
        blacklist: blacklist,
        source: source,
        onBatchFound: (batch) {
          final newFiles = <ScannedFile>[];
          for (final file in batch) {
            if (processedPaths.add(file.fullPath)) {
              newFiles.add(file);
            }
          }
          if (newFiles.isNotEmpty) {
            onBatchFound(newFiles);
          }
        },
      );
    }

    // Process individual files
    // We treat these as a batch per directory
    for (final entry in filesByDirectory.entries) {
      sourcePaths.add(entry.key);
      final batch = <ScannedFile>[];

      for (final filePath in entry.value) {
        if (!processedPaths.add(filePath)) {
          continue;
        }

        final fileName = p.basename(filePath);
        if (isBlacklistedFileName(fileName, blacklist)) {
          continue;
        }

        try {
          final file = scannedFileFromPathSync(
            filePath,
            relativePath: fileName,
            source: source,
          );
          batch.add(file);
        } catch (_) {}
      }

      if (batch.isNotEmpty) {
        onBatchFound(batch);
      }
    }

    onScanComplete(sourcePaths.toList());
  }

  /// Prompts for a save location and writes [content] to it.
  static Future<void> saveTextFile({
    required String suggestedName,
    required String content,
  }) async {
    final location = await getSaveLocation(suggestedName: suggestedName);
    if (location != null) {
      await File(location.path).writeAsString(content);
    }
  }

  /// Safe export that streams content from disk to disk.
  /// Handles large projects without using RAM for the whole content.
  static Future<void> exportCollectionStreaming(List<ScannedFile> files) async {
    final fileName =
        'context_collection_${DateTime.now().millisecondsSinceEpoch}.md';
    final savePath = await getSaveLocation(suggestedName: fileName);
    if (savePath == null) return;

    // Open a write stream directly to the file
    final sink = File(savePath.path).openWrite();

    try {
      // --- Header ---
      final headerFile = files
          .where((f) => f.isVirtual && f.name == 'Header')
          .firstOrNull;
      if (headerFile != null) {
        sink
          ..writeln(headerFile.effectiveContent)
          ..writeln();
      }

      sink.writeln('# Context Collection\n');

      final contextFiles =
          files
              .where(
                (f) =>
                    !(f.isVirtual &&
                        (f.name == 'Header' || f.name == 'Footer')),
              )
              .toList()
            ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

      for (final file in contextFiles) {
        sink
          ..writeln('## ${file.name}')
          ..writeln('> **Path:** ${file.fullPath}\n');

        final fenceLanguage = _isDocx(file)
            ? 'markdown'
            : file.extension.replaceAll('.', '');
        sink.writeln('```$fenceLanguage');

        if (file.isVirtual) {
          sink.write(file.effectiveContent);
        } else {
          // REAL FILES: Stream directly from disk!
          final f = File(file.fullPath);
          if (f.existsSync()) {
            if (_isDocx(file)) {
              try {
                sink.write(await _readDocxAsMarkdown(f));
              } catch (e) {
                sink.writeln('// Error converting .docx to text: $e');
              }
            } else {
              await sink.addStream(f.openRead());
            }
          } else {
            sink.writeln('// Error: File not found');
          }
        }

        sink
          ..writeln('\n```\n')
          ..writeln('---\n');
      }

      // --- Footer ---
      final footerFile = files
          .where((f) => f.isVirtual && f.name == 'Footer')
          .firstOrNull;
      if (footerFile != null) {
        sink
          ..writeln()
          ..writeln(footerFile.effectiveContent);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  static bool _isDocx(ScannedFile file) =>
      file.extension.toLowerCase() == '.docx';

  static Future<String> _readDocxAsMarkdown(File file) async {
    final bytes = await file.readAsBytes();
    return DocxConverter(bytes).convert();
  }

  static Future<bool> _isVSCodeDirectoryDrop(String filePath) async {
    if (!filePath.contains('/tmp/Drops/')) return false;
    try {
      final content = await File(filePath).readAsString();
      return content.contains('<script>start("') && content.contains('addRow(');
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _extractVSCodeDirectory(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      final match = RegExp(
        r'<script>start\("([^\"]+)"\);</script>',
      ).firstMatch(content);
      final dirPath = match?.group(1);
      if (dirPath != null && Directory(dirPath).existsSync()) {
        return dirPath;
      }
    } catch (_) {}
    return null;
  }
}
