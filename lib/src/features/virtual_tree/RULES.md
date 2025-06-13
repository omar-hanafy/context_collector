# Virtual Tree Behavior Rules & Specifications

## Core Principles

### 1. **User Choice First**
- The user should have control over how their files are organized
- When ambiguity exists, ask the user what they want
- Provide sensible defaults but allow overrides

### 2. **Flexible Organization**
- Files can exist multiple times if the user chooses (virtual duplicates)
- The tree represents the user's mental model, not the file system
- Support both automatic organization and manual adjustments

### 3. **Clear Visual Feedback**
- Always show what will happen before it happens
- Distinguish between different file states (original, duplicate, virtual)
- Make the tree structure predictable and understandable

## Drop Behavior Rules

### Rule 1: First Drop of Any Item
**Scenario**: User drops files/folders for the first time
**Behavior**: 
- Add immediately without asking
- Create minimal necessary structure
- Auto-select new items

### Rule 2: Dropping Same Directory Again
**Scenario**: User drops `/home/project/` when it already exists in tree
**Behavior**:
- **ALWAYS** show dialog with options:
  1. **Merge Smart** (default)
     - Only add files that don't exist
     - Use existing folder structure
     - Don't create duplicates
  2. **Replace Entire Directory**
     - Remove ALL files from this source directory
     - Add fresh copy of everything
     - Useful when files have changed
  3. **Add as Duplicate**
     - Create new virtual folder with suffix (e.g., "project (2)")
     - Keep all existing files
     - Add all new files under duplicate folder

### Rule 3: Dropping Subset of Existing Directory
**Scenario**: User drops `/home/project/src/file.js` when `/home/project/` already exists
**Behavior**:
- Check if file already exists at that path
- If exists: Show dialog
  1. **Skip** (default) - Don't add duplicate
  2. **Replace** - Update the existing file
  3. **Add as Copy** - Add with suffix (e.g., "file (2).js")
- If doesn't exist: Add to existing structure

### Rule 4: Dropping Different Files from Same Directory
**Scenario**: First drop `/project/file1.js`, then drop `/project/file2.js`
**Behavior**:
- Recognize they share a parent
- Add `file2.js` to existing `/project/` folder
- Don't create duplicate folder structures

### Rule 5: Mixed Source Drops
**Scenario**: Drop multiple items from different locations at once
**Behavior**:
- Process each source location independently
- Apply above rules for each source
- Show combined dialog if multiple conflicts

## Tree Organization Rules

### Structure Rule 1: Minimal Necessary Folders
**Principle**: Only create folders that add meaning
**Example**:
```
❌ Bad:  /home/user/projects/myapp/src/index.js
✅ Good: myapp/src/index.js
```

### Structure Rule 2: Preserve Relative Paths
**Principle**: Keep relative structure within a source
**Example**:
Drop: `/projects/app/src/components/Button.js` and `/projects/app/src/utils/helpers.js`
Result:
```
app/
├── src/
    ├── components/
    │   └── Button.js
    └── utils/
        └── helpers.js
```

### Structure Rule 3: Smart Root Naming
**Principle**: Use meaningful root folder names
- If dropping a project folder, use the project name
- If dropping mixed files, group by common parent
- If no common parent, create "Mixed Sources" root

## Duplicate Handling Specifications

### Duplicate Detection
**What constitutes a duplicate?**
1. **Exact Path Match**: Same source path already in scan history (not just in current files)
2. **Content Match**: Different path but identical content (future feature)

### User Decision Points
**When to ask the user:**
1. Dropping exact same directory path that was previously scanned
2. Dropping file that exists in structure
3. Dropping subset that creates conflicts

**When NOT to ask:**
1. First scan operation (empty scan history)
2. Dropping completely new files
3. Dropping to different virtual locations
4. Dropping a file then its parent directory (no longer shows false duplicate)

### Duplicate Resolution Options

#### For Directories:
1. **Merge Smart**
   - Compare file lists
   - Add only new files
   - Skip existing files
   - Preserve tree structure

2. **Replace All**
   - Remove all files from this source
   - Add fresh copies
   - Preserve virtual edits in other files

3. **Keep Both**
   - Rename folder with suffix
   - Keep all existing
   - Add all new under renamed folder

#### For Individual Files:
1. **Skip** - Don't add
2. **Replace** - Update existing
3. **Rename** - Add with suffix

## Virtual Files & Folders

### Creating Virtual Items
**Allowed Operations:**
- Create new file in any folder
- Create new folder anywhere
- Create at root level
- Edit content of any file (virtual or real)

**Naming Rules:**
- Virtual files start with default names (untitled-1.md)
- Auto-increment if name exists
- User can rename immediately
- Name validation prevents duplicates and invalid characters

### Virtual Item Behavior
- Treated exactly like real files in selection
- Can be edited, moved, deleted
- Shown with special indicator (✨)
- Included in export/copy operations
- Virtual file paths reflect their position in the tree hierarchy

### Implementation Details
- Virtual files are created directly in their parent folder without rebuilding the entire tree
- File creation uses dedicated `addVirtualFileNode` API to maintain proper state synchronization
- Virtual paths are built from the parent node's virtual path, not filesystem paths
- Checkboxes work immediately upon creation due to proper fileId linking

## Selection Behavior

### File Selection
- Clicking file toggles selection
- Multiple selection supported
- Selection persists across tree operations

### Folder Selection
- Checkbox shows three states:
  - ☐ None selected
  - ☑ All selected  
  - ⊟ Partial selected
- Clicking checkbox:
  - From none/partial → Select all
  - From all → Deselect all

### Selection Sync
- Tree selection immediately updates editor content
- Deselecting file removes it from combined output
- Selection state persists through refreshes

## Edge Cases & Decisions

### Case 1: Circular References
**Scenario**: Symlinks causing circular refs
**Decision**: Skip with warning, don't follow symlinks

### Case 2: Very Large Directories
**Scenario**: Dropping folder with 10,000+ files
**Decision**: Show progress, allow cancellation, add in batches

### Case 3: Binary Files
**Scenario**: Dropping images, executables
**Decision**: Add to tree but mark as binary, don't load content

### Case 4: Permission Errors
**Scenario**: Can't read file due to permissions
**Decision**: Add to tree with error indicator, show in tooltip

### Case 5: Multiple Duplicates
**Scenario**: file.js, file (2).js already exist, dropping file.js again
**Decision**: Increment to next available: file (3).js

## State Management Rules

### What Persists
- Tree structure
- Selection state  
- Virtual file content
- Expansion state

### What Resets
- On "Clear All": Everything
- On "Remove": Just that node and children
- On "Replace": Only affected files

### Undo/Redo (Future)
- Track operations for undo
- Granular undo per operation
- Clear undo stack on major operations

## UI/UX Standards

### Feedback Timing
- Immediate: Selection, expansion
- Async with progress: Large operations
- Debounced: Content building (300ms)

### Error Handling
- Show inline for file errors
- Toast for operation errors
- Dialog for critical decisions

### Visual Hierarchy
- Root folders: Bold
- Virtual items: Special icon
- Errors: Red indicator
- Modified: Orange indicator

## Performance Considerations

### Lazy Loading
- Load file content on demand
- Virtualize tree rendering for large lists
- Batch operations when possible

### Memory Management
- Cap in-memory content (100MB default)
- Offer to exclude large files
- Stream large file operations

## Summary of Key Decisions

1. **Duplicates ARE allowed** if user chooses
2. **Always ask** when dropping same source again (based on scan history, not file content)
3. **Smart merge** is the default option
4. **Preserve user organization** over file system structure
5. **Virtual files** are first-class citizens
6. **Selection drives content** in real-time
7. **Visual feedback** before any destructive operation

## Technical Implementation Notes

### State Synchronization (CRITICAL)
- **FileListNotifier is the SINGLE SOURCE OF TRUTH** for all file data and scan history
- TreeStateNotifier manages ONLY UI state (expansion, visual representation)
- All operations that modify files MUST go through FileListNotifier:
  - File creation: UI → FileListNotifier → TreeStateNotifier
  - File removal: UI → FileListNotifier.removeNodes() → Tree rebuild
  - Folder creation: UI → FileListNotifier → VirtualTreeAPI
- Tree is ALWAYS rebuilt from FileListNotifier's state
- This architecture prevents state synchronization bugs
- **IMPORTANT**: TreeStateNotifier.removeNode() method has been removed to enforce this pattern

### Virtual File Creation Flow
1. User creates file in tree UI
2. FileListNotifier creates ScannedFile with proper virtual path from parent
3. FileListNotifier calls `addVirtualFileNode` to add the node to the tree
4. Tree node is created with correct fileId linking
5. Selection callback triggers content rebuild

### Removal Operations (Bug Fix)
- **CRITICAL**: All removals MUST use FileListNotifier.removeNodes()
- This method:
  1. Recursively collects all descendant file IDs
  2. Removes files from the master file map
  3. **Cleans scanHistory** to remove orphaned source paths
  4. Rebuilds the entire tree from clean state
- This prevents the "remove and re-add shows duplicate dialog" bug
- Direct tree node removal is FORBIDDEN - TreeStateNotifier no longer has removeNode() method

### Edge Case Handling
- Name conflicts: Validated before showing content editor
- Large files: Warning dialog for files over 2MB
- Invalid characters: Prevented via form validation
- Double-click prevention: Save button disabled while saving

### Avoiding False Duplicate Detection (CRITICAL)

The scan history is fundamental to duplicate detection. If not properly maintained, it can lead to false positives where the app incorrectly identifies new additions as duplicates.

#### Common Causes of False Duplicates:
1. **Incomplete History Cleanup**: When files are removed but their source paths remain in scan history
2. **Replace Operations**: Using "Replace All" without cleaning the scan history
3. **Partial Removals**: Removing some files from a directory but not updating the scan metadata

#### Key Implementation Requirements:
1. **Always Clean Scan History**: Any operation that removes files MUST also clean the scan history
2. **Use Helper Methods**: The `_removePathsFromScanHistory()` helper ensures consistent cleanup
3. **Replace Operations**: The `_applyReplaceAllAction()` MUST clean scan history before updating state

#### Code Pattern for Safe Removal:
```dart
// WRONG - Creates false duplicates
state = state.copyWith(
  fileMap: newFileMap,
  selectedFileIds: newSelection,
  // scanHistory not updated - BUG!
);

// CORRECT - Prevents false duplicates
final newScanHistory = _removePathsFromScanHistory(pathsToRemove);
state = state.copyWith(
  fileMap: newFileMap,
  selectedFileIds: newSelection,
  scanHistory: newScanHistory, // Clean history
);
```

#### Testing for Regressions:
1. Add a directory
2. Choose "Replace All" when re-adding
3. Clear all files
4. Add the same directory again
5. Should NOT show duplicate dialog (if it does, scan history isn't being cleaned)

### Recent Architecture Improvements (Post-Cleanup)
- **SelectionState.allFiles removed**: fileMap is now the single source of truth, eliminating redundancy
- **Display logic consolidated**: All file display logic moved to FileDisplayHelper for consistency
- **Extension catalog unified**: FileDisplayHelper.extensionCatalog is the single source for file type definitions
- **File conflict handling refactored**: Split into smaller, focused methods for better maintainability
- **Debug statements removed**: Production-ready code without debug prints
- **Scan history cleanup fixed**: Prevents false duplicate detection after replace operations

These rules prioritize user control and flexibility while providing smart defaults. The tree is a workspace, not just a file viewer.
