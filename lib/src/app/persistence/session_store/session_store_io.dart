import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Desktop/mobile session storage: JSON files under the app-support
/// directory, written atomically (tmp file + rename).
class SessionStore {
  Future<Directory> _baseDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final target = Directory(p.join(supportDir.path, 'workspaces'));
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }
    return target;
  }

  Future<File> _indexFile() async {
    final dir = await _baseDir();
    return File(p.join(dir.path, 'index.json'));
  }

  Future<File> _sessionFile(String sessionId) async {
    final dir = await _baseDir();
    return File(p.join(dir.path, '$sessionId.json'));
  }

  Future<void> _atomicWrite(File file, String contents) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(contents, flush: true);
    if (file.existsSync()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<String?> readIndex() async {
    final file = await _indexFile();
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  Future<void> writeIndex(String payload) async {
    final file = await _indexFile();
    await _atomicWrite(file, payload);
  }

  Future<String?> readSession(String sessionId) async {
    final file = await _sessionFile(sessionId);
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  Future<void> writeSession(String sessionId, String payload) async {
    final file = await _sessionFile(sessionId);
    await _atomicWrite(file, payload);
  }

  Future<void> deleteSession(String sessionId) async {
    final file = await _sessionFile(sessionId);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
