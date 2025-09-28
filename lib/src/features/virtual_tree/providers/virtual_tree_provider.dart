import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../directory_tree_adapter.dart';

/// Shared DirectoryTreeAdapter instance for the tree feature.
final directoryTreeAdapterProvider =
    ChangeNotifierProvider<DirectoryTreeAdapter>((ref) {
      return DirectoryTreeAdapter();
    });
