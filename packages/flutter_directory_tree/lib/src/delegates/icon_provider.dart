// lib/src/delegates/icon_provider.dart
import 'package:directory_tree/directory_tree.dart';
import 'package:flutter/material.dart' show Icon, Icons;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

/// A pluggable source of icons for rows.
/// Keep this file `widgets`-only; material bits live here for convenience.
abstract class IconProvider {
  const IconProvider();

  /// Icon before the title (folder/file glyph, badges, etc.)
  Widget? leadingIcon(BuildContext context, VisibleNode node);

  /// Optional trailing adornment (sync status, error mark, etc.)
  Widget? trailingIcon(BuildContext context, VisibleNode node) => null;
}

/// A tiny, sensible default icon set using Material icons.
/// You can replace this with your own provider for IDE-like theming.
class MaterialIconProvider extends IconProvider {
  const MaterialIconProvider();

  @override
  Widget? leadingIcon(BuildContext context, VisibleNode node) {
    if (node.type == NodeType.folder) {
      return const Icon(Icons.folder, size: 18);
    }
    if (node.type == NodeType.root) {
      return const Icon(Icons.storage, size: 18);
    }

    // file
    final ext = p.extension(node.name).toLowerCase();
    final icon = switch (ext) {
      '.dart' => Icons.code,
      '.md' => Icons.article,
      '.json' => Icons.data_object,
      '.yaml' || '.yml' => Icons.description,
      '.png' || '.jpg' || '.jpeg' || '.gif' || '.svg' => Icons.image,
      '.txt' => Icons.description,
      _ => node.isVirtual ? Icons.cloud_queue : Icons.insert_drive_file,
    };
    return Icon(icon, size: 18);
  }
}
