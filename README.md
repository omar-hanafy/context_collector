# Context Collector

_Combine a bunch of files & folders into one neat, AI-ready text bundle._

Context Collector is a lightweight Flutter desktop app (macOS • Windows • Linux) that lets you drag-and-drop any mix of source files, logs, configs—even whole directories—then outputs a single, annotated document.  
Every chunk includes its full path and basic metadata so large-language models know exactly where things live in your codebase.

<p align="center">
  <img src="docs/screenshot_dark.png" width="70%" alt="Context Collector main window (dark theme)">
</p>

---

## ✨  Why you might care

| Problem                                                  | How Context Collector helps                                                      |
|----------------------------------------------------------|----------------------------------------------------------------------------------|
| _“ChatGPT keeps asking ‘where’s that widget defined?’”_  | Bundles related Dart/Swift/HTML/etc. files into one prompt-friendly blob.        |
| _“Sharing repro steps means pasting half a dozen logs.”_ | Drag the whole `logs` folder—binary files are skipped, text is merged & labeled. |
| _“I lose track of which files I already copied.”_        | Path headers + file-size badges keep things obvious.                             |
| _“Long prompts blow up my token budget.”_                | Quickly toggle files on/off, or collapse content before copy.                    |

---

##  Core features

* **Drag & Drop** files _or_ directories (recursive scan).
* **250+ extensions supported**, plus custom ones in _Settings → Extensions_.
* **Live Monaco Editor** preview with syntax highlighting, themes, word-wrap, and font-size controls.
* **Smart clipboard / save** – one click to copy the combined doc or save it as a `.txt`.
* **OS-native window** (built with [`window_manager`](https://pub.dev/packages/window_manager)) – resizable splitter, animations, dark/light theming.
* **Keyboard shortcuts**  
  `⌘/Ctrl  + F`  Find · `⌘/Ctrl  + Shift + P`  Command Palette · `⌘/Ctrl  + S`  Save file

---

##  Install it

**▶ Download a pre-built release**

1. Head to **Releases** on the [GitHub page](https://github.com/your-handle/context-collector/releases).
2. Grab the latest ZIP/DMG/EXE for your OS.
3. Run it – no extra setup.

**🛠️Build from source (Flutter 3.22+)**

```bash
git clone https://github.com/your-handle/context-collector.git
cd context-collector
flutter pub get
flutter config --enable-macos-desktop --enable-windows-desktop --enable-linux-desktop
flutter run  # or flutter build macos / windows / linux
```
