import 'dart:async';
import 'dart:io';

import 'package:context_collector/src/features/scan/data/file_scanner.dart';
import 'package:context_collector/src/features/scan/domain/scanned_file.dart';
import 'package:context_collector/src/shared/utils/drop_file_resolver.dart';
import 'package:context_collector/src/shared/utils/extension_catalog.dart';
import 'package:context_collector/src/shared/utils/vscode_drop_detector.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';

/// Result of processing a single drop item
@immutable
class DropProcessResult {
  const DropProcessResult({
    required this.files,
    required this.errors,
    required this.skippedPaths,
    this.filteredPaths = const [],
  });

  final List<ScannedFile> files;
  final Map<String, String> errors; // path -> error message
  final List<String> skippedPaths; // Already processed paths (duplicates)
  final List<String>
      filteredPaths; // Files filtered due to unsupported extensions

  bool get hasErrors => errors.isNotEmpty;

  int get totalProcessed =>
      files.length + errors.length + skippedPaths.length + filteredPaths.length;
}

/// Progress information for drop processing
@immutable
class DropProcessProgress {
  const DropProcessProgress({
    required this.totalItems,
    required this.processedItems,
    required this.currentItem,
    required this.phase,
  });

  final int totalItems;
  final int processedItems;
  final String? currentItem;
  final DropProcessPhase phase;

  double get progress => totalItems > 0 ? processedItems / totalItems : 0.0;

  String get progressText => '$processedItems / $totalItems items processed';
}

enum DropProcessPhase {
  collectingItems('Collecting dropped items...'),
  resolvingDirectories('Resolving directories...'),
  scanningFiles('Scanning files...'),
  filteringDuplicates('Filtering duplicates...'),
  complete('Complete');

  const DropProcessPhase(this.message);

  final String message;
}

/// Service responsible for processing dropped files and directories
/// This handles all the complexity of different drop scenarios
class DropProcessor {
  DropProcessor({
    required FileScanner fileScanner,
  }) : _fileScanner = fileScanner;

  final FileScanner _fileScanner;

  /// Process a list of dropped items and return the result
  Future<DropProcessResult> processDroppedItems({
    required List<XFile> droppedItems,
    required Map<String, FileCategory> supportedExtensions,
    required Set<String> existingFilePaths,
    void Function(DropProcessProgress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (kDebugMode) {
      print(
          '[DropProcessor] Starting processing of ${droppedItems.length} items');
      for (var i = 0; i < droppedItems.length && i < 5; i++) {
        print('  - Item $i: ${droppedItems[i].path}');
      }
    }

    // Phase 1: Collect and categorize items
    onProgress?.call(DropProcessProgress(
      totalItems: droppedItems.length,
      processedItems: 0,
      currentItem: null,
      phase: DropProcessPhase.collectingItems,
    ));

    final collectionResult = await _collectDroppedItems(droppedItems);

    if (kDebugMode) {
      print('[DropProcessor] Collection result:');
      print('  - File paths: ${collectionResult.filePaths.length}');
      print('  - Directory paths: ${collectionResult.directoryPaths.length}');
      if (collectionResult.filePaths.isNotEmpty) {
        print(
            '  - First few files: ${collectionResult.filePaths.take(3).toList()}');
      }
    }

    onProgress?.call(DropProcessProgress(
      totalItems: collectionResult.totalEstimatedItems,
      processedItems: droppedItems.length,
      currentItem: null,
      phase: DropProcessPhase.resolvingDirectories,
    ));

    // Phase 2: Resolve directories to files
    final allScannedFiles = <ScannedFile>[];
    final errors = <String, String>{};
    var processedCount = droppedItems.length;

    // Process individual files first
    final filteredPaths = <String>[];

    for (final filePath in collectionResult.filePaths) {
      try {
        final file = File(filePath);
        if (file.existsSync()) {
          final scannedFile = ScannedFile.fromFile(file);
          // Check if file has supported extension
          if (supportedExtensions.containsKey(scannedFile.extension) ||
              scannedFile.extension.isEmpty) {
            allScannedFiles.add(scannedFile);
          } else {
            filteredPaths.add(filePath);
          }
        } else {
          errors[filePath] = 'File not found';
        }
      } catch (e) {
        errors[filePath] = 'Error accessing file: $e';
      }
      processedCount++;

      onProgress?.call(DropProcessProgress(
        totalItems: collectionResult.totalEstimatedItems,
        processedItems: processedCount,
        currentItem: filePath,
        phase: DropProcessPhase.scanningFiles,
      ));
    }

    // Process directories
    for (final dirPath in collectionResult.directoryPaths) {
      onProgress?.call(DropProcessProgress(
        totalItems: collectionResult.totalEstimatedItems,
        processedItems: processedCount,
        currentItem: dirPath,
        phase: DropProcessPhase.scanningFiles,
      ));

      try {
        final scannedFiles = await _fileScanner.scanDirectory(
          dirPath,
          supportedExtensions,
        );
        allScannedFiles.addAll(scannedFiles);
        processedCount += scannedFiles.length;
      } catch (e) {
        errors[dirPath] = 'Error scanning directory: $e';
        processedCount++;
      }
    }

    // Phase 3: Filter duplicates and already-added files
    if (kDebugMode) {
      print('[DropProcessor] Before filtering:');
      print('  - All scanned files: ${allScannedFiles.length}');
      print('  - Existing file paths: ${existingFilePaths.length}');
      if (allScannedFiles.isNotEmpty) {
        print('  - First scanned file: ${allScannedFiles.first.fullPath}');
      }
    }

    onProgress?.call(DropProcessProgress(
      totalItems: allScannedFiles.length,
      processedItems: 0,
      currentItem: null,
      phase: DropProcessPhase.filteringDuplicates,
    ));

    final uniqueFiles = <ScannedFile>[];
    final skippedPaths = <String>[];
    final seenPaths = <String>{};

    for (var i = 0; i < allScannedFiles.length; i++) {
      final file = allScannedFiles[i];

      // Skip if already in the app
      if (existingFilePaths.contains(file.fullPath)) {
        skippedPaths.add(file.fullPath);
        if (i < 3) {
          debugPrint(
              '[DropProcessor] Skipping existing file: ${file.fullPath}');
        }
      }
      // Skip if we've already processed this path in this batch
      else if (seenPaths.contains(file.fullPath)) {
        skippedPaths.add(file.fullPath);
        if (i < 3) {
          debugPrint(
              '[DropProcessor] Skipping duplicate in batch: ${file.fullPath}');
        }
      }
      // Add to unique files
      else {
        uniqueFiles.add(file);
        seenPaths.add(file.fullPath);
      }

      if (i % 10 == 0) {
        // Update progress every 10 files
        onProgress?.call(DropProcessProgress(
          totalItems: allScannedFiles.length,
          processedItems: i + 1,
          currentItem: file.name,
          phase: DropProcessPhase.filteringDuplicates,
        ));
      }
    }

    // Final progress
    onProgress?.call(DropProcessProgress(
      totalItems: uniqueFiles.length,
      processedItems: uniqueFiles.length,
      currentItem: null,
      phase: DropProcessPhase.complete,
    ));

    if (kDebugMode) {
      print(
          '[DropProcessor] Processing complete in ${stopwatch.elapsedMilliseconds}ms');
      print('  - Files found: ${uniqueFiles.length}');
      print('  - Errors: ${errors.length}');
      print('  - Skipped (duplicates): ${skippedPaths.length}');
      print('  - Filtered (unsupported): ${filteredPaths.length}');
    }

    return DropProcessResult(
      files: uniqueFiles,
      errors: errors,
      skippedPaths: skippedPaths,
      filteredPaths: filteredPaths,
    );
  }

  /// Collect and categorize dropped items
  Future<_DropCollectionResult> _collectDroppedItems(
    List<XFile> droppedItems,
  ) async {
    final filePaths = <String>[];
    final directoryPaths = <String>[];
    var estimatedTotal = droppedItems.length;

    for (final item in droppedItems) {
      final itemPath = item.path;

      if (kDebugMode) {
        print('[DropProcessor] Processing dropped item: $itemPath');
      }

      // Check for VS Code directory drop
      if (itemPath.contains('/tmp/Drops/')) {
        try {
          final content = await File(itemPath).readAsString();
          final directoryPath =
              VSCodeDropDetector.extractDirectoryPath(content);

          if (directoryPath != null) {
            directoryPaths.add(directoryPath);
            // Estimate 20 files per directory for progress tracking
            estimatedTotal += 20;
            continue;
          }
        } catch (_) {
          // Not a VS Code directory listing, process normally
        }
      }

      // Handle typed drops (desktop_drop 0.6.0+)
      if (item is DropItemDirectory) {
        directoryPaths.add(itemPath);
        estimatedTotal += 20; // Estimate

        // Process children recursively
        await _processDropItemChildren(
          item.children,
          filePaths,
          directoryPaths,
        );
        estimatedTotal += item.children.length;
      } else if (item is DropItemFile) {
        // JetBrains workaround: Check if this "file" is actually a directory
        final checkType = FileSystemEntity.typeSync(itemPath);
        if (checkType == FileSystemEntityType.directory) {
          directoryPaths.add(itemPath);
          estimatedTotal += 20; // Estimate
        } else {
          filePaths.add(itemPath);
        }
      } else {
        // Fallback for regular XFile - use filesystem check
        final entity = FileSystemEntity.typeSync(itemPath);

        if (entity == FileSystemEntityType.directory) {
          directoryPaths.add(itemPath);
          estimatedTotal += 20; // Estimate
        } else if (entity == FileSystemEntityType.file) {
          filePaths.add(itemPath);
        } else if (DropFileResolver.isTemporaryDropFile(itemPath)) {
          // Handle other temporary drop files
          try {
            final testFile = File(itemPath);
            if (testFile.existsSync() &&
                testFile.statSync().type == FileSystemEntityType.file) {
              filePaths.add(itemPath);
            }
          } catch (_) {
            // Skip files that can't be accessed
          }
        }
      }
    }

    return _DropCollectionResult(
      filePaths: filePaths,
      directoryPaths: directoryPaths,
      totalEstimatedItems: estimatedTotal,
    );
  }

  /// Process children of DropItemDirectory recursively
  Future<void> _processDropItemChildren(
    List<DropItem> children,
    List<String> files,
    List<String> directories,
  ) async {
    for (final child in children) {
      if (child is DropItemDirectory) {
        directories.add(child.path);
        await _processDropItemChildren(child.children, files, directories);
      } else if (child is DropItemFile) {
        files.add(child.path);
      }
    }
  }
}

/// Internal class for collection results
class _DropCollectionResult {
  const _DropCollectionResult({
    required this.filePaths,
    required this.directoryPaths,
    required this.totalEstimatedItems,
  });

  final List<String> filePaths;
  final List<String> directoryPaths;
  final int totalEstimatedItems;
}
