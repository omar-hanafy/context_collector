/// Directory names that are always skipped while walking dropped or picked
/// folders, on every platform.
const Set<String> kIgnoredDirectoryNames = {
  'build',
  '.dart_tool',
  '.git',
  '.idea',
  'ios',
  'android',
  'node_modules',
  'linux',
  'macos',
  'windows',
  'web',
  'coverage',
  '.gradle',
  '.vscode',
  'Pods',
  '.symlinks',
  'DerivedData',
  'dist',
  'out',
};

/// True when [fileName] matches one of the blacklisted extension patterns.
bool isBlacklistedFileName(String fileName, Set<String> blacklist) {
  final lower = fileName.toLowerCase();
  return blacklist.any((ext) => lower.endsWith(ext.toLowerCase()));
}
