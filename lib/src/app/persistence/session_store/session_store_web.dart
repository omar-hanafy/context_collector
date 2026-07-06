import 'package:shared_preferences/shared_preferences.dart';

/// Web session storage: browser local storage via `shared_preferences`.
///
/// Saved sessions on web can restore virtual files and edited overrides;
/// real files referenced by path are skipped by the persistence service
/// because browsers cannot re-open files without user interaction.
class SessionStore {
  static const String _indexKey = 'cc.sessions.index';
  static const String _sessionKeyPrefix = 'cc.sessions.item.';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<String?> readIndex() => _prefs.getString(_indexKey);

  Future<void> writeIndex(String payload) =>
      _prefs.setString(_indexKey, payload);

  Future<String?> readSession(String sessionId) =>
      _prefs.getString('$_sessionKeyPrefix$sessionId');

  Future<void> writeSession(String sessionId, String payload) =>
      _prefs.setString('$_sessionKeyPrefix$sessionId', payload);

  Future<void> deleteSession(String sessionId) =>
      _prefs.remove('$_sessionKeyPrefix$sessionId');
}
