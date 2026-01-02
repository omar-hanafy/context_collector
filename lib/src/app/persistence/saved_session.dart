import 'package:flutter/foundation.dart';

@immutable
class VirtualFileSnapshot {
  const VirtualFileSnapshot({
    required this.name,
    required this.content,
    this.virtualPath,
  });

  factory VirtualFileSnapshot.fromJson(Map<String, dynamic> json) {
    return VirtualFileSnapshot(
      name: json['name'] as String,
      content: json['content'] as String? ?? '',
      virtualPath: json['virtualPath'] as String?,
    );
  }

  final String name;
  final String content;
  final String? virtualPath;

  Map<String, dynamic> toJson() => {
    'name': name,
    'content': content,
    'virtualPath': virtualPath,
  };
}

@immutable
class SavedSession {
  const SavedSession({
    required this.sessionId,
    required this.title,
    required this.savedAt,
    required this.filePaths,
    required this.virtualFiles,
    required this.selectedKeys,
    required this.viewingAll,
    required this.isActive,
    this.schemaVersion = currentSchemaVersion,
    this.activeKey,
    this.editedOverridesByPath = const <String, String>{},
  });

  factory SavedSession.fromJson(Map<String, dynamic> json) {
    final sessionId =
        (json['sessionId'] as String?) ?? (json['id'] as String? ?? '');
    return SavedSession(
      sessionId: sessionId,
      title: json['title'] as String? ?? 'Tab',
      savedAt: DateTime.parse(json['savedAt'] as String).toUtc(),
      filePaths: (json['filePaths'] as List<dynamic>).cast<String>(),
      virtualFiles: (json['virtualFiles'] as List<dynamic>)
          .map(
            (dynamic raw) => VirtualFileSnapshot.fromJson(
              (raw as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
      selectedKeys:
          (json['selectedKeys'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>(),
      viewingAll: json['viewingAll'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      activeKey: json['activeKey'] as String?,
      editedOverridesByPath:
          (json['editedOverridesByPath'] as Map<dynamic, dynamic>? ?? const {})
              .map(
                (dynamic key, dynamic value) =>
                    MapEntry(key as String, value as String),
              ),
    );
  }

  static const int currentSchemaVersion = 1;

  final String sessionId;
  final String title;
  final DateTime savedAt;
  final List<String> filePaths;
  final List<VirtualFileSnapshot> virtualFiles;
  final List<String> selectedKeys;
  final bool viewingAll;
  final bool isActive;
  final int schemaVersion;
  final String? activeKey;
  final Map<String, String> editedOverridesByPath;

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'id': sessionId,
    'title': title,
    'savedAt': savedAt.toIso8601String(),
    'filePaths': filePaths,
    'virtualFiles': [for (final file in virtualFiles) file.toJson()],
    'selectedKeys': selectedKeys,
    'viewingAll': viewingAll,
    'isActive': isActive,
    'schemaVersion': schemaVersion,
    'activeKey': activeKey,
    'editedOverridesByPath': editedOverridesByPath,
  };

  SavedSession copyWith({
    String? sessionId,
    String? title,
    DateTime? savedAt,
    List<String>? filePaths,
    List<VirtualFileSnapshot>? virtualFiles,
    List<String>? selectedKeys,
    bool? viewingAll,
    bool? isActive,
    int? schemaVersion,
    String? activeKey,
    Map<String, String>? editedOverridesByPath,
  }) {
    return SavedSession(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      savedAt: savedAt ?? this.savedAt,
      filePaths: filePaths ?? this.filePaths,
      virtualFiles: virtualFiles ?? this.virtualFiles,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      viewingAll: viewingAll ?? this.viewingAll,
      isActive: isActive ?? this.isActive,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      activeKey: activeKey ?? this.activeKey,
      editedOverridesByPath:
          editedOverridesByPath ?? this.editedOverridesByPath,
    );
  }
}

@immutable
class SavedSessionIndexItem {
  const SavedSessionIndexItem({
    required this.sessionId,
    required this.title,
    required this.savedAt,
    required this.fileCount,
    required this.isActive,
  });

  factory SavedSessionIndexItem.fromJson(Map<String, dynamic> json) {
    final sessionId =
        (json['sessionId'] as String?) ?? (json['id'] as String? ?? '');
    return SavedSessionIndexItem(
      sessionId: sessionId,
      title: json['title'] as String? ?? 'Tab',
      savedAt: DateTime.parse(json['savedAt'] as String).toUtc(),
      fileCount: json['fileCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  final String sessionId;
  final String title;
  final DateTime savedAt;
  final int fileCount;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'id': sessionId,
    'title': title,
    'savedAt': savedAt.toIso8601String(),
    'fileCount': fileCount,
    'isActive': isActive,
  };

  SavedSessionIndexItem copyWith({
    DateTime? savedAt,
    int? fileCount,
    bool? isActive,
    String? title,
  }) {
    return SavedSessionIndexItem(
      sessionId: sessionId,
      title: title ?? this.title,
      savedAt: savedAt ?? this.savedAt,
      fileCount: fileCount ?? this.fileCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
