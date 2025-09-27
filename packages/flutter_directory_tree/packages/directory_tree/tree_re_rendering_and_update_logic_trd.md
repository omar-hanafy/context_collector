# Tree Rendering from Selected Paths (TRD)

**Audience:** Frontend + UX + QA  
**Author:** Omar (edited by assistant)  
**Version:** v1.0  
**Goal:** A *no‑code* specification that removes ambiguity and tells the developer *exactly* how the tree must behave.

---

## 0) One‑line Summary
Render a file tree from a user’s **added** paths. The visible roots (**top parents**) are the **highest** selected directories that contain other selected items, after **compressing** away any selected directories that sit **under** another selected directory.

---

## 1) Scope & Non‑Goals

**In scope**
- Building and updating a tree UI from a set of user‑added paths (files or directories).
- Determining which nodes appear as **top parents** vs nested.
- Stable ordering, normalization, deduplication, and clear UI behavior.
- Bulk add and remove (if removal exists in the UI).

**Out of scope**
- Any filesystem mutation (no create/move/delete).
- “Smart” inference beyond the rules here (no VCS, no symlink resolution, no content peeking).
- Code samples or pseudocode (intentionally excluded).

---

## 2) Canonical Terminology
- **Add / Drop / Include**: user action that puts a path into the current selection.
- **Selected item**: a path added by the user (file or directory).
- **Anchor**:
  - for a **file**: its **parent directory**.
  - for a **directory**: the directory **itself**.
- **Anchor set**: the set of all anchors for the current selection (after normalization & dedup).
- **Ancestor**: Directory `A` is an ancestor of directory `B` iff `A` appears on `B`’s directory chain (one or more levels).
- **Top parent(s)**: the subset of the anchor set that are **not descendants** of any other anchor.
- **Materialized tree**: the rendered hierarchy consisting of top parents and the minimal intermediate directories necessary to display all selected items.

---

## 3) Normalization Rules (must run before any logic)
For every path received:
1. **Separator unification**: Internally use `/` as the separator.
2. **Remove trailing separator**: Except for the filesystem root (e.g., `/`, `C:/`).
3. **Collapse dot segments**: Resolve `.` and `..` segments.
4. **Unicode normalization**: NFC for consistent display/sorting (note macOS often stores NFD on disk; normalize for UI consistency).
5. **Case handling**: Compare & order **case‑insensitively** on macOS/Windows, **case‑sensitively** on Linux. If cross‑platform parity is desired, choose a global policy and apply it everywhere (recommended: **case‑insensitive** for simplicity).
6. **Symlinks**: **Do not resolve.** Treat the literal normalized string as identity. (If you later add realpath resolution, gate it behind a feature flag.)
7. **Deduplication**: Exact normalized duplicates are dropped (case rules applied per 3.5).
8. **Type determination**: Do **not** infer file/dir from extensions; rely on trusted metadata (e.g., `isDirectory` from the file picker or a stat call). If unavailable, treat as unknown and see §11.5.

> **Invariant N1:** All subsequent computations (anchors, ancestry, ordering) operate on the **normalized** forms.

---

## 4) Core Behavior (the part people get wrong)
Given the current **selection** of paths:

### 4.1 Build the anchor set
- For each selected **file**, take its **parent directory**.
- For each selected **directory**, take the **directory itself**.
- Deduplicate anchors (per §3.7).

### 4.2 Compress by ancestry (determine top parents)
- If an anchor **A** is an **ancestor** of another anchor **B**, **A remains** and **B is removed from top level** (B still exists in the tree; it just won’t be a top parent).
- The **top parent set** is: all anchors that are **not** descendants of any other anchor.

### 4.3 Materialize the display tree
- For each **top parent**, display it as a visible root.
- Under each top parent, materialize the **shortest necessary chain** of intermediate directories needed to show all selected files and directories that fall under that top parent.
- Every selected item appears exactly once under its **nearest ancestor anchor**.

> **Invariant C1:** No top parent is a descendant of another top parent.  
> **Invariant C2:** Each selected item belongs to exactly one top parent subtree.

---

## 5) Ordering Rules (deterministic)
- **Top parents**: sort **alphabetically** by their **full normalized path** (acceptable alternative: by base name; pick one and stick to it).
- **Within any directory level**: (1) directories first (alphabetical), then (2) files (alphabetical).
- Ties are resolved by full normalized path compare.
- No recency/MRU ordering unless specified as a separate user setting (not part of this TRD).

---

## 6) UI Behavior & Visual States
### 6.1 Node rendering
- Each **top parent** is a root node in the tree.
- Each node shows a **display name** (base name) and a **tooltip** with the full normalized path.
- Directories that are present **only as inferred intermediates** (not directly selected) use a **subtle secondary style** (lighter icon or label) so users can distinguish structure from selection.
- If a directory node would be empty in the **materialized** view (because no selected items are under it), **do not show** it unless the directory itself was directly selected (see §11.4).

### 6.2 Selection indicators
- **Directly selected directory**: show a **solid selection marker** on that node.
- **Inferred intermediate directory**: show a **hollow/secondary** marker (or none) distinct from direct selection.
- **Selected files**: appear under their anchors and carry a standard “selected” affordance consistent with the app.

### 6.3 Add / Remove actions
- **Add**: Merge new paths into the selection, run §4.1–4.3, and re‑render.
- **Remove**: Remove paths from the selection, run §4.1–4.3, and re‑render.
- **Idempotence**: Adding the same path twice yields no change after the first add.
- **Atomicity**: Bulk adds/removes compute from the union/difference and then render **once** (avoid flicker of intermediate states).

### 6.4 Large directories / performance hints
- **Lazy materialization**: Only materialize directories required to display selected items and their minimal context.
- Optional: If metadata is available, show a small badge like “(+23 not shown)” to indicate many non‑selected siblings exist at a level.

### 6.5 Expand/Collapse
- Standard tree affordances apply. Expansion state is independent of selection state. Persist expansion state per node key if feasible.

### 6.6 Accessibility (a11y)
- Nodes are exposed via an ARIA tree pattern.
- Keyboard: Up/Down to move; Left to collapse; Right to expand; Space/Enter to select (if selection is interactive); `Home`/`End` jump to first/last visible node.
- Tooltip content (full path) must be screen‑reader accessible (e.g., `aria-label`).

---

## 7) Canonical Walkthroughs (must match exactly)
Below, “top parent(s)” are the visible root nodes **after** compression.

### Case A — Add a file under `.../scan/models/`
Add: `/Users/omarhanafy/scripts/context_collector/lib/src/features/scan/models/file_category.dart`

**Anchor set**: `{ .../scan/models }`  
**Top parent(s)**: `models` (under `scan`)

```
models/
  file_category.dart
```

### Case B — Add a sibling under `.../scan/services/`
Add: `.../scan/services/markdown_builder.dart`

**Anchor set**: `{ .../scan/models, .../scan/services }`  
**Top parent(s)**: `models`, `services`

```
models/
  file_category.dart
services/
  markdown_builder.dart
```

### Case C — Add `.../scan/scan.dart`
Add: `.../scan/scan.dart` (anchor = `.../scan`)

`.../scan` is an **ancestor** of both `.../scan/models` and `.../scan/services` → it dominates as the single top parent.

**Top parent(s)**: `scan`

```
scan/
  scan.dart
  models/
    file_category.dart
  services/
    markdown_builder.dart
```

### Case D — Add `.../features/editor/` (a directory)
Add: `.../features/editor/` (anchor = itself)

**Top parent(s)** under `features`: `scan`, `editor`

```
scan/
  ...
editor/
  (its contents as selected/known)
```

### Case E — Add `.../lib/src/context_collector.dart` **or** the directory `.../lib/src/`
Add either: `.../lib/src/context_collector.dart` **or** `.../lib/src/`

Anchor includes `.../lib/src`. `.../lib/src` is an ancestor of `.../lib/src/features/scan` and `.../lib/src/features/editor`.

**Top parent**: `src`

```
src/
  context_collector.dart   (if that file was added)
  features/
    scan/
      ...
    editor/
      ...
```

### Case F — Add repo root file `.../context_collector/pubspec.yaml`
Add: `.../context_collector/pubspec.yaml` (anchor = `.../context_collector`)

This is an ancestor of everything under the repo.

**Top parent**: `context_collector`

```
context_collector/
  pubspec.yaml
  lib/
    src/
      features/
        scan/...
        editor/...
```

**These six scenarios are the acceptance baselines.**

---

## 8) Edge Cases (explicit & required)
1. **Selecting both a directory and a file under it**  
   The directory remains the anchor; the file appears beneath it. No duplicate top parents.
2. **Selecting overlapping directories** (e.g., `scan/` and `scan/models/`)  
   `scan/` dominates as the top parent; `models/` is nested.
3. **Multiple disjoint trees** (e.g., two different projects)  
   You’ll see **multiple top parents**, one per disjoint anchor subtree.
4. **Empty directory selection**  
   If a directory is selected but has **no** selected descendants and no selected files directly inside, still show that directory as a node (it was **directly selected**).
5. **Duplicate adds**  
   Harmless; dedup ensures only one instance.
6. **Case‑only duplicates (on macOS/Windows)**  
   Treated as the same path for ordering and dedup.
7. **Invalid or disappearing paths**  
   Do not crash; mark invalid; exclude from ancestry calculations **for that render**. Recompute on the next successful stat.
8. **Trailing slashes**  
   Ignored after normalization; `/a/b/` == `/a/b`.
9. **Windows drive letters**  
   Normalize to `C:/...` form internally; drives are disjoint roots.
10. **Symlinks**  
    Literal path identity; different symlink paths to the same target are distinct (by design in this TRD).
11. **Unknown type at add time**  
    If `isDirectory`/`isFile` is unknown, optimistically assume **file** for anchoring (parent directory as anchor). When real metadata arrives, recompute if needed.
12. **Hidden entries**  
    Hidden files/dirs (dot‑prefixed) follow the same rules; no special treatment unless separately configured.

---

## 9) Data Model (no code; name the fields)
- **SelectedItem**: `{ id, fullPathNormalized, type: file|directory|unknown }`
- **Anchor**: `{ fullPathNormalized }` (always a directory)
- **Node**: `{ key, baseName, fullPathNormalized, kind: directory|file, selected: direct|inferred|none, state: normal|invalid|loading }`

> **Key rule:** `key` must be stable across renders for the same normalized path.

---

## 10) Events & State Transitions (no pseudocode)
- **onAdd(paths[])** → normalize → merge into selection → recompute anchors → compress → materialize → render.
- **onRemove(paths[])** → normalize → subtract from selection → recompute anchors → compress → materialize → render.
- **onMetadata(path, typeResult)** (async) → update type → recompute if the anchor would change.

All recomputations are **atomic** with respect to a single UI update.

---

## 11) Non‑functional Requirements
- **Performance**: For selections up to 5,000 items, first render ≤ 100ms budget on a modern laptop; subsequent updates ≤ 50ms. Use lazy materialization and memoization of normalized paths.
- **Stability**: Tree order and node keys must be deterministic given the same input set.
- **Persistence**: (If product requires) persist selection and expansion state; restoring must re‑apply §3–§5 to regenerate the tree deterministically.
- **i18n/L10n**: Sorting uses locale‑aware compare consistent with the chosen case policy.
- **Accessibility**: See §6.6.

---

## 12) Test Plan (acceptance criteria)

**General**
- Given a set of paths, after add, the **anchor set** equals the **parent dirs for files** plus **the dirs themselves** for directories.
- After compression, **no top parent** is a descendant of another **top parent**.
- All selected items appear **exactly once** under a single top parent.

**Specific (must pass exactly as written)**
1. Add `.../scan/models/file_category.dart` → top parents: `models`
2. Add `.../scan/services/markdown_builder.dart` → top parents: `models`, `services`
3. Add `.../scan/scan.dart` → top parents: `scan`
4. Add `.../features/editor/` → top parents: `scan`, `editor`
5. Add `.../lib/src/context_collector.dart` **or** `.../lib/src/` → top parent: `src`
6. Add `.../pubspec.yaml` → top parent: `context_collector`

**Edge checks**
- Add `scan/` and `scan/models/` → top parent: `scan`
- Add two unrelated roots → two top parents (both visible)
- Add same path twice → no change after first
- Remove `scan/` when `scan/models/` remains → top parents: `models` (and any siblings)
- Add an unknown‑type path, then update it to directory → anchors recomputed and top parents updated accordingly

---

## 13) UX Copy & Visual Notes
- Tooltip: *Full path* (normalized). Example: `…/lib/src/features/scan/models`.
- Error badge text for invalid/missing path: “Unavailable (permissions or missing)”.
- Optional count badge: “(+N not shown)” when there are known but un‑materialized siblings.

---

## 14) Open Questions (decide before implementation)
1. **Global case policy**: Lock to case‑insensitive everywhere for consistency, or mirror OS behavior? (Recommendation: **case‑insensitive** for simplicity.)
2. **Persistence**: Should selection/expansion state persist across sessions? If yes, define the storage key & lifecycle.
3. **Hidden entries**: Any product‑level setting to hide/show dotfiles by default?
4. **Tooltip truncation**: Should tooltips wrap or middle‑truncate long paths?
5. **Locale sorting**: Use OS locale or app‑level locale?

---

## 15) Rationale (why these rules)
- Anchoring on parent directories for files guarantees that files never appear as roots; visible roots are always directories users can reason about.
- Compression by ancestry guarantees a clean, non‑duplicated set of top‑level entries without losing context.
- Minimal materialization keeps the UI fast and uncluttered while still precise to the user’s selection.

---

**End of TRD**

