import 'dart:io';

/// Utility class to detect and handle VS Code directory drops
/// 
/// When dragging a directory from VS Code's file tree, VS Code creates
/// a temporary HTML file containing a JavaScript listing of the directory.
/// This class extracts the actual directory path from that listing.
class VSCodeDropDetector {
  /// Extract directory path from VS Code's HTML listing file
  /// 
  /// Looks for: <script>start("/path/to/directory/");</script>
  static String? extractDirectoryPath(String content) {
    final match = RegExp(r'<script>start\("([^"]+)"\);</script>').firstMatch(content);
    return match?.group(1);
  }
  
  /// Check if this is a VS Code directory listing file
  static bool isVSCodeDirectoryListing(String filePath, String content) {
    return filePath.contains('/tmp/Drops/') && 
           content.contains('<script>start("') &&
           content.contains('addRow(');
  }
  
  /// Try to extract directory path from a potential VS Code drop file
  /// Returns null if not a VS Code directory listing or if extraction fails
  static Future<String?> tryExtractVSCodeDirectory(String filePath) async {
    // Quick check if it's in the temp drops folder
    if (!filePath.contains('/tmp/Drops/')) {
      return null;
    }
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final content = await file.readAsString();
      
      if (!isVSCodeDirectoryListing(filePath, content)) {
        return null;
      }
      
      final directoryPath = extractDirectoryPath(content);
      
      // Verify the directory actually exists
      if (directoryPath != null && await Directory(directoryPath).exists()) {
        return directoryPath;
      }
    } catch (_) {
      // Any error means this isn't a VS Code directory listing
    }
    
    return null;
  }
}
