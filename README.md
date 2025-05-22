# Context Collector

**Context Collector** is a lightweight Flutter‑desktop application that lets you drag‑and‑drop any mix of source‑code,
config, or text files and instantly generate a clean, concatenated text bundle—perfect for pasting into ChatGPT or
committing as project context.

------

## ✨ Key features

|                         |                                                                                                         |
|-------------------------|---------------------------------------------------------------------------------------------------------|
| 🖱️ **Drag‑and‑drop**   | Drop individual files *or* whole folders; nested directories are scanned recursively.                   |
| 📂 **300+ file‑types**  | Recognises every common programming, markup, and config extension—from `.dart`to `.yaml` to `.sql`.     |
| 📝 **Reference header** | Each file is prefixed with a comment block (`// File: …`, size, modified date) so LLMs know the source. |
| 🧩 **Live preview**     | Read‑only pane shows the combined output with monospace styling and smooth scrolling.                   |
| 📋 **One‑click copy**   | Copy the entire bundle to your clipboard or save it as a single `.txt`.                                 |
| 🎨 **Modern UI**        | Material 3, dark‑mode aware, themed with custom colors and subtle animations.                           |
| 🪟 **Cross‑platform**   | Compiles to native Windows, macOS, and Linux executables (*web build consciously skipped*).             |

------

## 🚀 Getting started

### Prerequisites

- Flutter ≥ 3.16 with desktop support enabled (`flutter config --enable-macos-desktop` etc.)
- Dart 3.x SDK (bundled with Flutter)

\### Clone & run

```bash
git clone https://github.com/your‑org/context_collector.git
cd context_collector
flutter pub get
flutter run  # chooses your current desktop platform automatically
```

\### Build a production bundle

```bash
# macOS (Universal)
flutter build macos

# Windows (x64)
flutter build windows --release

# Linux (deb package)
flutter build linux --release
```

The binaries are placed under `build/<platform>/` and can be zipped or notarised as usual.

------

## 🖼️ Screenshots

| Home / empty state                                     | After dropping files                                     |
|--------------------------------------------------------|----------------------------------------------------------|
| ![Empty‑state screenshot](docs/images/empty_state.png) | ![Loaded‑state screenshot](docs/images/loaded_state.png) |

> *Tip:* record an 8‑second GIF with `gifox` or `peek` and drop it into `docs/images`—GitHub renders it inline.

------

## 🔍 Under the hood

- **State management:** `provider` (simple `ChangeNotifier`).
- **File & directory picking:** `desktop_drop` + `file_selector`.
- **Theming:** custom `AppTheme` with M3 `ColorScheme` + smooth animations.
- **No SQL/Prefs:** everything is kept in memory; nothing touches disk unless you explicitly press **Save**.

The architecture is deliberately thin—`lib/providers/file_collector_provider.dart` does all the heavy lifting, while
widgets under `lib/widgets/` stay dumb and composable.

------

## 🛠️ Configuration & extension

| What                                 | How                                                                                                  |
|--------------------------------------|------------------------------------------------------------------------------------------------------|
| **Add/remove recognised extensions** | Edit `lib/config/file_extensions.dart`; each entry maps *extension → human category icon*.           |
| **Change reference header style**    | Tweak `FileItem.generateReference()` if you prefer Markdown comments (`<!-- … -->`) instead of `//`. |
| **Disable directory recursion**      | Flip the `recursive` flag in `FileCollectorProvider.addDirectory()`.                                 |

------

## 🗺️ Roadmap

- Toggle *include hidden files*
- Search & filter inside the preview pane
- Syntax‑highlight each file block
- Unit tests for the provider layer

Contributions & feature requests are welcome—just open an issue!

------

## 🤝 Contributing

1. Fork the repo and create your feature branch (`git checkout -b feature/amazing-thing`).
2. Commit your changes with conventional commits.
3. Push to the branch (`git push origin feature/amazing-thing`).
4. Open a Pull Request describing what you changed and *why*.

For larger ideas, please start with a discussion thread first so we can agree on scope.

------

## 📄 License

Licensed under the **MIT License**—see [`LICENSE`](LICENSE) for details.

------

## 🙌 Acknowledgements
- UI icons from [Material Icons](https://fonts.google.com/icons).
- Built with <3 by [Your Name](https://github.com/your‑username).

------

Made with 🍵 & Flutter 3.21—happy context‑collecting! 🥳
