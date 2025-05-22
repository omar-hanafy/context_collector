# Context Collector - Quick Start Guide

## What I've Built for You

A complete Flutter desktop application for collecting and combining text content from multiple files. Perfect for gathering context from code files, documentation, and configuration files.

## File Structure Created

```
lib/
├── main.dart                 # App entry point with window configuration
├── models/
│   └── file_item.dart       # File data model with content loading
├── providers/
│   └── file_collector_provider.dart  # State management for files
├── screens/
│   └── home_screen.dart     # Main app screen with drag & drop
├── theme/
│   └── app_theme.dart       # Modern light/dark theme
└── widgets/
    ├── action_buttons_widget.dart     # Load, copy, save buttons
    ├── combined_content_widget.dart   # Preview of combined content
    ├── drop_zone_widget.dart         # Initial drag & drop area
    └── file_list_widget.dart         # List of added files
```

## Key Features Implemented

✅ **Drag & Drop**: Desktop native drag and drop for multiple files  
✅ **File Browser**: Manual file selection with multi-select  
✅ **Smart Detection**: Automatic text file type detection  
✅ **File Selection**: Individual checkboxes for each file  
✅ **Content Loading**: Async loading with progress indicators  
✅ **Path References**: Full file paths in combined output  
✅ **Copy to Clipboard**: One-click copying of combined content  
✅ **Save to File**: Export combined content as text file  
✅ **Real-time Preview**: Live preview of combined content  
✅ **Error Handling**: Graceful error messages and recovery  
✅ **Modern UI**: Clean, responsive Material 3 design  
✅ **Dark Mode**: Automatic light/dark theme support  

## Supported File Types

The app automatically detects and processes these text file types:
- **Code**: .dart, .py, .js, .ts, .java, .kt, .swift, .cpp, .c, .h, .cs, .php, .rb, .go, .rs, .scala
- **Web**: .html, .css, .json, .xml, .yaml, .yml
- **Data**: .csv, .log, .ini, .conf, .cfg, .properties, .env
- **Scripts**: .sh, .bat, .ps1, .sql, .md, .txt, .gitignore, .dockerfile

## How to Run

1. **Make the run script executable:**
   ```bash
   chmod +x run_app.sh
   ```

2. **Run the app:**
   ```bash
   ./run_app.sh
   ```

   Or manually:
   ```bash
   flutter pub get
   flutter run -d macos  # or windows/linux
   ```

## Usage Workflow

1. **Launch** - App opens with a drag & drop zone
2. **Add Files** - Drag files from Finder/Explorer or click "Browse Files"
3. **Select Files** - Use checkboxes to choose which files to include
4. **Load Content** - Click "Load Content" to read file contents
5. **Preview** - See combined content in the right panel
6. **Copy/Save** - Use "Copy All" for clipboard or "Save" for file

## Output Format

The combined content includes:
```
# Context Collection
Generated on: 2025-05-22T...
Total files: 3

================================================================================
// File: /path/to/file1.dart
// Size: 2.5KB
// Modified: 2025-05-22T...
================================================================================
[File content here]


================================================================================
// File: /path/to/file2.py
// Size: 1.8KB
// Modified: 2025-05-22T...
================================================================================
[File content here]
```

## Technical Details

- **Framework**: Flutter 3.0+ with Material 3
- **State Management**: Provider pattern
- **File Operations**: Native file_selector and desktop_drop
- **Window Management**: Configured for desktop with proper sizing
- **Helper Utilities**: Uses your preferred flutter_helper_utils and dart_helper_utils
- **Responsive Design**: Follows Flutter's directional properties (start/end vs left/right)

## Customization

The app follows your coding preferences:
- Uses `.addOpacity()` instead of `.withOpacity()`
- Implements logical directional properties (start/end)
- Leverages your dart_helper_utils for safe data conversion
- Uses flutter_helper_utils for enhanced UI components

Enjoy your new context collection tool! 🚀
