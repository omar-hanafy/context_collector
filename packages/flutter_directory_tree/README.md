# flutter_directory_tree

Widget helpers and controllers that turn the canonical `directory_tree` data
into a Flutter-friendly file navigator. The package keeps the path rules we
spelled out in `tech_requirement.md`: you hand us a cleaned set of file
entries, we keep the structure stable across rebuilds and make the compact
root decisions deterministic.

## Path & root handling
- Provide `TreeEntry` objects for every effective file (expand dropped
  directories before you call the builder) so rule 3’s selected-set `S` is
  explicit.
- `TreeBuilder` canonicalizes input paths (slashes, drive letters, `.` / `..`)
  and derives stable folder IDs (`packages/directory_tree/lib/src/builder/tree_builder.dart:17-210`),
  so deduplication and Windows/Posix parity come for free.
- Compute `sourceRoots` with the LCA policy from the spec: for each volume,
  pick the deepest ancestor that still has direct files; if none do, pass each
  qualifying child folder instead. Those roots drop straight into the builder
  and give you cases #1–#3 exactly.
- The builder sorts folders first, files second, and hoists single-child
  containers by default via `autoPickVisibleRoot`
  (`packages/directory_tree/lib/src/builder/tree_builder.dart:428-540`), so the
  visible root already matches the “smallest meaningful root” language.
- Mixed volumes or casing mismatches are normalized before grouping, which is
  covered by the Windows/Linux tests in `packages/directory_tree/test/tree_builder_test.dart`.

## User-facing behaviour
- `TreeData.visibleRootId` lands on the compact root; if you prefer to hide the
  container row entirely, pass the branch folders as `sourceRoots` or swap in a
  flatten strategy that skips the visible root (the UI accepts any
  `FlattenStrategy`).
- `virtualPath` and `sourcePath` stay aligned with the canonical inputs, so
  `DirectoryTreeController` can rebuild without losing reveal/selection state
  (`lib/src/controller/directory_tree_controller.dart`).
- Because grouping happens per canonical root, multiple drop sessions or drives
  naturally become sibling roots; tests such as
  `handles empty sourceRoots by grouping on directory` guarantee the behaviour.

## Optional polish

✨ Animated row background for people who want hover/selection/focus visuals
without touching their public API:

```dart
// Lightweight decorator to layer on top of your NodeBuilder.
import 'package:flutter/widgets.dart';
import '../theme/directory_tree_theme.dart';

class TreeRowBackground extends StatefulWidget {
  const TreeRowBackground({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  State<TreeRowBackground> createState() => _TreeRowBackgroundState();
}

class _TreeRowBackgroundState extends State<TreeRowBackground> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = DirectoryTreeTheme.of(context);
    final t = Curves.easeOutCubic;
    final bg = widget.selected
        ? (theme.selectionColor ?? const Color(0x2A2196F3))
        : (_hover ? (theme.hoverColor ?? const Color(0x11000000)) : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: theme.animationDuration,
        curve: t,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: theme.roundedCorners ? BorderRadius.circular(4) : null,
        ),
        child: widget.child,
      ),
    );
  }
}

nodeBuilder: (ctx, node, st) => TreeRowBackground(
  selected: st.isSelected,
  child: TreeNodeTile(
    node: node,
    state: st,
    // ...your current leading/title/trailing etc.
  ),
),
```
