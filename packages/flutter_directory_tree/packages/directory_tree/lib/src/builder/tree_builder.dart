import 'dart:convert';

import 'package:directory_tree/src/models/tree_data.dart';
import 'package:directory_tree/src/models/tree_entry.dart';
import 'package:directory_tree/src/models/tree_node.dart';
import 'package:path/path.dart' as p;

/// Builds a deterministic tree from entries + anchors (TRD-compliant).
/// Result shape:
/// root (invisible)
/// └─ tree/ (visible top-level folder label)
///    ├─ `topParent1`/...
///    └─ `topParent2`/...
class TreeBuilder {
  static const String rootId = 'root';
  static const String treeRootId = 'tree_root';
  static final p.Context _ctx = p.posix;

  /// Canonicalizes a path to a normalized, POSIX-like form.
  /// Adds an optional [unicodeNormalize] hook (e.g., NFC).
  static String _canonicalize(
    String input, {
    String Function(String)? unicodeNormalize,
  }) {
    if (input.isEmpty) return '/';
    final trimmed = input.trim();

    // Unify slashes
    final backslash = String.fromCharCode(0x5c);
    var sanitized = trimmed.contains(backslash)
        ? trimmed.replaceAll(backslash, '/')
        : trimmed;
    if (sanitized.isEmpty) return '/';

    // Optional Unicode normalization (TRD §3.4)
    if (unicodeNormalize != null) {
      sanitized = unicodeNormalize(sanitized);
    }

    // Windows drive handling
    sanitized = sanitized.replaceFirstMapped(
      RegExp(r'^[a-zA-Z]:([/\\])'),
      (m) {
        final drive = m[0]![0].toUpperCase();
        final remainder = m[0]!.substring(1).replaceAll(backslash, '/');
        return '$drive$remainder';
      },
    );

    final isWindowsLike =
        RegExp('^[a-zA-Z]:/').hasMatch(sanitized) || sanitized.startsWith('//');
    final uri = Uri.file(sanitized, windows: isWindowsLike);
    var canonical = uri.path.isEmpty ? '/' : uri.path;
    canonical = Uri.decodeComponent(canonical);

    // Remove the extra leading "/" for "C:/..."
    if (isWindowsLike &&
        canonical.startsWith('/') &&
        canonical.length > 1 &&
        RegExp('^[A-Za-z]:/').hasMatch(canonical.substring(1))) {
      canonical = canonical.substring(1);
    }

    final normalized = _ctx.normalize(canonical);
    return normalized.isEmpty ? '/' : normalized;
  }

  TreeData build({
    required List<TreeEntry> entries,

    /// Optional legacy roots. If [autoComputeAnchors] is true, these are merged
    /// into the computed anchor set before compression.
    List<String> sourceRoots = const [],

    /// TRD: directories the user directly selected (render even if empty).
    List<String> selectedDirectories = const [],

    String rootFolderLabel = 'tree',
    bool expandFoldersByDefault = true,
    bool selectNewFilesByDefault = true,

    /// TRD prefers the **shallowest** root when multiple match.
    bool preferDeepestRoot = false,

    bool sortChildrenByName = true,
    List<String> stripPrefixes = const [],
    bool autoPickVisibleRoot = true,
    int? visibleRootMaxHoistLevels = 2,
    bool visibleRootIgnoreVirtualFiles = true,
    bool mergeVirtualIntoRealFolders = true,

    /// TRD §3.5 — recommended: case-insensitive path policy
    bool caseInsensitivePaths = true,

    /// TRD §3.4 — supply NFC if you have a normalizer library; otherwise leave null
    String Function(String)? unicodeNormalize,

    /// TRD core: compute anchors from files + [selectedDirectories] and compress.
    bool autoComputeAnchors = true,

    /// Hide the container row so top parents render at depth 0 (TRD §6.1).
    bool omitContainerRowAtRoot = false,
  }) {
    String fold(String s) => caseInsensitivePaths ? s.toLowerCase() : s;

    // Normalize strip prefixes (longest-first so deeper prefixes win)
    final normalizedStripPrefixes = [
      for (final prefix in stripPrefixes)
        _canonicalize(prefix, unicodeNormalize: unicodeNormalize),
    ]..sort((a, b) => b.length.compareTo(a.length));

    String stripPath(String path) {
      final normalizedPath = _canonicalize(
        path,
        unicodeNormalize: unicodeNormalize,
      );
      for (final prefix in normalizedStripPrefixes) {
        if (normalizedPath == prefix || _ctx.isWithin(prefix, normalizedPath)) {
          final relative = _ctx.relative(normalizedPath, from: prefix);
          if (relative == '.') {
            final base = _ctx.basename(prefix);
            if (base.isEmpty || base == '.') return '/';
            return '/$base';
          }
          return relative.startsWith('/') ? relative : '/$relative';
        }
      }
      return normalizedPath;
    }

    // Root + container
    final nodes = <String, TreeNode>{
      rootId: TreeNode(
        id: rootId,
        name: 'Root',
        type: NodeType.root,
        parentId: '',
        virtualPath: '/',
        isExpanded: true,
      ),
    };
    final folderCanonicalPaths = <String, String>{};

    final treeRoot = TreeNode(
      id: treeRootId,
      name: rootFolderLabel,
      type: NodeType.folder,
      parentId: rootId,
      virtualPath: _ctx.join('/', rootFolderLabel),
      isExpanded: true,
    );
    nodes[treeRootId] = treeRoot;
    nodes[rootId] = nodes[rootId]!.copyWith(
      childIds: [...nodes[rootId]!.childIds, treeRootId],
    );

    // If nothing at all was provided, early out with the shell tree.
    final hasAnyInput =
        entries.isNotEmpty ||
        selectedDirectories.isNotEmpty ||
        sourceRoots.isNotEmpty;
    if (!hasAnyInput) {
      final visibleRootId = autoPickVisibleRoot
          ? _autoPickVisibleRoot(
              nodes: nodes,
              ignoreVirtualFiles: visibleRootIgnoreVirtualFiles,
              maxLevels: visibleRootMaxHoistLevels,
            )
          : treeRootId;
      return TreeData(
        nodes: nodes,
        rootId: rootId,
        visibleRootId: visibleRootId,
        omitContainerRowAtRoot: omitContainerRowAtRoot,
      );
    }

    // === 1) Normalize + dedup physical file entries by path (TRD §3.7) ===
    final fileRecords = <_EntryRecord>[];
    final seenFileByPath = <String>{};
    for (final e in entries.where((e) => !e.isVirtual)) {
      final cf = _canonicalize(e.fullPath, unicodeNormalize: unicodeNormalize);
      final key = fold(cf);
      if (!seenFileByPath.add(key)) continue; // drop exact duplicates by path
      fileRecords.add(_EntryRecord(entry: e, canonicalPath: cf));
    }

    // === 2) Build anchor universe ===
    final fileAnchors = <String>{
      for (final r in fileRecords) _ctx.dirname(r.canonicalPath),
    };
    final selectedDirCanonByKey = <String, String>{};
    for (final dir in selectedDirectories) {
      final canon = _canonicalize(dir, unicodeNormalize: unicodeNormalize);
      final key = fold(canon);
      selectedDirCanonByKey[key] = canon;
    }
    final selectedDirCanon = selectedDirCanonByKey.values.toSet();
    final selectedDirKeys = selectedDirCanonByKey.keys.toSet();
    final legacyRoots = <String>{
      for (final r in sourceRoots)
        _canonicalize(r, unicodeNormalize: unicodeNormalize),
    };

    final anchorUniverse = autoComputeAnchors
        ? {...fileAnchors, ...selectedDirCanon, ...legacyRoots}
        : {...legacyRoots}; // honoring legacy mode if needed

    // === 3) Compress anchors by ancestry (keep highest / shallowest) ===
    final topAnchors = _compressAnchors(anchorUniverse, caseInsensitivePaths);

    // === 4) Group files under their single top parent ===
    final grouped = <String, List<_EntryRecord>>{};
    String? chooseTopFor(String fullPath) {
      // Find the shallowest top anchor that is an ancestor of [fullPath].
      for (final a in topAnchors) {
        if (_isWithinPolicy(a, fullPath, caseInsensitivePaths)) {
          return a;
        }
      }
      return null;
    }

    for (final r in fileRecords) {
      final top =
          chooseTopFor(r.canonicalPath) ??
          _ctx.dirname(r.canonicalPath); // defensive fallback
      (grouped[top] ??= []).add(r);
    }
    // Ensure directory-only selections appear, even if they have no files.
    for (final a in topAnchors) {
      grouped.putIfAbsent(a, () => <_EntryRecord>[]);
    }

    // === 5) One folder per top anchor under /tree ===
    final sortedRootPaths = topAnchors.toList()..sort();
    final rootLabels = _uniqueRootLabels(sortedRootPaths);
    final rootIds = {
      for (final canonicalPath in sortedRootPaths)
        canonicalPath: _stableRootIdFor(canonicalPath),
    };
    for (final canonicalSourcePath in sortedRootPaths) {
      final folderName =
          rootLabels[canonicalSourcePath] ?? _ctx.basename(canonicalSourcePath);
      final displaySourcePath = stripPath(canonicalSourcePath);

      final node = _findOrCreateFolder(
        nodes: nodes,
        canonicalFolderPaths: folderCanonicalPaths,
        name: folderName,
        parentId: treeRootId,
        parentVirtualPath: nodes[treeRootId]!.virtualPath,
        sourcePath: displaySourcePath,
        canonicalSourcePath: canonicalSourcePath,
        expanded: expandFoldersByDefault,
        forcedId: rootIds[canonicalSourcePath],
        mergeVirtualIntoRealFolders: mergeVirtualIntoRealFolders,
        caseInsensitivePaths: caseInsensitivePaths,
        origin: selectedDirKeys.contains(fold(canonicalSourcePath))
            ? SelectionOrigin.direct
            : SelectionOrigin.inferred,
      );

      // Add grouped files under this top parent, preserving relative path.
      for (final record in grouped[canonicalSourcePath]!) {
        final rel = _ctx.relative(
          record.canonicalPath,
          from: canonicalSourcePath,
        );
        _addFileAndFolders(
          nodes: nodes,
          canonicalFolderPaths: folderCanonicalPaths,
          baseId: node.id,
          relativePath: rel,
          entry: record.entry,
          select: selectNewFilesByDefault,
          expandFolders: expandFoldersByDefault,
          mergeVirtualIntoRealFolders: mergeVirtualIntoRealFolders,
          caseInsensitivePaths: caseInsensitivePaths,
          origin: SelectionOrigin.inferred,
        );
      }
    }

    // === 6) Materialize chains for directly selected subdirectories ===
    // (So directory-only selections nested under a top anchor still appear.)
    for (final dirCanon in selectedDirCanon) {
      // Find its governing top anchor; if none found (unlikely), treat itself as top.
      final top = topAnchors.firstWhere(
        (a) => _isWithinPolicy(a, dirCanon, caseInsensitivePaths),
        orElse: () => dirCanon,
      );
      final topId = rootIds[top]!;
      var parentId = topId;
      var parentVirtualPath = nodes[parentId]!.virtualPath;

      final rel = _ctx.relative(dirCanon, from: top);
      final partsRaw = _ctx.split(rel);
      final parts = partsRaw
          .where((s) => s.isNotEmpty && s != '/' && s != '.')
          .toList();
      if (parts.isEmpty) {
        continue;
      }

      for (var i = 0; i < parts.length; i++) {
        final seg = parts[i];
        final isLeaf = i == parts.length - 1;
        final nextSourcePath =
            '${nodes[topId]!.sourcePath ?? top}/${parts.take(i + 1).join('/')}';
        final nextCanonicalPath = _ctx.join(top, parts.take(i + 1).join('/'));
        final folder = _findOrCreateFolder(
          nodes: nodes,
          canonicalFolderPaths: folderCanonicalPaths,
          name: seg,
          parentId: parentId,
          parentVirtualPath: parentVirtualPath,
          sourcePath: nextSourcePath,
          canonicalSourcePath: nextCanonicalPath,
          expanded: expandFoldersByDefault,
          mergeVirtualIntoRealFolders: mergeVirtualIntoRealFolders,
          caseInsensitivePaths: caseInsensitivePaths,
          origin: isLeaf
              ? SelectionOrigin.direct
              : SelectionOrigin.inferred,
        );
        parentId = folder.id;
        parentVirtualPath = folder.virtualPath;
      }
    }

    // === 7) Place virtual entries ===
    for (final e in entries.where((e) => e.isVirtual)) {
      final parentSpec = (e.metadata?['virtualParent'] as String?)?.trim();
      if (parentSpec == null || parentSpec.isEmpty) {
        _addFile(
          nodes: nodes,
          parentId: treeRootId,
          name: e.name,
          entry: e,
          select: selectNewFilesByDefault,
        );
        continue;
      }

      final backslash = String.fromCharCode(0x5c);
      final cleaned = parentSpec.replaceAll(backslash, '/').trim();
      final normalized = _ctx.normalize('/$cleaned');
      final segments = _ctx
          .split(normalized)
          .where((segment) => segment.isNotEmpty && segment != '/')
          .toList();

      var parentId = treeRootId;
      var parentVirtualPath = nodes[treeRootId]!.virtualPath;
      for (final segment in segments) {
        parentId = _findOrCreateFolder(
          nodes: nodes,
          canonicalFolderPaths: folderCanonicalPaths,
          name: segment,
          parentId: parentId,
          parentVirtualPath: parentVirtualPath,
          expanded: expandFoldersByDefault,
          mergeVirtualIntoRealFolders: mergeVirtualIntoRealFolders,
          caseInsensitivePaths: caseInsensitivePaths,
          origin: SelectionOrigin.inferred,
        ).id;
        parentVirtualPath = nodes[parentId]!.virtualPath;
      }

      _addFile(
        nodes: nodes,
        parentId: parentId,
        name: e.name,
        entry: e,
        select: selectNewFilesByDefault,
      );
    }

    if (sortChildrenByName) {
      _sortAllChildren(nodes);
    }

    final visibleRootId = autoPickVisibleRoot
        ? _autoPickVisibleRoot(
            nodes: nodes,
            ignoreVirtualFiles: visibleRootIgnoreVirtualFiles,
            maxLevels: visibleRootMaxHoistLevels,
          )
        : treeRootId;

    assert(
      () {
        _assertTree(nodes, rootId);
        return true;
      }(),
      'Tree structure failed validation.',
    );

    return TreeData(
      nodes: nodes,
      rootId: rootId,
      visibleRootId: visibleRootId,
      omitContainerRowAtRoot: omitContainerRowAtRoot,
    );
  }

  void _addFileAndFolders({
    required Map<String, TreeNode> nodes,
    required Map<String, String> canonicalFolderPaths,
    required String baseId,
    required String relativePath,
    required TreeEntry entry,
    required bool select,
    required bool expandFolders,
    required bool mergeVirtualIntoRealFolders,
    required bool caseInsensitivePaths,
    SelectionOrigin origin = SelectionOrigin.none,
  }) {
    final parts = _ctx.split(relativePath).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return;

    var parentId = baseId;
    String? parentSourcePath = nodes[parentId]!.sourcePath;
    String? parentCanonicalPath = canonicalFolderPaths[parentId];

    for (var i = 0; i < parts.length - 1; i++) {
      final segment = parts[i];
      final parent = nodes[parentId]!;
      final nextSourcePath = parentSourcePath != null
          ? _ctx.join(parentSourcePath, segment)
          : null;
      final nextCanonicalPath = parentCanonicalPath != null
          ? _ctx.join(parentCanonicalPath, segment)
          : null;

      parentId = _findOrCreateFolder(
        nodes: nodes,
        canonicalFolderPaths: canonicalFolderPaths,
        name: segment,
        parentId: parentId,
        parentVirtualPath: parent.virtualPath,
        sourcePath: nextSourcePath,
        canonicalSourcePath: nextCanonicalPath,
        expanded: expandFolders,
        mergeVirtualIntoRealFolders: mergeVirtualIntoRealFolders,
        caseInsensitivePaths: caseInsensitivePaths,
        origin: origin == SelectionOrigin.direct
            ? SelectionOrigin.direct
            : SelectionOrigin.inferred,
      ).id;

      parentSourcePath = nodes[parentId]!.sourcePath ?? nextSourcePath;
      parentCanonicalPath = canonicalFolderPaths[parentId] ?? nextCanonicalPath;
    }

    _addFile(
      nodes: nodes,
      parentId: parentId,
      name: parts.last,
      entry: entry,
      select: select,
    );
  }

  void _addFile({
    required Map<String, TreeNode> nodes,
    required String parentId,
    required String name,
    required TreeEntry entry,
    required bool select,
  }) {
    final parent = nodes[parentId]!;
    final nodeId = 'node_${entry.id}';
    if (nodes.containsKey(nodeId)) return;

    final node = TreeNode(
      id: nodeId,
      name: name,
      type: NodeType.file,
      parentId: parentId,
      virtualPath: _ctx.join(parent.virtualPath, name),
      sourcePath: entry.fullPath,
      entryId: entry.id,
      isVirtual: entry.isVirtual,
      isSelected: select,
    );
    nodes[nodeId] = node;
    nodes[parentId] = parent.copyWith(childIds: [...parent.childIds, nodeId]);
  }

  TreeNode _findOrCreateFolder({
    required Map<String, TreeNode> nodes,
    required Map<String, String> canonicalFolderPaths,
    required String name,
    required String parentId,
    required String parentVirtualPath,
    String? sourcePath,
    String? canonicalSourcePath,
    bool expanded = true,
    String? forcedId,
    bool mergeVirtualIntoRealFolders = true,
    bool caseInsensitivePaths = true,
    SelectionOrigin origin = SelectionOrigin.none,
  }) {
    assert(
      !name.contains('/'),
      'Folder names must not contain "/" characters.',
    );
    final parent = nodes[parentId]!;

    final normalizedDisplaySourcePath = sourcePath != null
        ? _ctx.normalize(sourcePath)
        : null;
    final normalizedCanonicalSourcePath = canonicalSourcePath != null
        ? _ctx.normalize(canonicalSourcePath)
        : null;
    final canonKey = normalizedCanonicalSourcePath == null
        ? null
        : (caseInsensitivePaths
              ? normalizedCanonicalSourcePath.toLowerCase()
              : normalizedCanonicalSourcePath);

    // If caller provides a stable id and it exists, update it.
    if (forcedId != null && nodes.containsKey(forcedId)) {
      final existing = nodes[forcedId]!;
      assert(
        existing.type == NodeType.folder,
        'Node $forcedId is not a folder.',
      );
      if (normalizedCanonicalSourcePath != null) {
        canonicalFolderPaths[forcedId] = normalizedCanonicalSourcePath;
      }
      final desiredOrigin = _mergeOrigin(existing.origin, origin);
      final needUpdate =
          existing.name != name ||
          (normalizedDisplaySourcePath != null &&
              (existing.sourcePath == null ||
                  _ctx.normalize(existing.sourcePath!) !=
                      normalizedDisplaySourcePath)) ||
          existing.isExpanded != expanded ||
          existing.origin != desiredOrigin;
      if (needUpdate) {
        nodes[forcedId] = existing.copyWith(
          name: name,
          sourcePath: normalizedDisplaySourcePath ?? existing.sourcePath,
          isExpanded: expanded,
          origin: desiredOrigin,
        );
      }
      if (!parent.childIds.contains(forcedId)) {
        nodes[parentId] = parent.copyWith(
          childIds: [...parent.childIds, forcedId],
        );
      }
      return nodes[forcedId]!;
    }

    // Try to find a sibling folder we can merge with.
    for (final cid in parent.childIds) {
      final c = nodes[cid]!;
      if (c.type != NodeType.folder || c.name != name) continue;

      final existingCanonical = canonicalFolderPaths[cid];
      final existingKey = existingCanonical == null
          ? null
          : (caseInsensitivePaths
              ? existingCanonical.toLowerCase()
              : existingCanonical);
      final bothNull = canonKey == null && existingKey == null;
      final bothEqual =
          canonKey != null && existingKey != null && existingKey == canonKey;
      final canMergeVirtualIntoReal =
          mergeVirtualIntoRealFolders &&
          canonKey == null &&
          existingCanonical != null;
      final canMergeRealIntoVirtual =
          mergeVirtualIntoRealFolders &&
          canonKey != null &&
          existingCanonical == null;

      if (!(bothNull ||
          bothEqual ||
          canMergeVirtualIntoReal ||
          canMergeRealIntoVirtual)) {
        continue;
      }

      if (normalizedCanonicalSourcePath != null) {
        canonicalFolderPaths[cid] = normalizedCanonicalSourcePath;
      }
      var updated = c;
      if (normalizedDisplaySourcePath != null && c.sourcePath == null) {
        updated = updated.copyWith(sourcePath: normalizedDisplaySourcePath);
      }
      final desiredOrigin = _mergeOrigin(updated.origin, origin);
      if (updated.origin != desiredOrigin) {
        updated = updated.copyWith(origin: desiredOrigin);
      }
      if (!identical(updated, c)) {
        nodes[cid] = updated;
      }
      return nodes[cid]!;
    }

    // Create a new folder.
    final folderVirtualPath = _ctx.join(parentVirtualPath, name);
    final folderId =
        forcedId ??
        (normalizedCanonicalSourcePath != null
            ? _folderIdForSourcePath(normalizedCanonicalSourcePath)
            : _folderIdForVirtualPath(folderVirtualPath));
    final folder = TreeNode(
      id: folderId,
      name: name,
      type: NodeType.folder,
      parentId: parentId,
      virtualPath: folderVirtualPath,
      sourcePath: normalizedDisplaySourcePath,
      isExpanded: expanded,
      origin: origin,
    );
    nodes[folder.id] = folder;
    nodes[parentId] = parent.copyWith(
      childIds: [...parent.childIds, folder.id],
    );
    if (normalizedCanonicalSourcePath != null) {
      canonicalFolderPaths[folder.id] = normalizedCanonicalSourcePath;
    }
    return folder;
  }

  static String _folderIdForSourcePath(String canonicalSourcePath) {
    final segments = _ctx
        .split(canonicalSourcePath)
        .where((segment) => segment.isNotEmpty)
        .toList();
    final base = segments.isNotEmpty ? segments.last : 'root';
    final sanitizedBase = base.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
    final digest = base64Url
        .encode(utf8.encode(canonicalSourcePath))
        .replaceAll('=', '');
    return 'folder_sp_${sanitizedBase}_$digest';
  }

  String _folderIdForVirtualPath(String virtualPath) {
    final backslash = String.fromCharCode(0x5c);
    final normalized = virtualPath.contains(backslash)
        ? virtualPath.replaceAll(backslash, '/')
        : virtualPath;
    final sanitized = normalized.replaceAll(RegExp('[^a-zA-Z0-9/_-]'), '_');
    final label = sanitized.replaceAll('/', '_');
    final digest = base64Url
        .encode(utf8.encode(normalized))
        .replaceAll('=', '');
    final suffix = label.isEmpty || label.replaceAll('_', '').isEmpty
        ? 'root'
        : label;
    return 'folder_${suffix}_$digest';
  }

  void _sortAllChildren(Map<String, TreeNode> nodes) {
    int compare(String aId, String bId) {
      final a = nodes[aId]!;
      final b = nodes[bId]!;
      if (a.type != b.type) {
        return a.type == NodeType.folder ? -1 : 1;
      }
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) return byName;
      return a.id.compareTo(b.id);
    }

    for (final entry in nodes.entries) {
      final node = entry.value;
      if (node.type != NodeType.folder || node.childIds.isEmpty) continue;
      final sorted = List<String>.from(node.childIds)..sort(compare);
      nodes[node.id] = node.copyWith(childIds: sorted);
    }
  }

  String _autoPickVisibleRoot({
    required Map<String, TreeNode> nodes,
    required bool ignoreVirtualFiles,
    int? maxLevels,
  }) {
    var current = treeRootId;
    var levels = 0;
    while (true) {
      final node = nodes[current]!;
      final children = node.childIds.map((id) => nodes[id]!).toList();
      final folderChildren = children
          .where((n) => n.type == NodeType.folder)
          .toList();
      final fileChildren = children.where((n) {
        if (n.type != NodeType.file) return false;
        if (ignoreVirtualFiles && n.isVirtual) return false;
        return true;
      }).toList();

      final canHoist =
          folderChildren.length == 1 &&
          fileChildren.isEmpty &&
          (maxLevels == null || levels < maxLevels);
      if (!canHoist) break;

      current = folderChildren.single.id;
      levels += 1;
    }
    return current;
  }

  static String _stableRootIdFor(String canonicalSourcePath) {
    final segments = _ctx
        .split(canonicalSourcePath)
        .where((s) => s.isNotEmpty)
        .toList();
    final base = segments.isNotEmpty ? segments.last : 'root';
    final sanitizedBase = base.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
    final digest = base64Url
        .encode(utf8.encode(canonicalSourcePath))
        .replaceAll('=', '');
    return 'folder_sr_${sanitizedBase}_$digest';
  }

  static Map<String, String> _uniqueRootLabels(Iterable<String> paths) {
    final canonicalPaths = paths.toList();
    if (canonicalPaths.isEmpty) return {};

    final segments = <String, List<String>>{
      for (final path in canonicalPaths)
        path: _ctx.split(path).where((s) => s.isNotEmpty).toList(),
    };
    final take = <String, int>{
      for (final path in canonicalPaths) path: 1,
    };

    String labelFor(String path) {
      final segs = segments[path]!;
      if (segs.isEmpty) return 'root';
      var count = take[path] ?? 1;
      if (count < 1) count = 1;
      if (count > segs.length) count = segs.length;
      final slice = segs.sublist(segs.length - count);
      return slice.join(' - ');
    }

    while (true) {
      final byLabel = <String, List<String>>{};
      for (final path in canonicalPaths) {
        final label = labelFor(path);
        byLabel.putIfAbsent(label, () => []).add(path);
      }
      final conflicts = byLabel.values
          .where((group) => group.length > 1)
          .toList();
      if (conflicts.isEmpty) {
        return {for (final path in canonicalPaths) path: labelFor(path)};
      }

      var grew = false;
      for (final group in conflicts) {
        for (final path in group) {
          final segs = segments[path]!;
          final current = take[path] ?? 1;
          if (current < segs.length) {
            take[path] = current + 1;
            grew = true;
          }
        }
      }

      if (!grew) {
        final fallback = <String, String>{};
        for (final path in canonicalPaths) {
          final baseLabel = labelFor(path);
          final digest = base64Url
              .encode(utf8.encode(path))
              .replaceAll('=', '');
          final shortDigest = digest.length > 6
              ? digest.substring(0, 6)
              : digest;
          fallback[path] = '$baseLabel [$shortDigest]';
        }
        return fallback;
      }
    }
  }

  void _assertTree(Map<String, TreeNode> nodes, String rootId) {
    for (final entry in nodes.entries) {
      final node = entry.value;
      for (final childId in node.childIds) {
        final child = nodes[childId];
        assert(
          child != null,
          'Missing child node $childId referenced by parent ${node.id}',
        );
        assert(
          child!.parentId == node.id,
          'Child $childId points to ${child.parentId} instead of ${node.id}',
        );
      }
    }

    final visited = <String>{};
    final stack = <String>{};

    bool visit(String id) {
      if (!visited.add(id)) return true;
      stack.add(id);
      for (final childId in nodes[id]!.childIds) {
        if (stack.contains(childId)) {
          return false;
        }
        if (!visit(childId)) {
          return false;
        }
      }
      stack.remove(id);
      return true;
    }

    assert(
      visit(rootId),
      'Cycle detected while validating the tree structure.',
    );
  }

  static SelectionOrigin _mergeOrigin(
    SelectionOrigin current,
    SelectionOrigin incoming,
  ) {
    if (current == SelectionOrigin.direct || incoming == SelectionOrigin.direct) {
      return SelectionOrigin.direct;
    }
    if (current == SelectionOrigin.inferred ||
        incoming == SelectionOrigin.inferred) {
      return SelectionOrigin.inferred;
    }
    return SelectionOrigin.none;
  }

  // === Helpers: TRD anchor compression & ancestry ===

  /// Compress anchors by removing any anchor that is a descendant of another anchor.
  /// Returns anchors ordered shallowest first, then lexicographically.
  static List<String> _compressAnchors(
    Iterable<String> anchors,
    bool caseInsensitive,
  ) {
    // Dedup by case policy
    final byFold = <String, String>{};
    for (final a in anchors) {
      final key = caseInsensitive ? a.toLowerCase() : a;
      byFold[key] = a; // last wins; order not critical here
    }
    final list = byFold.values.toList()
      ..sort((a, b) {
        final al = _ctx.split(a).where((s) => s.isNotEmpty).length;
        final bl = _ctx.split(b).where((s) => s.isNotEmpty).length;
        if (al != bl) return al.compareTo(bl); // shallowest first
        final ac = caseInsensitive ? a.toLowerCase() : a;
        final bc = caseInsensitive ? b.toLowerCase() : b;
        return ac.compareTo(bc);
      });

    final out = <String>[];
    for (final cand in list) {
      final keep = out.every(
        (kept) => !_isWithinPolicy(kept, cand, caseInsensitive) || kept == cand,
      );
      if (keep) out.add(cand);
    }
    return out;
  }

  /// Returns true if [parent] is an ancestor of (or equal to) [child]
  /// under the given case policy.
  static bool _isWithinPolicy(
    String parent,
    String child,
    bool caseInsensitive,
  ) {
    final pth = caseInsensitive ? parent.toLowerCase() : parent;
    final cth = caseInsensitive ? child.toLowerCase() : child;
    if (pth == cth) return true;
    final ps = _ctx.split(pth).where((s) => s.isNotEmpty).toList();
    final cs = _ctx.split(cth).where((s) => s.isNotEmpty).toList();
    if (ps.length > cs.length) return false;
    for (var i = 0; i < ps.length; i++) {
      if (ps[i] != cs[i]) return false;
    }
    return true;
  }
}

class _EntryRecord {
  const _EntryRecord({
    required this.entry,
    required this.canonicalPath,
  });

  final TreeEntry entry;
  final String canonicalPath;
}
