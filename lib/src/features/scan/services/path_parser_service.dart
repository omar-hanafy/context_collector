import 'dart:io';

import 'package:path/path.dart' as p;

/// Result of path parsing operation
class PathParseResult {
  const PathParseResult({
    required this.validPaths,
    required this.errors,
  });

  /// List of successfully parsed and validated paths
  final List<String> validPaths;

  /// Map of invalid paths to their error descriptions
  final Map<String, String> errors;

  /// Whether parsing completed without any errors
  bool get hasErrors => errors.isNotEmpty;

  /// Total number of paths processed (valid + invalid)
  int get totalPaths => validPaths.length + errors.length;
}

/// Service responsible for parsing mixed path input into clean, normalized paths
class PathParserService {
  /// Parses a raw string of mixed paths into a clean, platform-neutral list.
  /// Handles various formats:
  /// - Space-delimited paths
  /// - Newline-delimited paths
  /// - Quoted paths with spaces
  /// - Mixed Windows and POSIX paths
  /// - Concatenated paths
  /// - UNC paths (\\server\share)
  ///
  /// Returns a PathParseResult containing valid paths and errors
  ///
  /// Note: For very large inputs (5000+ paths), consider implementing
  /// progress reporting in a future version to avoid UI freezing.
  Future<PathParseResult> parse(String rawInput) async {
    if (rawInput.trim().isEmpty) {
      return const PathParseResult(validPaths: [], errors: {});
    }

    final parsedPaths = <String>{};
    final errors = <String, String>{};

    // Step 1: Extract quoted paths first to preserve spaces
    final quotedPaths = <String>[];
    final quotePatterns = [
      RegExp('"([^"]+)"'), // Double quotes
      RegExp("'([^']+)'"), // Single quotes
    ];

    var processedInput = rawInput;
    for (final pattern in quotePatterns) {
      processedInput = processedInput.replaceAllMapped(pattern, (match) {
        final path = match.group(1)!;
        quotedPaths.add(path);
        return ' {{QUOTED_PATH}} '; // Placeholder
      });
    }

    // Step 2: Handle UNC paths before normalizing separators
    // Convert \\server\share to //server/share temporarily
    processedInput = processedInput.replaceAllMapped(
      RegExp(r'\\\\([^\\]+\\[^\\]+(?:\\[^\\]+)*)'),
      (match) => '//UNC_PATH_${match.group(1)!.replaceAll(r'\', '_SLASH_')}',
    );

    // Step 3: Normalize path separators to forward slashes
    processedInput = processedInput.replaceAll(r'\', '/');

    // Step 4: Split concatenated Windows drive paths (e.g., C:/UsersD:/Docs)
    processedInput = processedInput.replaceAllMapped(
      RegExp(r'([A-Za-z]:/[^/\s]*)(?=[A-Za-z]:/|$)', multiLine: true),
      (match) => '${match.group(1)} ',
    );

    // Step 5: Don't split concatenated POSIX paths - this was causing issues
    // Users should separate paths with spaces or newlines

    // Step 6: Split by whitespace
    final tokens = processedInput
        .split(RegExp(r'\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Step 7: Process each token
    var quotedIndex = 0;
    for (final token in tokens) {
      if (token == '{{QUOTED_PATH}}') {
        // Replace placeholder with actual quoted path
        if (quotedIndex < quotedPaths.length) {
          parsedPaths.add(quotedPaths[quotedIndex++]);
        }
      } else if (token.startsWith('//UNC_PATH_')) {
        // Restore UNC path
        final uncPath = token
            .replaceFirst('//UNC_PATH_', r'\\')
            .replaceAll('_SLASH_', r'\');
        parsedPaths.add(uncPath);
      } else {
        parsedPaths.add(token);
      }
    }

    // Step 8: Clean and validate paths
    final cleanedPaths = <String>[];
    for (var path in parsedPaths) {
      path = path.trim();
      if (path.isEmpty) continue;

      final originalPath = path;

      // Don't convert UNC paths separators
      if (!path.startsWith(r'\\')) {
        // Convert Windows paths to POSIX for internal consistency
        path = path.replaceAll(r'\', '/');
      }

      // Security: Skip paths trying to navigate above project root
      if (path.contains('..')) {
        errors[originalPath] =
            'Path contains ".." which is not allowed for security reasons';
        continue;
      }

      // Normalize the path
      try {
        final normalized = p.normalize(path);

        // Additional validation
        final validationError = _validatePath(normalized);
        if (validationError == null) {
          cleanedPaths.add(normalized);
        } else {
          errors[originalPath] = validationError;
        }
      } catch (e) {
        errors[originalPath] = 'Invalid path format: $e';
      }
    }

    // Remove duplicates while preserving order
    final uniquePaths = <String>[];
    final seen = <String>{};
    for (final path in cleanedPaths) {
      final canonical = _canonicalizePath(path);
      if (!seen.contains(canonical)) {
        seen.add(canonical);
        uniquePaths.add(path);
      }
    }

    return PathParseResult(
      validPaths: uniquePaths,
      errors: errors,
    );
  }

  /// Validates if a path is acceptable, returns error message or null if valid
  String? _validatePath(String path) {
    // Platform-specific illegal characters
    if (Platform.isWindows) {
      // Windows illegal characters: < > : " | ? * and control characters
      // But allow : for drive letters and \\ for UNC paths
      if (path.startsWith(r'\\')) {
        // UNC path - check after the initial \\\\
        final uncContent = path.substring(2);
        final illegalChars = RegExp(r'[<>"|?*\x00-\x1F]');
        if (illegalChars.hasMatch(uncContent)) {
          return 'Path contains illegal characters for Windows: ${illegalChars.firstMatch(uncContent)?.group(0)}';
        }
      } else {
        // Regular Windows path
        final pathWithoutDrive = path.replaceFirst(RegExp('^[A-Za-z]:'), '');
        final illegalChars = RegExp(r'[<>:"|?*\x00-\x1F]');
        if (illegalChars.hasMatch(pathWithoutDrive)) {
          return 'Path contains illegal characters for Windows: ${illegalChars.firstMatch(pathWithoutDrive)?.group(0)}';
        }
      }
    } else {
      // Unix-like systems - mainly control characters and null
      final illegalChars = RegExp(r'\x00');
      if (illegalChars.hasMatch(path)) {
        return 'Path contains null character';
      }
    }

    // Path should not be just a drive letter
    if (RegExp(r'^[A-Za-z]:/?$').hasMatch(path)) {
      return 'Path cannot be just a drive letter';
    }

    // Basic length check
    if (Platform.isWindows) {
      // Windows has different limits for regular paths vs UNC paths
      if (path.startsWith(r'\\')) {
        if (path.length > 32767) {
          return 'UNC path exceeds maximum length of 32767 characters';
        }
      } else if (path.length > 260) {
        return 'Path exceeds maximum length of 260 characters on Windows';
      }
    } else if (path.length > 4096) {
      // Most Unix systems have a 4096 path limit
      return 'Path exceeds maximum length of 4096 characters';
    }

    return null;
  }

  /// Creates a canonical representation of a path for deduplication
  String _canonicalizePath(String path) {
    // Remove trailing slashes except for root paths
    var canonical = path;
    if (canonical.length > 1 && canonical.endsWith('/')) {
      canonical = canonical.substring(0, canonical.length - 1);
    }

    // Lowercase for case-insensitive filesystems (Windows, macOS)
    if (Platform.isWindows || Platform.isMacOS) {
      canonical = canonical.toLowerCase();
    }

    return canonical;
  }
}
