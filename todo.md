- Fix auto update issue.
- adding a new file clears custom text added.
- support for tree view.
- support for custom text item in tree view.
- support paste path or list of paths.
- support paste content (this should be easily available added after the custom text item feature).
- extract text from docx, pdf, excel. 
- support for urls. (github, google docs, etc.)
- support for images (OCR).

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
