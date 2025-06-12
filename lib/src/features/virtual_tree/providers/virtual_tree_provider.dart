import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/virtual_tree_api.dart';
import '../api/virtual_tree_impl.dart';
import '../state/tree_state.dart';

/// Provider for VirtualTreeAPI implementation
final virtualTreeProvider = Provider<VirtualTreeAPI>((ref) {
  final notifier = ref.watch(treeStateProvider.notifier);
  return VirtualTreeImpl(notifier);
});
