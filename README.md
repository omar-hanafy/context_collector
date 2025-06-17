<div align="center">

# Context Collector

</div>

<p align="center">
  <img src="https://raw.githubusercontent.com/omar-hanafy/context_collector/refs/heads/main/readme-assets/icon.png" width="150" alt="Context Collector Icon">
</p>

<p align="center">
  <!-- Badges will be added here -->
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Windows-blue" alt="Platforms: macOS, Windows">
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.0.0%20%3C4.0.0-blueviolet" alt="Dart SDK: >=3.0.0 <4.0.0">
  <img src="https://img.shields.io/badge/Flutter-blue?logo=flutter" alt="Flutter">
  <a href="https://github.com/omar-hanafy/context_collector/commits/main"><img src="https://img.shields.io/github/last-commit/omar-hanafy/context_collector" alt="Last Commit"></a>
  <a href="https://github.com/omar-hanafy/context_collector/stargazers"><img src="https://img.shields.io/github/stars/omar-hanafy/context_collector?style=social" alt="GitHub Stars"></a>
</p>

> **Combine files & folders into a clean, AI-ready text bundle — powered by Flutter and Monaco Editor.**

Context Collector is a lightweight desktop app (macOS • Windows) that lets you drag-and-drop source files, logs, configurations, or entire directories and outputs a neatly annotated document.
Every chunk includes full file paths and metadata, making it ideal for working smoothly with AIs and LLMs without the hassle of manual copying and pasting.

<p align="center">
  <img src="https://raw.githubusercontent.com/omar-hanafy/context_collector/refs/heads/main/readme-assets/home.png" width="100%" alt="Context Collector main window (dark theme)">
</p>

---

## 🖥️ Platform Support

| Platform | Status | Requirements |
|----------|--------|--------------|
| **macOS** | ✅ Fully Supported | macOS 10.13 or later |
| **Windows** | ✅ Fully Supported | Windows 10/11 with [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) |

> **Note for Windows users:** The app will prompt you to install WebView2 Runtime if it's not already installed. This is required for the Monaco editor integration.

---

## 🖥️ Typical Workflow

<p align="center">
  <img src="https://raw.githubusercontent.com/omar-hanafy/context_collector/refs/heads/main/readme-assets/editor.png" width="100%" alt="Editor view with combined content">
</p>

1. **Drag & drop** files or directories onto the drop zone.
2. **Toggle** files to include/exclude from your combined context.
3. **Review & edit** the assembled content inside the Monaco editor.
4. **Copy** your merged content instantly.

> Tip: Head to *Settings → Extensions* to exclude noisy logs or add specialized formats (`.bert`, `.fish`, etc.).
<!-- Image removed from here -->

---

## ✨ Key Features

| Capability                       | What it means for you                                                                                      |
|----------------------------------|------------------------------------------------------------------------------------------------------------|
| **Drag‑and‑drop everything**     | Drop individual files or entire directories; nested files are discovered automatically.                    |
| **250+ extensions supported**    | Built‑in support for code, logs, configs, docs, data & more — easily add your own custom extensions.       |
| **Monaco editor inside Flutter** | Enjoy syntax highlighting, multi‑cursor editing, Vim/IntelliJ/VS Code keybindings, themes, and word-wrap.  |
| **Live statistics**              | Line, character, cursor, and selection counts update in real-time—ideal for managing prompt token budgets. |
| **Quick copy**                   | Copy merged context to clipboard with one click.                                                           |
| **Extensible APIs**              | Integrate the toolkit into your Flutter apps or automate assembly using Dart scripts.                      |

<p align="center">
  <img src="https://raw.githubusercontent.com/omar-hanafy/context_collector/refs/heads/main/readme-assets/sidepanel-expanded.png" width="100%" alt="Sidepanel expanded with file details">
</p>

---

## 🚀 Getting Started

### Option 1: Pre-built app (Recommended)

1. Go to [**Releases**](https://github.com/omar-hanafy/context_collector/releases) and download the latest:
   - **macOS**: `.dmg` file
   - **Windows**: `.exe` installer
2. Install and run—zero setup required.

### Option 2: Build from source (Flutter 3.22+)

```bash
git clone https://github.com/omar-hanafy/context_collector.git
cd context_collector
flutter pub get

# Enable desktop support if not already enabled
flutter config --enable-macos-desktop --enable-windows-desktop

# Run or build
flutter run  # or flutter build macos / windows
```

---

## 🛠️ Configuration Highlights

* **Editor presets**: Beginner, Developer, Power User, Accessibility.
* **Keybinding presets**: VS Code (default), IntelliJ/WebStorm, Vim, Emacs—or load your custom JSON map.
* **Theme support**: Comes bundled with VS Light/Dark, One Dark Pro, and HC Black. Easily import additional VS Code themes.
* **Customizable extension catalog**: Quickly enable or disable formats or add custom file-to-category mappings.

<p align="center">
  <img src="https://raw.githubusercontent.com/omar-hanafy/context_collector/refs/heads/main/readme-assets/settings.png" width="100%" alt="Context Collector Settings"><br>
  <em>General application settings.</em>
</p>
<br>
<p align="center">
  <img src="https://raw.githubusercontent.com/omar-hanafy/context_collector/refs/heads/main/readme-assets/editor-settings.png" width="100%" alt="Context Collector Editor Settings"><br>
  <em>Editor specific settings and theme selection.</em>
</p>

---

## 📌 Why Context Collector?

| Problem                                                 | Context Collector's solution                                                                |
|---------------------------------------------------------|---------------------------------------------------------------------------------------------|
| *"ChatGPT keeps asking 'where's that widget defined?'"* | Bundles related Dart, Swift, HTML, etc., files into one cohesive, prompt-ready bundle.      |
| *"Sharing repro steps means pasting multiple logs."*    | Drag your entire `logs` directory; text files merge automatically and binaries are skipped. |
| *"Losing track of copied files."*                       | Path headers and file-size indicators clearly organize your context.                        |
| *"Long prompts blow up my token budget."*               | Quickly toggle files on/off or collapse content to control token usage.                     |

---

## ⚠️ Known Limitations

### Drag & Drop

| Application | Limitation | Workaround |
|-------------|------------|------------|
| **JetBrains IDEs** | Multi-file selection only drops the first file | Drop files one at a time or use finder/explorer
| **VS Code** | Dropped files show only the filename | The full content is still processed correctly |

---

## 🔮 Roadmap
* ✅ ~~Add Windows support.~~ **Done!**
* 📟 Export as file.
* 🗂️ Import from GitHub repos.
* 🌐 Add web support.
* 🤖 AI summarization of context.

Have an idea? [Open an issue](https://github.com/omar-hanafy/context_collector/issues) or join our Discord! <!-- Add Discord link if you have one -->

---

## 🤝 Contributing
Contributions are welcome!
Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

---

## ☕ Support

If you find this project helpful or valuable, please consider supporting its development:

<p align="center">
  <a href="https://www.buymeacoffee.com/omar.hanafy" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174">
  </a>
</p>

Your support helps maintain and improve Context Collector. Thank you!

---

## 📄 License

Context Collector is open-source software licensed under the **MIT License**—see [LICENSE](LICENSE).
© 2025 Omar Hanafy & community contributors.

---

## 🙏 Acknowledgements

Context Collector is built with:

*   **[Flutter](https://flutter.dev)** & **[Dart](https://dart.dev)** - The cross-platform framework powering this app
*   **[Monaco Editor](https://github.com/microsoft/monaco-editor)** - Microsoft's powerful code editor integrated via webview
*   **Open Source Community** - Special thanks to all contributors and the maintainers of our dependencies

> 📦 For a complete list of dependencies, see [`pubspec.yaml`](pubspec.yaml)

A heartfelt thank you to everyone who stars the repository, contributes code, reports issues, or offers feedback. Your support is invaluable! ❤️
