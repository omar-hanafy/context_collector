import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Monaco asset manager - Single source of truth for all Monaco-related assets
class MonacoAssetManager {
  static const String _assetBaseDir = 'assets/monaco';
  static const String _cacheSubDir = 'monaco_editor_cache';
  static const String _htmlFileName = 'index.html';
  static const String _relativePath = 'monaco-editor/min/vs';

  /// Get the Monaco assets directory, copying if necessary
  static Future<String> getAssetsDirectory() async {
    final targetDir = p.join(
      (await getApplicationSupportDirectory()).path,
      _cacheSubDir,
    );

    // Check if Monaco is already extracted by looking for a key file
    final loaderFile = File(
      p.join(targetDir, 'monaco-editor', 'min', 'vs', 'loader.js'),
    );

    if (!loaderFile.existsSync()) {
      debugPrint('[MonacoAssetManager] Monaco not found, copying assets...');
      await _copyAllAssets(targetDir);
    } else {
      debugPrint(
        '[MonacoAssetManager] Monaco already extracted at: $targetDir',
      );
    }

    // Ensure HTML file is always up to date
    await _ensureHtmlFile(targetDir);

    return targetDir;
  }

  /// Get the path to the HTML file
  static Future<String> getHtmlFilePath() async {
    final targetDir = await getAssetsDirectory();
    return p.join(targetDir, _htmlFileName);
  }

  /// Ensure the HTML file exists and is up to date
  static Future<void> _ensureHtmlFile(String targetDir) async {
    final htmlFile = File(p.join(targetDir, _htmlFileName));

    // Generate platform-specific HTML
    String htmlContent;

    if (Platform.isWindows) {
      // Windows needs absolute paths since we load from file://
      final vsPath = p.join(targetDir, 'monaco-editor', 'min', 'vs');
      final absoluteVsPath = Uri.file(vsPath).toString();
      htmlContent = EditorConstants.indexHtmlContent(absoluteVsPath);

      // Add Windows-specific flutter channel script
      const channelScript =
          '''
<script>
${MonacoScripts.windowsFlutterChannelScript}
</script>
''';
      htmlContent = htmlContent.replaceFirst(
        '<head>',
        '<head>\n$channelScript',
      );
    } else {
      // macOS uses relative paths since HTML is in the same directory
      htmlContent = EditorConstants.indexHtmlContent(_relativePath);
    }

    // Always write/overwrite to ensure it's current with any EditorConstants changes
    await htmlFile.writeAsString(htmlContent);

    debugPrint('[MonacoAssetManager] HTML file updated at: ${htmlFile.path}');
  }

  /// Copy all Monaco assets to the target directory
  static Future<void> _copyAllAssets(String targetDir) async {
    final stopwatch = Stopwatch()..start();

    // Clean and create target directory
    final directory = Directory(targetDir);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);

    // Get all assets from the manifest
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final monacoAssets = manifest
        .listAssets()
        .where((key) => key.startsWith(_assetBaseDir))
        .toList();

    debugPrint(
      '[MonacoAssetManager] Found ${monacoAssets.length} Monaco assets to copy',
    );

    // Copy each asset maintaining directory structure
    var copiedCount = 0;
    for (final assetKey in monacoAssets) {
      try {
        // Calculate relative path (skip index.html from assets if it exists)
        final relativePath = assetKey.substring('$_assetBaseDir/'.length);
        if (relativePath.isEmpty || relativePath == _htmlFileName) continue;

        // Create target file path
        final targetFile = File(p.join(targetDir, relativePath));

        // Ensure parent directory exists
        await targetFile.parent.create(recursive: true);

        // Load and write asset
        final bytes = await rootBundle.load(assetKey);
        await targetFile.writeAsBytes(bytes.buffer.asUint8List());

        copiedCount++;

        // Log progress every 100 files
        if (copiedCount % 100 == 0) {
          debugPrint(
            '[MonacoAssetManager] Progress: $copiedCount/${monacoAssets.length} files copied',
          );
        }
      } catch (e) {
        debugPrint(
          '[MonacoAssetManager] Error copying $assetKey: $e',
        );
      }
    }

    stopwatch.stop();
    debugPrint(
      '[MonacoAssetManager] Completed: $copiedCount files copied in ${stopwatch.elapsedMilliseconds}ms',
    );
  }

  /// Clean up all Monaco assets including HTML
  static Future<void> cleanAssets() async {
    final targetDir = p.join(
      (await getApplicationSupportDirectory()).path,
      _cacheSubDir,
    );

    final directory = Directory(targetDir);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
      debugPrint('[MonacoAssetManager] Monaco assets cleaned');
    }
  }

  /// Get information about extracted Monaco assets
  static Future<Map<String, dynamic>> getAssetInfo() async {
    final targetDir = p.join(
      (await getApplicationSupportDirectory()).path,
      _cacheSubDir,
    );

    final directory = Directory(targetDir);
    if (!directory.existsSync()) {
      return {
        'exists': false,
        'path': targetDir,
      };
    }

    // Count files and calculate size
    var fileCount = 0;
    var totalSize = 0;
    var hasHtmlFile = false;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        fileCount++;
        totalSize += await entity.length();

        if (p.basename(entity.path) == _htmlFileName) {
          hasHtmlFile = true;
        }
      }
    }

    return {
      'exists': true,
      'path': targetDir,
      'fileCount': fileCount,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'hasHtmlFile': hasHtmlFile,
      'htmlPath': p.join(targetDir, _htmlFileName),
    };
  }

  /// Force refresh of HTML file (useful if EditorConstants change)
  static Future<void> refreshHtmlFile() async {
    final targetDir = await getAssetsDirectory();
    await _ensureHtmlFile(targetDir);
  }
}
