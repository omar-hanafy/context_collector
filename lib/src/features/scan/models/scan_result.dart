import 'package:flutter/foundation.dart';
import 'scanned_file.dart';

/// Represents the source of a scan operation
enum ScanSource { drop, browse, paste, manual }

/// Metadata about a scan operation
@immutable
class ScanMetadata {
  final List<String> sourcePaths;
  final DateTime timestamp;
  final ScanSource source;

  const ScanMetadata({
    required this.sourcePaths,
    required this.timestamp,
    required this.source,
  });
}

/// Result of a scan operation, containing files and metadata
@immutable
class ScanResult {
  final List<ScannedFile> files;
  final ScanMetadata metadata;

  const ScanResult({
    required this.files,
    required this.metadata,
  });
}
