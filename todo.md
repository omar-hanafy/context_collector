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

Of course. Let's craft a comprehensive implementation plan to refactor `ContextCollector 2.0` from scratch, aligning with your new requirements and setting up your two developers for success on parallel tracks.

This plan establishes a clear architecture, divides responsibilities, and provides detailed notes on key changes.

***

## 🚀 ContextCollector 2.0: Refactor & Implementation Plan

This document outlines the strategy, folder structure, and task breakdown for rebuilding the Context Collector application according to the final requirements.

### Core Strategy

The refactor will pivot from the current structure to a more robust and modular architecture centered around three key concepts:

1.  **Workspace-Centric State:** The application's core state will be managed by a `WorkspaceService`, which oversees a collection of `TabState` objects. Each tab is a self-contained collection task with its own virtual file tree and state.
2.  **Virtual File System (VFS):** We will move away from a flat list of `ScannedFile`. The new system will use a hierarchical tree of `VirtualNode` objects (`VirtualFile`, `VirtualDirectory`). This makes handling mixed-path drops and in-tree file creation natural and robust.
3.  **Single Source of Truth (Hive):** All session and settings data will be persisted in Hive. This includes tab structures, dirty file content, notes, and user settings (like theme and editor preferences). **SharedPreferences will be completely removed** to avoid state fragmentation.

### 📂 Proposed Folder Structure

This structure promotes a clear separation of concerns, making it easier for your team to work in parallel.

```plaintext
lib/
├── core/
│   ├── persistence/
│   │   └── hive_service.dart     # Handles all Hive box operations (setup, read, write)
│   └── models/
│       ├── virtual_node.dart     # Abstract base class for files/folders
│       ├── virtual_file.dart     # Represents a file (from disk or in-memory)
│       └── virtual_directory.dart# Represents a folder in the VFS
│
├── features/
│   ├── workspace/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── tab_state.dart  # Model for a single tab's state (Hive-adaptable)
│   │   │   └── workspace_repository.dart # Data layer for saving/loading workspace from Hive
│   │   ├── service/
│   │   │   └── workspace_service.dart  # Manages all tabs, VFS logic, and persistence
│   │   └── ui/
│   │       ├── widgets/
│   │       │   ├── file_tree.dart        # The file_tree_view widget implementation
│   │       │   └── file_context_menu.dart # Right-click menu for the tree
│   │       └── workspace_view.dart       # The main left-panel UI (tabs + tree)
│
│   ├── editor/
│   │   ├── service/
│   │   │   ├── content_assembler.dart # Builds the final Markdown string
│   │   │   └── editor_service.dart      # Manages Monaco instances and interactions
│   │   └── ui/
│   │       ├── widgets/
│   │       │   ├── combined_output_view.dart # Read-only Monaco view for combined output
│   │       │   └── popup_editor.dart         # Monaco-based popup for editing single files
│   │       └── editor_panel.dart           # The main right-panel UI
│
│   └── app/
│       ├── app.dart                    # MaterialApp and root providers
│       └── home_screen.dart            # Main screen, stitches Workspace and Editor panels
│
├── shared/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_provider.dart       # Manages app theme (light/dark/system)
│   ├── utils/
│   │   ├── language_mapper.dart
│   │   └── path_utils.dart           # Helpers for path manipulation
│   └── widgets/
│       ├── resizable_splitter.dart
│       └── status_indicators.dart    # UI for ✨, 📝, ❌
│
└── main.dart                         # App entry point, initializes services
```

### 📝 Key Refactoring & Implementation Notes

* **State Management (Riverpod):** We will have a primary `workspaceProvider` that exposes the `WorkspaceService`. UI components will listen to this provider to get the current state of all tabs and the active tab's file tree.
* **Virtual File System:** The `VirtualNode` models are central.
    * `VirtualFile` will contain fields for `path`, `originalContent` (from disk), `editedContent`, a `isDirty` flag, and a `isCustom` flag (for files created in-app). This perfectly matches the requirements.
    * `VirtualDirectory` will contain a list of `VirtualNode` children.
    * The `WorkspaceService` will manage the logic for creating the "Virtual Root" when files from different parent directories are dropped.
* **Persistence with Hive:**
    * The `TabState` model will be designed with Hive in mind, using `@HiveType` and `@HiveField` annotations. It will store the list of root paths, custom file content, and dirty file content.
    * The `WorkspaceRepository` will be the only class that directly interacts with the Hive "workspace" box.
    * **Editor settings**, previously in SharedPreferences, will now be part of a `Settings` object also stored in a separate Hive box. This centralizes all persistence.
* **Editor Management:** The `EditorService` will manage the lifecycle of the Monaco editor instances.
    * **Main View:** The `CombinedOutputView` will be a read-only Monaco instance. It will react to changes in the active tab's selected files and re-render the formatted content from the `ContentAssembler`.
    * **Popup Editor:** When a user double-clicks a file, the `WorkspaceService` will provide the `EditorService` with the file's content. The `PopupEditor` will open with this content. On "Save," the `EditorService` will notify the `WorkspaceService` to update the `VirtualFile`'s `editedContent` and `isDirty` flag in memory. **No disk writes will occur.**

---

### 📋 Implementation Plan & Task Breakdown

Here is a phased plan, with tasks clearly assigned to each developer.

#### Phase 0: Core Setup (Both Developers)

* **Task:** Initialize the new Flutter project.
* **Task:** Set up the new folder structure.
* **Task:** Implement the `HiveService` to initialize all necessary Hive boxes on app startup (`workspace`, `settings`).
* **Task:** Create the `VirtualNode`, `VirtualFile`, and `VirtualDirectory` data models in `lib/core/models/`.
* **Task:** Set up the basic `MaterialApp`, theme provider, and a placeholder `HomeScreen` that uses the `ResizableSplitter`.

---

#### Phase 1: Core Functionality (Week 1)

**Developer A (Workspace & State)**

* **Focus:** Implement the Virtual File System and basic file management.
* **`WorkspaceService`:** Create the initial service. Implement the `addFromPath` method to handle a **single directory drop**. This involves creating the `VirtualNode` tree from the directory structure.
* **`FileTreeView`:** Use the `file_tree_view` package to display the `VirtualNode` tree from the `WorkspaceService`.
* **In-Memory Operations:** Implement the logic for creating (`New File`) and removing nodes from the tree. These operations should only affect the in-memory state within the `WorkspaceService`. Mark newly created files as "custom".
* **State:** Use a `StateNotifierProvider` to expose the `WorkspaceService`. The `FileTreeView` should rebuild when the tree changes.

**Developer B (Editor & Assembly)**

* **Focus:** Get a basic, functional editor and content assembly pipeline working.
* **`ContentAssembler`:** Create the service. Implement the `buildMerged` method as per the requirements, but initially just for a **single file**.
* **`EditorService` & `EditorPanel`:** Set up the right-hand panel. Get a basic Monaco editor instance running inside the `CombinedOutputView`. It should be **read-only** for now.
* **"Copy to Clipboard":** Implement the copy button. When clicked, it should take the content from a *hard-coded sample file*, process it through the `ContentAssembler`, and copy it to the clipboard. This tests the assembly and copy part of the workflow.

**End of Phase 1 Goal:** A user can drag a single project folder, see the file tree, and the app can format and copy the content of a single file from that tree.

---

#### Phase 2: Enhancements (Week 2)

**Developer A (Workspace & State)**

* **Focus:** Implement the full tab system, persistence, and all input methods.
* **Tab Management:**
    * Implement the full `TabState` model (`@HiveType`).
    * Enhance `WorkspaceService` to manage a list of `TabState` objects. Implement `addTab`, `removeTab`, `switchToTab`.
    * Create the `WorkspaceRepository` to save and load the entire workspace state (list of `TabState` objects) from Hive.
    * Implement session restoration on app startup.
* **Input Methods:**
    * Enhance the VFS logic to handle **mixed-location drops** (creating a Virtual Root).
    * Implement "Smart Path Reconciliation."
    * Implement the `pastePaths` and `pasteContent` features.
* **State & UI:**
    * Implement the UI for the tab bar.
    * Implement the status indicators (✨, 📝, ❌) in the `FileTreeView` based on file state.
    * Implement the "dirty" state warnings when closing a tab or removing a file with unsaved in-memory changes.

**Developer B (Editor & Assembly)**

* **Focus:** Connect the editor to the state and implement the full editing workflow.
* **Connecting Editor to State:**
    * The `CombinedOutputView` should now listen to the active tab in the `WorkspaceService`.
    * When the selection in the `FileTreeView` changes, the `ContentAssembler` should be triggered to rebuild the combined output, which is then displayed in the read-only Monaco view.
* **Popup Editor:**
    * Create the `PopupEditor` widget, using a separate Monaco instance.
    * On double-click in the `FileTreeView`, the `WorkspaceService` should notify the `EditorService` to show the popup with the file's content (either `editedContent` or `originalContent`).
    * When the user saves in the popup, the `EditorService` updates the file's `editedContent` and `isDirty` flag in the `WorkspaceService`. **No disk I/O occurs.**
* **Refresh Logic:** Implement the "Refresh" functionality. When triggered, it should discard in-memory edits (with a warning) and reload the content from disk for the selected file(s).

**End of Phase 2 Goal:** The full core workflow is functional. Users can manage multiple collections in tabs, add files from any source, see the combined output, and edit individual files in-memory. The session is saved and restored on restart.

---

#### Phase 3: Polish & Finalize (Week 3)

**Developer A (Workspace & State)**

* **Focus:** Error handling and performance.
* **Error Handling:** Implement robust handling for edge cases: binary files (reject with message), large files (>10MB warning), circular symlinks (skip with warning), non-existent paths on paste.
* **Performance:** Implement progress indicators for dropping large folders. Ensure the UI remains responsive during large operations.
* **Final Touches:** Refine the right-click context menu logic and ensure all actions are smooth.

**Developer B (Editor & Assembly)**

* **Focus:** Polishing the editor experience and UI.
* **Editor Polish:**
    * Integrate Monaco for the popup editor if it's more performant and feature-rich than the alternative (`re_editor`).
    * Implement all required keyboard shortcuts for actions like "Copy Content."
* **UI Polish:**
    * Ensure syntax highlighting is correctly mapped for all languages using `LanguageMapper`.
    * Finalize the look and feel of the `EditorPanel` and `PopupEditor`, ensuring they match the app's theme.
    * Ensure the `ContentAssembler` output format is pixel-perfect according to the requirements.

**End of Phase 3 Goal:** The application is feature-complete, robust, performant, and polished, matching all requirements laid out in the document.
Of course. Here is a comprehensive, three-part implementation plan designed for your team. Each plan details the responsibilities, phases, and collaboration points for each developer, ensuring everyone is aligned on the architecture and APIs from day one.

---

### 📋 Plan for Dev A: Workspace & State Management

Your primary responsibility is the **application's brain**. You will own the entire data model, state management, and persistence layer. Your world revolves around the `WorkspaceService`, the Virtual File System (VFS), and Hive.

#### Phase 1: The Virtual File Tree

**Focus:** Establish the core data structure and get a visual, interactive file tree on screen.

* **Models:**
    * Implement the abstract `VirtualNode` class.
    * Create `VirtualFile` with fields for `path`, `content`, `isDirty`, and `isCustom`.
    * Create `VirtualDirectory` with a `List<VirtualNode>` for its children.
* **Service (`WorkspaceService`):**
    * Create the initial service using Riverpod (`StateNotifier`). It will manage the state for a **single tab** for now.
    * Implement `addDirectory(String path)`: Scans a directory and builds a VFS tree of `VirtualNode`s.
    * Implement `createFile(String name, [VirtualDirectory parent])`: Creates a new, empty `VirtualFile` in the tree, marked as custom (✨).
    * Implement `removeNode(VirtualNode node)`: Removes a file or folder from the in-memory tree.
* **UI (`FileTreeView`):**
    * Use the `file_tree_view` package to render the VFS tree from the `WorkspaceService`.
    * Ensure the view is read-only and simply reflects the state. Clicks and interactions can be placeholders for now.

**API & Collaboration:**
* You will expose a `workspaceProvider` that Dev B and the Team Lead can watch.
* Your service will expose a stream or value of the current VFS tree (`List<VirtualNode>`).
* **For Dev B:** Provide a way to get a specific `VirtualFile` by its path to be used for testing the `ContentAssembler`.

---

### 🎨 Plan for Dev B: Editor & Content Presentation

Your primary responsibility is the **application's hands and eyes**. You will own everything the user sees and interacts with concerning code and text, including the Monaco editor integration and the final output assembly.

#### Phase 1: The Monaco Core

**Focus:** Get a working Monaco editor on screen and establish the content formatting pipeline.

* **Service (`ContentAssembler`):**
    * Implement the service that takes a `List<VirtualFile>` and builds the final, formatted Markdown string as specified in the requirements.
    * For this phase, you can create dummy `VirtualFile` objects for testing. Focus on getting the `## FileName`, `> Path: ...`, and ```language ... ``` formatting perfect.
* **UI (`CombinedOutputView`):**
    * Integrate a **read-only** Monaco editor instance.
    * Load it with a hardcoded example generated by your `ContentAssembler` to verify the output and syntax highlighting.
* **Core Action (`Copy to Clipboard`):**
    * Implement the copy functionality. A button click should trigger the `ContentAssembler` (with your dummy data) and copy the result to the clipboard.

**API & Collaboration:**
* You will create an `EditorService` that will eventually manage all Monaco instances.
* **For Dev A:** You need the `VirtualFile` model to build your `ContentAssembler`. You will consume the `isDirty` and `isCustom` flags in a later phase to show status indicators.
* **For Team Lead:** You will provide the `CombinedOutputView` widget to be placed in the right-hand panel of the main UI.

---

### 🧩 My Plan (Team Lead): Integration & Shared Components

My role is to be the **architect and integrator**. I will build the application shell, create shared utilities, and ensure that the work from Dev A and Dev B merges seamlessly at each stage.

#### Phase 1: Building the Scaffold

**Focus:** Create the application's structure and provide the sandboxes for the other developers to work in.

* **Project Setup:**
    * Initialize the new Git repository with a `main`, `develop`, and feature branches (`feature/workspace`, `feature/editor`).
    * Set up the complete folder structure as defined in the plan.
    * Configure `main.dart` and the `app.dart` to initialize core services.
* **Core Services (`lib/core`):**
    * Implement the `HiveService` and initialize it in `main.dart`. This service will provide a simple API for other services to get Hive boxes (`getWorkspaceBox()`, `getSettingsBox()`).
* **UI Shell (`lib/features/app`):**
    * Create the main `HomeScreen` widget.
    * Implement the `ResizableSplitter` to create the two-panel layout.
    * Provide placeholder `Container`s where `FileTreeView` (from Dev A) and `EditorPanel` (from Dev B) will go.
    * Build the main `AppBar`.
* **Integration:**
    * At the end of the week, I will merge `feature/workspace` and `feature/editor` into `develop`.
    * I will connect Dev A's `FileTreeView` to the left panel and Dev B's `CombinedOutputView` to the right panel.

**Key Refactoring Note for the Team:**
* **Hive is King:** I will remove **all** instances of `shared_preferences`. The `EditorSettings` and `ThemeMode` will be refactored to use a new `SettingsService` that is backed by our `HiveService`. This ensures a single, reliable source for all persisted data.

By following these parallel plans, we can ensure modular development while staying aligned on the final architecture. Regular check-ins will be key to making sure our API contracts remain solid. Let's get started!
