Of course. Here is the General Implementation Plan for ContextCollector 2.0.

This document serves as the high-level roadmap and architectural blueprint for the entire team. It outlines our core
strategy, technical architecture, and development phases to ensure we are all aligned as we build the next version of
the application.

---

## 🚀 ContextCollector 2.0: General Implementation Plan

### 1. Project Vision & Guiding Principles

Our goal is to build the ultimate developer scratchpad for AI interactions. Every decision we make should serve the core
workflow: **Aggregate Context → Organize & Refine → Copy Formatted Output**.

To achieve this, we will adhere to the following principles:

* **Modularity Over Monolith:** Features will be broken down into discrete, testable services. The `Workspace` (data and
  state) will be independent of the `Editor` (presentation).
* **State-Driven UI:** We will use Riverpod to its full potential. The UI will be a direct reflection of the application
  state. We don't "tell" the UI to change; we change the state, and the UI reacts.
* **Single Source of Truth:** **Hive** will be our one and only persistence layer. All session data, user settings, and
  tab information will be stored in Hive boxes. This prevents state conflicts and simplifies data management.
* **Pragmatic & Focused:** We will strictly follow the requirements document, prioritizing the core workflow above all
  else. Features not in the scope will be deferred to future versions.

### 2. High-Level Architecture

We will rebuild the application from the ground up using a clean, feature-driven folder structure and a
services-oriented architecture.

#### **Proposed Folder Structure**

```plaintext
lib/
├── core/                  # App-wide, foundational code
│   ├── persistence/
│   └── models/
├── features/              # Individual feature domains
│   ├── workspace/         # Manages tabs, file tree, and state (Dev A)
│   ├── editor/            # Manages Monaco and content display (Dev B)
│   └── app/               # Main app shell and screen layout (Team Lead)
├── shared/                # Widgets, utils, and themes used across features
└── main.dart              # Application entry point
```

#### **Core Services & Data Models**

* **`HiveService` (`lib/core/persistence`)**: A simple wrapper around Hive responsible for initializing boxes and
  providing a clean API (`read`, `write`) for repositories.
* **`VirtualNode` Models (`lib/core/models`)**: These are the atoms of our application.
    * `VirtualFile`: Represents any file, whether from disk, pasted, or created in-app. It holds its path, status (
      `isDirty`, `isCustom`), and content (`originalContent`, `editedContent`).
    * `VirtualDirectory`: A container for other `VirtualNode`s, forming the tree structure.
* **`WorkspaceService` (`lib/features/workspace/service`)**: The **brain** of the application.
    * Manages the list of open tabs (`TabState`).
    * Holds the VFS tree for the currently active tab.
    * Contains all business logic for adding, removing, and modifying nodes in the tree.
    * Orchestrates persistence by communicating with `WorkspaceRepository`.
* **`EditorService` (`lib/features/editor/service`)**: The liaison to the Monaco editor.
    * Manages the lifecycle of Monaco instances (both the main view and popups).
    * Provides a simple Dart API to interact with the JavaScript world of the editor (e.g., `setContent`,
      `formatDocument`).
* **`ContentAssembler` (`lib/features/editor/service`)**: A pure, stateless utility.
    * Its only job is to take a list of selected `VirtualFile`s and produce the final, perfectly formatted Markdown
      string for the output view and clipboard.

### 3. Phased Development Roadmap

We will build the application in three distinct phases.

#### **Phase 1: Core Workflow Foundation (Week 1)**

**Goal:** A user can drag a single folder, see its file tree, and copy the formatted content of one file.

* **Milestones:**
    * Basic Virtual File System (VFS) is functional for a single directory.
    * `file_tree_view` is implemented and displays the VFS.
    * A read-only Monaco editor can display content from a single selected file.
    * The "Copy" button works for a single file's content.

#### **Phase 2: Full Feature Implementation (Week 2)**

**Goal:** Implement the complete feature set as defined in the requirements.

* **Milestones:**
    * **Tab System:** Multi-tab management is fully functional.
    * **Persistence:** Sessions (tabs, files, edits) are saved to Hive and restored on app launch.
    * **All Input Methods:** Mixed-path drag-and-drop, path pasting, and content pasting are implemented.
    * **In-Memory Editing:** The popup editor is functional, and the "dirty" state (📝) is correctly managed and
      persisted.
    * **Content Extraction:** Support for `.docx`, `.pdf`, and `.xlsx` is added.

#### **Phase 3: Polish, Performance & Edge Cases (Week 3)**

**Goal:** Make the application robust, performant, and delightful to use.

* **Milestones:**
    * **Error Handling:** All specified edge cases (binary files, large files, symlinks, etc.) are handled gracefully.
    * **Performance:** Progress indicators are implemented for long-running operations. The UI remains responsive under
      load.
    * **Advanced Features:** URL and Image (OCR) ingestion are implemented.
    * **UI/UX Polish:** All UI elements are refined, animations are smooth, and the application feels cohesive and
      professional.
    * **Auto-Updater**: The update mechanism is tested and confirmed to be working reliably.

### 4. Team Collaboration & Workflow

* **Git Strategy:**
    * `main`: Production releases only.
    * `develop`: The primary integration branch. All feature branches merge into `develop`.
    * `feature/workspace`: Branch for Dev A's work.
    * `feature/editor`: Branch for Dev B's work.
    * `feature/shared`: Branch for the Team Lead's work on shared components.
* **Communication:** We will have a brief daily stand-up to discuss progress and blockers. Any changes to the "API"
  between services (e.g., a new method needed in `WorkspaceService`) must be communicated immediately.
* **Code Reviews:** All pull requests into the `develop` branch must be reviewed by at least one other team member. The
  Team Lead has the final approval for merging. This ensures code quality and shared knowledge of the codebase.
  Excellent. Here is the detailed, phased implementation plan specifically for the developer responsible for the *
  *Editor and Content Presentation (Dev B)**.

This plan outlines your core responsibilities, tasks for each phase, and the specific APIs you will need from and
provide to the rest of the team.

---

### 📋 Plan for Developer B: Editor & Content Presentation

Your mission is to create a flawless and intuitive editing and viewing experience. You are the owner of the Monaco
editor integration, the final formatted output, and the mechanisms for content extraction from complex file types. Your
world is primarily within `lib/features/editor/`.

#### Your Core Responsibilities:

* **Monaco Editor Integration**: Implementing and managing all Monaco editor instances (the main read-only view and the
  editing popup).
* **Content Assembly**: Building the service that takes raw file data and transforms it into the final, beautifully
  formatted Markdown output.
* **Advanced Content Extraction**: Handling the logic for parsing files like `.docx`, `.pdf`, `.xlsx`, and extracting
  text from images via OCR.

---

### Phase 1: The Monaco Core & Assembly Pipeline

**Goal:** Get a working, read-only editor on screen that can display perfectly formatted content from a test data set.
This phase focuses on building your core components in isolation.

* **Task 1: Build the `ContentAssembler` Service.**
    * Create the `ContentAssembler` class in `lib/features/editor/service/`.
    * Implement its primary method: `String assemble(List<VirtualFile> files)`.
    * **For now, create your own dummy `VirtualFile` objects for testing.** This decouples you from the Workspace team's
      progress.
    * Focus on perfecting the output format as per the requirements:
        ```markdown
        ## filename.ext
        > Path: /path/to/file.ext

        ```language
        ... file content ...
        ```
        ---
        ```
    * Use the `LanguageMapper` (provided by the Team Lead in `lib/shared/utils/`) to get the correct language identifier
      for the code block.

* **Task 2: Implement the `CombinedOutputView` Widget.**
    * Create this widget in `lib/features/editor/ui/widgets/`.
    * Integrate a **read-only** Monaco editor instance. You can refactor the existing WebView implementation for this.
    * The widget should accept a `String` of content.
    * In a parent `EditorPanel` widget, feed the output of your `ContentAssembler` (using your dummy data) into this
      view to see a live preview.

* **Task 3: Implement Core "Copy" Functionality.**
    * In the main UI (the Team Lead will provide a placeholder), add the "Copy to Clipboard" button logic.
    * On press, it should trigger your `ContentAssembler` and copy the resulting string to the system clipboard. This
      validates the entire output pipeline.

**API & Collaboration Contracts (Phase 1):**

* **You Provide:**
    * To the Team Lead: The `EditorPanel` widget, which contains your `CombinedOutputView`, ready to be placed in the
      right-hand side of the `ResizableSplitter`.
* **You Need:**
    * From Dev A (Workspace): The final class definition for `VirtualFile` so you can replace your dummy objects.
    * From Team Lead: The shared `LanguageMapper` utility.

---

### Phase 2: Integration, Interaction & Advanced Parsing

**Goal:** Connect your editor components to the live application state from Dev A, implement the file editing workflow,
and add support for complex document types.

* **Task 1: Connect to the Live Workspace.**
    * Modify your `EditorPanel` to be a `ConsumerWidget`.
    * Watch the `workspaceProvider` from Dev A to get the list of currently selected files from the active tab.
    * Whenever the selection changes, automatically re-run your `ContentAssembler` and update the `CombinedOutputView`
      with the new content.

* **Task 2: Implement the `PopupEditor`.**
    * Create a new stateful widget, `PopupEditor`, which will contain a **writable** Monaco instance.
    * Expose a method in your `EditorService` like `Future<void> showEditorFor(VirtualFile file)`. This method will be
      called by the `WorkspaceService` when a file is double-clicked.
    * The popup should display the file's content (prefer `editedContent` if it exists, otherwise `originalContent`).
    * **Implement the Save Flow:**
        * On "Save", the popup calls a method like `editorService.updateFile(file.id, newContent)`.
        * Your `EditorService` then calls the method provided by Dev A:
          `workspaceService.updateFileContent(file.id, newContent)`. This marks the file as dirty (📝) in the central
          state.
    * **Note:** You are not responsible for the disk I/O, only for updating the state via the `WorkspaceService`.

* **Task 3: Implement Advanced Content Parsers.**
    * Integrate the document processing libraries (`archive`, `xml`, `syncfusion_flutter_pdf`, `excel`) into a new or
      existing service (e.g., `FileContentExtractor`).
    * Update the file loading logic: when a file with a `.docx`, `.pdf`, or `.xlsx` extension is encountered, use the
      appropriate library to convert its content to Markdown or plain text before it's stored in the `VirtualFile`'s
      content field.

**API & Collaboration Contracts (Phase 2):**

* **You Provide:**
    * An `EditorService` with a public method `showEditorFor(VirtualFile file)` that the `WorkspaceService` can call.
* **You Need:**
    * From Dev A (Workspace):
        * A stream/notifier of the `List<VirtualFile>` that are currently selected in the active tab.
        * A method `workspaceService.updateFileContent(String fileId, String newContent)` to call when saving an edit.
        * A method `workspaceService.revertFile(String fileId)` to call for the "Refresh" action.

---

### Phase 3: Polish & Future-Forward Features

**Goal:** Refine the editor experience, implement OCR and URL ingestion, and ensure all features are robust and
polished.

* **Task 1: Implement URL and Image (OCR) Ingestion.**
    * Extend your content extraction logic.
    * For nodes identified as URLs, use an HTTP client to fetch the raw content. Work with Dev A to handle different URL
      types (e.g., raw GitHub links vs. general web pages).
    * For nodes identified as images, use the `google_ml_kit_text_recognition` package to perform OCR and populate the
      `VirtualFile`'s content with the extracted text.

* **Task 2: Polish the Editor Experience.**
    * Implement keyboard shortcuts for essential actions like "Copy Content".
    * Finalize the UI/UX of the `PopupEditor`, ensuring it has clear Save/Cancel buttons and provides a good editing
      experience.
    * Rigorously test the `LanguageMapper` integration to ensure a wide variety of code files have correct syntax
      highlighting in the final output.

* **Task 3: Performance & Error Handling.**
    * Ensure that parsing large or complex files (like a 100-page PDF) shows a loading indicator and doesn't freeze the
      UI.
    * If a parser fails (e.g., for a corrupted `.docx` or an encrypted `.pdf`), gracefully store an error message in the
      `VirtualFile`'s `error` field, which should be displayed to the user.

**API & Collaboration Contracts (Phase 3):**

* **You Need:**
    * From Dev A (Workspace): A way to identify if a `VirtualNode` is a URL or an image so your services can apply the
      correct ingestion logic.
      Excellent. Here is the detailed, phased implementation plan for the developer responsible for the **Workspace &
      State Management (Dev A)**.

This plan outlines your core responsibilities, a clear path from foundation to full features, and the specific APIs you
will provide to the rest ofthe team.

---

### 📋 Plan for Developer A: Workspace & State Management

Your mission is to be the **architect of the application's memory and logic**. You are responsible for the entire data
layer, state management, and persistence. Your world revolves around the `WorkspaceService`, the Virtual File System (
VFS) models, and the `WorkspaceRepository` that communicates with Hive.

#### Your Core Responsibilities:

* **Data Modeling**: Designing the `VirtualNode` hierarchy and the `TabState` model for persistence.
* **State Management**: Building the `WorkspaceService` (using Riverpod) as the central brain that manages all
  application state.
* **VFS Logic**: Implementing all rules for adding, removing, and merging files and directories in the virtual tree.
* **Persistence**: Creating the repository layer to reliably save and restore the entire user session using Hive.

---

### Phase 1: The Virtual File Tree Foundation

**Goal:** Establish the core data structure and get a visual, interactive file tree on screen for a single,
non-persistent tab. This phase is about building a solid foundation.

* **Task 1: Design the Core Data Models (`lib/core/models`).**
    * Create an `abstract class VirtualNode` with common properties (`id`, `name`, `parent`).
    * Implement `class VirtualDirectory extends VirtualNode` which contains a `List<VirtualNode> children`.
    * Implement `class VirtualFile extends VirtualNode` with the following fields:
        * `String originalPath` (the path on disk, can be empty for custom files)
        * `String? originalContent` (loaded from disk)
        * `String? editedContent` (in-memory changes)
        * `bool isDirty` (defaults to `false`)
        * `bool isCustom` (defaults to `false`, `true` for files made in-app)

* **Task 2: Build the Initial `WorkspaceService`.**
    * Create your service as a `StateNotifier` that manages a state object containing a `List<VirtualNode>` (the VFS
      tree). For this phase, you will manage only one tree (a single tab).
    * Implement `Future<void> addDirectory(String path)`: This method will scan the given directory path, create the
      corresponding `VirtualNode` tree structure, and update the service's state. It does *not* need to read file
      content yet.
    * Implement `void createFileInTree()`: Adds a new, empty `VirtualFile` to the tree with `isCustom: true`.
    * Implement `void removeNodeFromTree(String nodeId)`: Removes a node and its children from the VFS.

* **Task 3: Implement the `FileTreeView` Widget (`lib/features/workspace/ui/widgets`).**
    * As a `ConsumerWidget`, watch your `workspaceProvider`.
    * Use the `file_tree_view` package to render the VFS tree from the service.
    * Implement `onNodeTap` to update a `selectedNodeId` in your service's state.
    * Lay the groundwork for a right-click context menu (e.g., using `InkWell`'s `onSecondaryTap`). Implement the "New
      File" and "Remove" actions, which call the corresponding methods in your service.

**API & Collaboration Contracts (Phase 1):**

* **You Provide:**
    * To the Team Lead: The main `workspaceProvider` and the `FileTreeView` widget to be placed in the left UI panel.
    * To Dev B: The `VirtualFile` class definition, and a way for them to get a single file's state to begin testing
      their `ContentAssembler`.
* **You Need:**
    * From Team Lead: The initialized project with Riverpod and the Hive service stub.

---

### Phase 2: Full State, Persistence & Advanced Inputs

**Goal:** Evolve the service to manage multiple tabs, persist the entire session to disk using Hive, and handle all
specified input methods. This is the most intensive phase.

* **Task 1: Implement Full Tab Management.**
    * Create the `TabState` model in `lib/features/workspace/data/models/`. It should contain the VFS tree, tab name,
      ID, etc. **Annotate it for Hive (`@HiveType`, `@HiveField`).**
    * Refactor your `WorkspaceService` to manage a `List<TabState>` and an `activeTabId`.
    * Implement the public API for tab management: `addTab()`, `closeTab(tabId)`, `switchToTab(tabId)`,
      `renameTab(tabId, newName)`.

* **Task 2: Build the Persistence Layer.**
    * Create the `WorkspaceRepository` in `lib/features/workspace/data/`.
    * This repository will have two methods: `saveWorkspace(List<TabState> tabs)` and
      `Future<List<TabState>> loadWorkspace()`. It will use the `HiveService` provided by the Team Lead.
    * Integrate this into your `WorkspaceService`:
        * On initialization, call `loadWorkspace()` to restore the previous session.
        * After any significant state change (adding/removing files, switching tabs, editing content), call
          `saveWorkspace()`. Use a debouncer to avoid excessive writes.

* **Task 3: Implement Advanced Input & VFS Logic.**
    * **Mixed-Location Drops**: Modify your file-adding logic to detect when files/folders from different parent
      directories are added. When this happens, create a "Virtual Root" directory at the top of your VFS tree to contain
      them.
    * **Smart Path Reconciliation**: Implement the logic to correctly merge trees when a parent directory is dropped
      over an existing child.
    * **Paste Handling**: Implement `addFromPastedPaths(String text)` and `addFromPastedContent(String text)` in your
      `WorkspaceService`.

* **Task 4: Implement State & Status Indicators.**
    * Your `VirtualFile` model already has the necessary flags (`isDirty`, `isCustom`).
    * Expose this state through your provider.
    * In your `FileTreeView`, work with the Team Lead to render the UI icons (✨, 📝, ❌) based on the state of each node.
      The `isNotFound` status (`❌`) will be determined during session restoration if a file path no longer exists.
    * Implement the "dirty" state warnings when `closeTab` is called for a tab that contains dirty files.

**API & Collaboration Contracts (Phase 2):**

* **You Provide:**
    * A `workspaceProvider` that now exposes the full list of tabs and the active tab's state.
    * A stream/notifier of the `List<VirtualFile>` that are currently *selected* in the `FileTreeView` of the active
      tab. Dev B needs this for the `CombinedOutputView`.
    * A public method `updateFileContent(String fileId, String newContent)` for Dev B's popup editor to call on save.
    * A public method `revertFile(String fileId)` for Dev B's refresh action.

---

### Phase 3: Robustness, Performance & Advanced Ingestion

**Goal:** Make your services bulletproof by handling all edge cases and performance bottlenecks. Add support for new
content types.

* **Task 1: Implement Edge Case Handling.**
    * **Binary/Large Files:** In your file scanning/adding logic, check file sizes and types. For unsupported binaries,
      create a `VirtualFile` but set an error message in its `error` field instead of loading content. For large files,
      populate the content but perhaps also set a warning flag.
    * **Symbolic Links:** When recursively scanning directories, use `dart:io`'s `Link` class to check
      `Link.resolveSymbolicLinks()` and maintain a set of visited paths to detect and break cycles.
    * **Error Indicator (`❌`):** Ensure this is fully implemented for files that are missing on session restoration.

* **Task 2: Add Support for URL & Image Nodes.**
    * Collaborate with Dev B on a system to handle new content types. A good approach is to add a `FileType` enum to
      `VirtualFile` (e.g., `local`, `custom`, `url`, `image`).
    * When a URL or image is added (via paste or future UI), create a `VirtualFile` with the appropriate type and its
      path set to the URL or image location. You are responsible for adding the node to the tree; Dev B is responsible
      for fetching/parsing its content.

* **Task 3: Performance Optimization.**
    * For large directory drops or path pastes, update the state of the `WorkspaceService` with a progress indicator
      object (e.g., `double progress`, `String currentAction`).
    * The Team Lead will use this to display a progress bar in the UI. Ensure your file scanning and processing happen
      in isolates or are chunked to avoid freezing the UI.

**API & Collaboration Contracts (Phase 3):**

* **You Provide:**
    * A robust `VirtualFile` model that can represent any type of content and its state (including errors).
    * A progress stream/notifier that the UI can listen to during heavy operations.

Excellent. Here is the detailed, phased implementation plan for your role as the **Team Lead, Integrator, and Owner of
Shared Components**.

This plan outlines your responsibilities, which focus on building the application's foundation, creating shared services
and widgets, and weaving together the features developed by Dev A and Dev B into a cohesive, polished final product.

---

### 📋 My Plan (Team Lead): Integration, Shared Components & Final Polish

My mission is to act as the **project architect and integrator**. I will build the application shell, create the shared
services and utilities that empower the other developers, and be responsible for the final integration, quality
assurance, and release of the product.

#### My Core Responsibilities:

* **Project Scaffolding**: Setting up the project, folder structure, and Git workflow.
* **Core Services**: Implementing foundational services like persistence (`Hive`) and settings management.
* **UI Shell**: Building the main application window, tab bar, and panel layout.
* **Shared Components**: Creating reusable widgets and utilities that are used across multiple features.
* **Integration & Code Review**: Merging feature branches and ensuring all parts of the application work together
  seamlessly.
* **Release Management**: Handling the build, packaging, and auto-updater configuration.

---

### Phase 1: Building the Scaffold & Foundation

**Goal:** Create a functional application shell and all foundational components, providing a clear and stable platform
for Dev A and Dev B to begin their work.

* **Task 1: Project & Repository Setup.**
    * Initialize the new Git repository.
    * Establish the branching strategy:
        * `main`: For tagged releases only.
        * `develop`: The primary integration branch where features are merged.
        * `feature/workspace`: For Dev A.
        * `feature/editor`: For Dev B.
    * Create the complete folder structure as defined in the General Plan. This provides a clear home for everyone's
      code.

* **Task 2: Implement Core Services (`lib/core`).**
    * Implement the `HiveService`. This will involve:
        * Adding `hive` and `hive_flutter` to `pubspec.yaml`.
        * Writing an `init()` method in `main.dart` to set up Hive, register all `HiveType` adapters (which Dev A will
          create for `TabState`), and open the required boxes (`workspace`, `settings`).
        * Providing a clean, app-wide service for accessing the opened boxes.

* **Task 3: Build the UI Shell (`lib/features/app`).**
    * Create the main `HomeScreen` widget which will serve as the top-level UI.
    * Implement the main `AppBar`, including the title and placeholder action buttons.
    * Implement the `ResizableSplitter` widget (`lib/shared/widgets`) to create the two-panel layout.
    * Inside the splitter, place named `Container` placeholders for `WorkspaceView` (left) and `EditorPanel` (right).

* **Task 4: Create Shared Utilities (`lib/shared/utils`).**
    * Implement the `LanguageMapper` and `ExtensionCatalog` classes. These are critical, shared resources needed by both
      Dev A (for file filtering) and Dev B (for syntax highlighting) and should be managed centrally by you.

* **Task 5: End-of-Phase Integration.**
    * Review and merge Dev A's `feature/workspace` branch into `develop`.
    * Review and merge Dev B's `feature/editor` branch into `develop`.
    * Replace the placeholder containers in `HomeScreen` with the actual `FileTreeView` from Dev A and the `EditorPanel`
      from Dev B.
    * **Result:** A running app with a visible (but disconnected) file tree on the left and a read-only editor on the
      right.

---

### Phase 2: Weaving Features Together

**Goal:** Connect the core components, implement the tabbed interface, and build out the application's settings and
global input mechanisms.

* **Task 1: Implement the Tab Bar UI.**
    * In `WorkspaceView` (Dev A's primary panel), build the UI for the tab bar.
    * This UI will be a `ConsumerWidget` that watches Dev A's `workspaceProvider`.
    * It will display the list of tabs, highlight the active one, and provide UI controls (+) for adding a new tab.
    * Connect the UI controls to the methods on the `WorkspaceService` (`addTab`, `switchToTab`, `renameTab`,
      `closeTab`).

* **Task 2: Build the Settings Service & Screen.**
    * **Crucial Refactor:** Create a new `SettingsService` backed by your `HiveService`.
    * This service will manage loading and saving the `EditorSettings` and `ThemeMode`. This officially replaces all
      usage of `shared_preferences`.
    * Build the `SettingsScreen` UI, allowing users to modify the theme.
    * Expose the settings via a new `settingsProvider` so that Dev B's editor components can react to changes in font
      size, theme, etc.

* **Task 3: Implement Global Input Handling.**
    * Wrap the `HomeScreen` with the `DropTarget` widget.
    * In the `onDragDone` callback, you will call the methods on Dev A's `WorkspaceService` (e.g., `addFromPaths()`).
    * Implement a global key listener (e.g., `Focus` or `RawKeyboardListener`) to detect `Ctrl+V` pastes. When detected,
      you will analyze the clipboard content and call the appropriate `WorkspaceService` method (`addFromPastedPaths` or
      `addFromPastedContent`).

**API & Collaboration Contracts (Phase 2):**

* **You Provide:**
    * A fully functional `SettingsScreen` and a `settingsProvider` for app-wide configuration.
    * A UI shell that correctly routes user input (drops, pastes) to the `WorkspaceService`.
* **You Need:**
    * From Dev A: The complete API on `WorkspaceService` for managing tabs and handling all input types.
    * From Dev B: The `PopupEditor` widget, which you can help integrate into the main app overlay if needed.

---

### Phase 3: Final Polish, Shipping & Beyond

**Goal:** Finalize all UI/UX details, implement the auto-updater, and prepare the application for release.

* **Task 1: Implement the Auto-Updater UI & Logic.**
    * Build the "Updates" tab within the `SettingsScreen`.
    * Provide a "Check for Updates" button that calls the `autoUpdaterService`.
    * Listen to events from the `autoUpdaterService` to show user-facing notifications (e.g., "An update has been
      downloaded and will be installed on restart.").

* **Task 2: App-wide UI/UX Polish.**
    * Conduct a full review of the application, ensuring consistent design, padding, and behavior.
    * Add any final animations or transitions to make the app feel responsive and modern.
    * Implement the final application icons for both macOS and Windows.

* **Task 3: Quality Assurance & Final Integration.**
    * Lead the testing effort, running through all test cases outlined in the requirements document on both platforms.
    * Perform the final code reviews for all feature branches before merging into `main` for release. Resolve any final
      merge conflicts.

* **Task 4: Build & Release.**
    * Manage the release build process using `flutter build`.
    * Create the `appcast.xml` file required for the auto-updater to function. Host it on GitHub Pages as specified.
    * Create a new release on GitHub, attaching the built application installers (`.dmg` or `.zip` for macOS, `.msi` or
      `.zip` for Windows).
    * Write the release notes, celebrating the launch of ContextCollector 2.0!
