- Fix auto update issue.
- adding a new file clears custom text added.
- support for tree view.
- support for custom text item in tree view.
- support paste path or list of paths.
- support paste content (this should be easily available added after the custom text item feature).
- extract text from docx, pdf, excel. 
- support for urls. (github, google docs, etc.)
- support for images (OCR).
- save sessions and reload them (handle not found files and other edge cases).

---
Hints Section:

```yaml
dependencies:
  # Document processing
  archive: ^1.0.1 # to uncompress docx file.
  xml: ^6.0.1 # to parse xml files in docx to md.

  # Excel handling
  excel: ^4.0.6 # to convert excel files to md

  # PDF handling
  syncfusion_flutter_pdf: ^0.3.1 # to extract text from pdf files.

  # OCR
  google_mlkit_text_recognition: ^0.15.0 # tried to extract text from images or complex pdfs.
```

# ContextCollector 2.0 - Final Requirements Document

## 🎯 Core Philosophy

**Primary Purpose**: Collect files and notes → Format nicely → Copy to AI

**NOT**: A full-featured code editor or IDE
 **IS**: A smart scratch pad with file organization

## 📋 Primary Workflow (MUST BE PERFECT)

```
Open app → Drag project files → Create/add notes → Copy formatted content → Paste to AI
```

## 🏗️ Architecture Overview

### 1. **Tree-Based File Organization**

- Use `file_tree_view` package for file/folder display
- Virtual root system for mixed-location files
- In-place file/folder creation
- No separate "Notes" directory - custom files live naturally in the tree

### 2. **Tabbed Workspace**

- Multiple context collections via tabs
- Lightweight persistence using Hive
- Session restoration on app restart
- Each tab = independent collection task

### 3. **Smart Content Management**

- In-memory file editing (no disk writes)
- Dirty state tracking
- Monaco editor integration for viewing combined output
- Popup editor for individual files

## 📑 Detailed Requirements

### Feature 1: Tree View Management

#### Scenarios:

1. **Single Directory Drop**

   - User drags `/project/src`
   - Shows exact folder structure
   - Can create files at any level

2. **Mixed Location Handling**

   ```
   Initial: User drags /home/user/projectA/src/
   projectA/
   └── src/
       └── index.js
   
   Then: User drags /home/user/projectB/lib/
   Virtual Root/
   ├── projectA/
   │   └── src/
   └── projectB/
       └── lib/
   ```

3. **Smart Path Reconciliation**

   - If new drop contains existing paths, merge intelligently
   - Example: Dropping `/home/user/` when `/home/user/projectA` exists

   ```
   Before:
   projectA/
   
   After:
   home/user/
   └── projectA/
   ```

#### Edge Cases:

- Circular symlinks → Skip with warning
- Binary files → Reject with message
- Files > 10MB → Warning but allow
- Non-existent paths → Show error indicator

### Feature 2: File Operations

#### Scenarios:

1. **Create Custom File**
   - Right-click in tree → "New File"
   - Default name: `untitled-1.md`
   - Can create anywhere in tree
   - Stored in memory with special indicator (✨)
2. **Edit File**
   - Double-click → Opens popup editor
   - Changes tracked in memory only
   - File marked as dirty (📝)
   - Original disk content preserved
3. **Delete/Remove**
   - Dirty files → Confirmation dialog
   - Custom files → Simple removal
   - Disk files → Remove from collection only
4. **Refresh**
   - Single file: Reload from disk (loses edits with warning)
   - All files: Batch refresh with progress

#### Status Indicators:

- 📝 Edited (dirty)
- ❌ Not found on disk
- ✨ Custom (created in-app)
- 📄 Normal file

### Feature 3: Input Methods

#### Scenarios:

1. **Drag & Drop**

   - Files/folders from explorer
   - Multiple items at once
   - VS Code file drops supported

2. **Paste Paths**

   ```
   /path/to/file1.js
   /path/to/file2.ts
   C:\Users\project\src
   ```

   - Parse line by line
   - Add to current tree
   - Invalid paths → Show errors

3. **Paste Content**

   - Detect raw code/text paste
   - Create file at selected location
   - Default: `/pasted-{timestamp}.txt`
   - Can rename immediately

### Feature 4: Tab System

#### Scenarios:

1. **Tab Management**

   - "+" button for new tab
   - Tab names: "Collection 1", "Collection 2", etc.
   - Can rename tabs
   - Close with dirty files → Warning

2. **Persistence**

   ```json
   {
     "tabs": [{
       "id": "tab-1",
       "name": "Feature X Context",
       "paths": ["/project/src", "/docs/api.md"],
       "customFiles": {
         "Virtual Root/notes.md": "content here"
       },
       "dirtyFiles": {
         "/project/src/index.js": "edited content"
       }
     }]
   }
   ```

3. **Restoration**

   - On app start: Restore all tabs
   - Missing files: Show with ❌ indicator
   - Custom files: Fully restored
   - Dirty edits: Restored with 📝 indicator

### Feature 5: Content Assembly

#### Scenarios:

1. **Combined Output Format**

   ~~~markdown
   # Context Collection
   
   ## notes.md
   > **Path:** Virtual Root/notes.md
   
   ```md
   [content]
   ~~~

   ## index.js

   > **Path:** /project/src/index.js

   ```javascript
   [content]
   ```

   ```
   
   ```

2. **Copy Operations**

   - Button in toolbar
   - Keyboard shortcut (Ctrl/Cmd+C)
   - Include all selected files
   - Respect tree order

### Feature 6: Editor Integration

#### Scenarios:

1. **Monaco (Right Panel)**
   - Always visible
   - Shows combined content
   - Read-only by default
   - Syntax highlighting
2. **Popup Editor**
   - For individual file editing
   - Modal dialog
   - Save/Cancel buttons
   - If Monaco is simple to reuse → Use it
   - Otherwise → Use re_editor package

## 🚫 Out of Scope

- Writing changes to disk
- File system operations (move, rename on disk)
- Git integration
- Multi-user collaboration
- Cloud sync
- Advanced search/replace
- File diffing
- Terminal integration
- Plugin system

## ✅ Test Cases

### Basic Flow

1. Open app → Empty state with welcome message
2. Drag folder → Tree appears with structure
3. Right-click → Create `prompt.md`
4. Type content → Auto-saved in memory
5. Click copy → Formatted content in clipboard

### Mixed Paths

1. Drag `/projectA/src`
2. Drag `/projectB/lib`
3. Verify virtual root created
4. Create file at root level
5. Copy → Verify all paths correct

### Tab Persistence

1. Create 2 tabs with different content
2. Add custom files to each
3. Edit some disk files
4. Close app
5. Reopen → Verify everything restored

### Error Handling

1. Add file, then delete from disk → Shows ❌
2. Drop binary file → Shows rejection message
3. Paste invalid paths → Shows error list
4. Close tab with dirty files → Shows warning

### Performance

1. Drop folder with 1000 files → Shows progress
2. Copy 100 files → Completes in < 2 seconds
3. Switch between tabs → Instant
4. Create 10 custom files → No lag

------

**Remember**: Every feature should make the primary workflow smoother without adding complexity. When in doubt, choose the simpler implementation.

---

## 🏛️ High-Level Architecture & Strategy

Your core philosophy is perfect: a "smart scratch pad." We'll design the architecture around this principle, ensuring that every decision serves the primary workflow.

* **State Management**: We will continue to use **Riverpod**, as it's already in the project and is perfectly suited for managing the increased complexity of tabs and tree state. The new state model will be hierarchical:
    * `WorkspaceState` (the entire app session)
        * `List<TabState>` (a list of all open tabs)
            * `FileTree` (the virtual file tree for a single tab)
                * `TreeNode` (wraps a file, its status, and children)
* **Persistence**: We will use the **Hive** package as specified. It's a fast, native Dart database ideal for storing the session state (`WorkspaceState`) as a single object. A simple `HiveService` will manage serialization and deserialization.
* **Core Packages**:
    * `file_tree_view`: For the primary file visualization.
    * `hive` / `hive_flutter`: For session persistence.
    * `re_editor`: As a pragmatic choice for the initial popup editor to accelerate Phase 1. We can evaluate upgrading it to a reusable Monaco instance in the polish phase.
    * `flutter_riverpod`: To manage all application state.

---

## 📁 Recommended Folder Structure

This structure organizes the new features logically and builds upon your existing `features` directory.

```
lib/
├── main.dart
└── src/
    ├── core/                  # App-wide services (not feature-specific)
    │   ├── persistence/
    │   │   └── hive_service.dart
    │   └── utils/
    │       └── path_reconciler.dart # Logic for merging file paths
    │
    ├── features/
    │   ├── tabs/                # NEW: Manages the tabbed workspace
    │   │   ├── domain/
    │   │   │   ├── tab_state.dart
    │   │   │   └── workspace_state.dart
    │   │   ├── application/
    │   │   │   └── tabs_notifier.dart   # Riverpod notifier for workspace
    │   │   └── presentation/
    │   │       ├── widgets/
    │   │       │   ├── app_tab_bar.dart
    │   │       │   └── tab_view_layout.dart
    │   │       └── home_screen.dart     # The main screen hosting the tabs
    │   │
    │   ├── file_tree/           # NEW: Replaces 'scan' for tree logic
    │   │   ├── domain/
    │   │   │   ├── file_node.dart       # Represents a single file/folder
    │   │   │   └── file_status.dart     # Enum for ✨, 📝, ❌
    │   │   ├── application/
    │   │   │   ├── file_tree_builder.dart # Builds the virtual tree from paths
    │   │   │   └── file_tree_notifier.dart # Manages state for one tree
    │   │   └── presentation/
    │   │       ├── file_tree_widget.dart
    │   │       └── widgets/
    │   │           └── file_context_menu.dart
    │   │
    │   ├── editor/              # Existing editor logic, with additions
    │   │   ├── ... (keep existing bridge, domain, services)
    │   │   └── presentation/
    │   │       ├── ... (keep existing ui)
    │   │       └── popup/
    │   │           └── file_editor_popup.dart # New popup editor UI
    │   │
    │   └── settings/            # Existing settings logic
    │       └── ...
    │
    └── shared/                  # Existing shared widgets and utils
        └── ...
```

---
