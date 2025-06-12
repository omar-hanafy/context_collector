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
1. **Exact Path Match**: Same source path already in tree
2. **Content Match**: Different path but identical content (future feature)

### User Decision Points
**When to ask the user:**
1. Dropping exact same directory
2. Dropping file that exists in structure
3. Dropping subset that creates conflicts

**When NOT to ask:**
1. First time dropping anything
2. Dropping completely new files
3. Dropping to different virtual locations

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

**Naming Rules:**
- Virtual files start with default names (untitled-1.md)
- Auto-increment if name exists
- User can rename immediately

### Virtual Item Behavior
- Treated exactly like real files in selection
- Can be edited, moved, deleted
- Shown with special indicator (✨)
- Included in export/copy operations

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
2. **Always ask** when dropping same source again
3. **Smart merge** is the default option
4. **Preserve user organization** over file system structure
5. **Virtual files** are first-class citizens
6. **Selection drives content** in real-time
7. **Visual feedback** before any destructive operation

These rules prioritize user control and flexibility while providing smart defaults. The tree is a workspace, not just a file viewer.
