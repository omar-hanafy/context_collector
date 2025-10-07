## Shipping Pandoc with your Flutter desktop app

**Windows**

* Grab the official ZIP (“portable”) from Pandoc releases, add `pandoc.exe` to your app’s install folder (e.g. `YourApp\bin\pandoc\pandoc.exe`), and invoke it with `Process.run`. The project explicitly ships Windows ZIP builds suitable for bundling. ([Pandoc][1])

**macOS**

* Put the `pandoc` binary inside your `.app` bundle (e.g. `YourApp.app/Contents/MacOS/pandoc` or `Contents/Resources/bin/pandoc`).
* Make sure it’s executable and **codesigned as nested/bundled code** when you sign the app; otherwise Gatekeeper can block it. (Apple’s docs: nested “bundled code” must be signed as part of the app.) ([Apple Developer][2])

**Dart path helper (Win + mac)**
Put the binary next to your app executable and call it like this:

```dart
import 'dart:io';
import 'package:path/path.dart' as p;

String pandocPath() {
  final exeDir = File(Platform.resolvedExecutable).parent;
  if (Platform.isMacOS) return p.join(exeDir.path, 'pandoc');           // Contents/MacOS/pandoc
  if (Platform.isWindows) return p.join(exeDir.path, 'pandoc', 'pandoc.exe');
  throw UnsupportedError('Only Windows/macOS supported here');
}

Future<void> docxToMd(String inPath, String outPath) async {
  final mediaDir = p.join(p.dirname(outPath), '${p.basenameWithoutExtension(outPath)}_media');
  final r = await Process.run(pandocPath(), [
    '-f','docx','-t','gfm',                   // GitHub-flavored Markdown
    '--extract-media=$mediaDir',              // saves embedded images
    inPath, '-o', outPath
  ]);
  if (r.exitCode != 0) throw Exception(r.stderr);
}
```

Pandoc’s `--extract-media` option pulls images out of DOCX/ODT and rewrites links in the Markdown. ([Pandoc][3])

---

## “How many formats can I convert **to Markdown**?”

Short answer: **dozens**. Practically, if Pandoc can read it, you can `-t gfm`/`-t markdown` it.

Key **non-plain-text** inputs you’ll likely care about:

* **DOCX** (Microsoft Word) → MD
* **ODT** (OpenDocument Text) → MD
* **RTF** → MD
* **EPUB** / **FB2** (e-book containers) → MD
* Plus lots of markup/texty formats (HTML, LaTeX, Org, reST, MediaWiki, JATS/DocBook XML, etc.).
  See Pandoc’s official input formats list (docx/odt/rtf/epub/fb2/ipynb/typst and many more). ([GitHub][4])

Looking at the nature of my app I only need to convert non-plain-text formats just to expand the supported ones.

You can programmatically check what your **shipped** binary supports:

```dart
final formats = await Process.run(pandocPath(), ['--list-input-formats']);
print(formats.stdout);
```

(Those `--list-*` flags are built in.) ([Pandoc][3])

**Notable exceptions**

* **PDF**: Pandoc **can’t** read PDFs (convert in Word/Google Docs first, or use a PDF-to-text/HTML tool, then feed that to Pandoc). ([Pandoc][5])
* **PPTX**: Pandoc writes PPTX but doesn’t read it as input. ([GitHub][6])

[1]: https://pandoc.org/installing.html "Installing pandoc"
[2]: https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac "Creating distribution-signed code for macOS"
[3]: https://pandoc.org/MANUAL.html "Pandoc - Pandoc User’s Guide"
[4]: https://github.com/jgm/pandoc "GitHub - jgm/pandoc: Universal markup converter"
[5]: https://pandoc.org/faqs.html "FAQs"
[6]: https://github.com/jgm/pandoc/issues/4252 "PowerPoint reader support? · Issue #4252 · jgm/pandoc"
---
the apove article is just demonstration of possibility, when I am going to use this in the app I have to expand those
examples and implementation to fit the apps needs and structure.
