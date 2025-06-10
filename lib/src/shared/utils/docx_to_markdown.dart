// lib/docx_to_markdown.dart

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

///  Example usage with configuration
/// final config = DocxToMarkdownConfig.defaults.copyWith(
///   extractImages: false,
///   underlineMode: UnderlineMode.ignore,
///   useStreaming: true, // For large files
/// );
/// final markdown = await 'document.docx'.docxToMarkdown(config: config);
/// Configuration for DocxToMarkdownConverter
class DocxToMarkdownConfig {
  const DocxToMarkdownConfig({
    this.styleMapping = const {
      'Heading1': '# ',
      'Heading2': '## ',
      'Heading3': '### ',
      'Heading4': '#### ',
      'Heading5': '##### ',
      'Heading6': '###### ',
      'Title': '# ',
      'Subtitle': '## ',
      'Quote': '> ',
      'IntenseQuote': '> ',
      'Code': '```',
    },
    this.bulletStyles = const ['-', '*', '+'],
    this.extractImages = true,
    this.includeComments = false,
    this.preserveEmptyParagraphs = false,
    this.maxImageWidth = 0,
    this.codeBlockStyle = 'Code',
    this.customStyleHandlers = const {},
    this.underlineMode = UnderlineMode.html,
    this.useStreaming = false,
  });
  final Map<String, String> styleMapping;
  final List<String> bulletStyles;
  final bool extractImages;
  final bool includeComments;
  final bool preserveEmptyParagraphs;
  final int maxImageWidth;
  final String codeBlockStyle;
  final Map<String, String> customStyleHandlers;
  final UnderlineMode underlineMode;
  final bool useStreaming;

  /// Default configuration with sensible defaults
  static const defaults = DocxToMarkdownConfig();

  DocxToMarkdownConfig copyWith({
    Map<String, String>? styleMapping,
    List<String>? bulletStyles,
    bool? extractImages,
    bool? includeComments,
    bool? preserveEmptyParagraphs,
    int? maxImageWidth,
    String? codeBlockStyle,
    Map<String, String>? customStyleHandlers,
    UnderlineMode? underlineMode,
    bool? useStreaming,
  }) {
    return DocxToMarkdownConfig(
      styleMapping: styleMapping ?? this.styleMapping,
      bulletStyles: bulletStyles ?? this.bulletStyles,
      extractImages: extractImages ?? this.extractImages,
      includeComments: includeComments ?? this.includeComments,
      preserveEmptyParagraphs:
          preserveEmptyParagraphs ?? this.preserveEmptyParagraphs,
      maxImageWidth: maxImageWidth ?? this.maxImageWidth,
      codeBlockStyle: codeBlockStyle ?? this.codeBlockStyle,
      customStyleHandlers: customStyleHandlers ?? this.customStyleHandlers,
      underlineMode: underlineMode ?? this.underlineMode,
      useStreaming: useStreaming ?? this.useStreaming,
    );
  }
}

/// How to handle underline formatting
enum UnderlineMode {
  /// Output as HTML <u> tags
  html,

  /// Output as ++text++ (some markdown flavors)
  plusPlus,

  /// Ignore underlines
  ignore,
}

/// Tracks list state across paragraphs
class ListState {
  final Map<String, ListInfo> _activeLists = {};
  final Map<String, int> _counters = {};

  void updateList(String numId, String ilvl, String? numFmt) {
    final level = int.tryParse(ilvl) ?? 0;
    final key = '$numId:$ilvl';

    if (!_counters.containsKey(key) || numFmt == 'bullet') {
      _counters[key] = 0;
    }

    if (numFmt != 'bullet') {
      _counters[key] = (_counters[key] ?? 0) + 1;
    }

    _activeLists[numId] = ListInfo(
      level: level,
      format: numFmt,
      lastIndex: _counters[key] ?? 1,
    );
  }

  void clearList(String numId) {
    _activeLists.remove(numId);
  }

  void clearAll() {
    _activeLists.clear();
    _counters.clear();
  }

  ListInfo? getList(String numId) => _activeLists[numId];
}

class ListInfo {
  ListInfo({
    required this.level,
    this.format,
    required this.lastIndex,
  });
  final int level;
  final String? format;
  final int lastIndex;
}

/// Main class for converting DOCX files to Markdown
class DocxToMarkdownConverter {
  /// Creates a new converter instance
  DocxToMarkdownConverter({
    this.outputMediaPath,
    DocxToMarkdownConfig? config,
  }) : config = config ?? DocxToMarkdownConfig.defaults;
  final Map<String, String> _mediaFiles = {};
  final Map<String, Relationship> _relationships = {};
  final Map<String, String> _numbering = {};
  final Map<String, String> _numToAbstract = {};
  final Map<String, CommentInfo> _comments = {};
  final List<String> _activeComments = [];
  final List<FootnoteInfo> _footnotes = [];
  final List<VerticalMergeCell> _verticalMerges = [];
  final StringBuffer _output = StringBuffer();
  final String? outputMediaPath;
  final DocxToMarkdownConfig config;
  final ListState _listState = ListState();

  /// Converts a DOCX file to Markdown format
  /// Throws [DocxException] for any conversion errors
  ///
  /// For very large DOCX files, consider setting [config.useStreaming] to true
  /// to reduce memory usage.
  Future<String> convertFile(String filePath) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    // Check file extension
    final ext = path.extension(filePath).toLowerCase();
    if (ext == '.doc') {
      throw UnsupportedFormatException(
        'Old .doc format is not supported. Please convert to .docx first.',
      );
    }
    if (ext != '.docx') {
      throw UnsupportedFormatException(
        'Unsupported file format: $ext. Only .docx files are supported.',
      );
    }

    if (config.useStreaming) {
      return _processDocxStreaming(filePath);
    } else {
      return _processDocx(file);
    }
  }

  Future<String> _processDocx(File docxFile) async {
    _resetState();

    final bytes = await docxFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    await _processArchive(archive);

    return _output.toString().trim();
  }

  Future<String> _processDocxStreaming(String filePath) async {
    _resetState();

    final inputStream = InputFileStream(filePath);
    final archive = ZipDecoder().decodeStream(inputStream);

    await _processArchive(archive);
    await inputStream.close();

    return _output.toString().trim();
  }

  void _resetState() {
    _output.clear();
    _mediaFiles.clear();
    _relationships.clear();
    _numbering.clear();
    _numToAbstract.clear();
    _comments.clear();
    _activeComments.clear();
    _footnotes.clear();
    _verticalMerges.clear();
    _listState.clearAll();
  }

  Future<void> _processArchive(Archive archive) async {
    // Extract relationships
    await _parseRelationships(archive);

    // Extract numbering definitions
    await _parseNumbering(archive);

    // Extract comments if enabled
    if (config.includeComments) {
      await _parseComments(archive);
    }

    // Extract footnotes
    await _parseFootnotes(archive);

    // Extract media files
    if (config.extractImages && outputMediaPath != null) {
      await _extractMediaFiles(archive);
    }

    // Extract and parse main document
    final docFile = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw DocxParsingException('Missing word/document.xml'),
    );

    // FIX: The argument type 'Uint8List?' can't be assigned to the parameter type 'List<int>'. (Documentation)
    final xmlDoc = XmlDocument.parse(
      const Utf8Decoder().convert(docFile.readBytes() ?? []),
    );

    // Process document body
    final body = xmlDoc.findAllElements('w:body').firstOrNull;
    if (body == null) {
      throw DocxParsingException('Document body not found');
    }

    // Track code block state
    bool inCodeBlock = false;

    for (final element in body.children) {
      if (element is XmlElement) {
        inCodeBlock = await _processElement(element, inCodeBlock);
      }
    }

    // Close any open code block
    if (inCodeBlock) {
      _output
        ..writeln('```')
        ..writeln();
    }

    // Append footnotes if any
    if (_footnotes.isNotEmpty) {
      _output.writeln('\n---\n');
      for (final footnote in _footnotes) {
        _output.writeln('[^${footnote.id}]: ${footnote.text}');
      }
    }
  }

  Future<void> _parseRelationships(Archive archive) async {
    final relsFile = archive.files.firstWhereOrNull(
      (f) => f.name == 'word/_rels/document.xml.rels',
    );

    if (relsFile == null) return;

    // FIX: The argument type 'Uint8List?' can't be assigned to the parameter type 'List<int>'. (Documentation)
    final relsDoc = XmlDocument.parse(
      const Utf8Decoder().convert(relsFile.readBytes() ?? []),
    );

    for (final rel in relsDoc.findAllElements('Relationship')) {
      final id = rel.getAttribute('Id');
      final type = rel.getAttribute('Type');
      final target = rel.getAttribute('Target');

      if (id != null && target != null) {
        _relationships[id] = Relationship(
          id: id,
          type: type ?? '',
          target: target,
        );
      }
    }
  }

  Future<void> _parseNumbering(Archive archive) async {
    final numFile = archive.files.firstWhereOrNull(
      (f) => f.name == 'word/numbering.xml',
    );

    if (numFile == null) return;

    final numDoc = XmlDocument.parse(
      const Utf8Decoder().convert(numFile.readBytes() ?? []),
    );

    // Parse abstract numbering definitions
    for (final abstractNum in numDoc.findAllElements('w:abstractNum')) {
      final abstractNumId = abstractNum.getAttribute('w:abstractNumId');
      if (abstractNumId != null) {
        for (final lvl in abstractNum.findAllElements('w:lvl')) {
          final ilvl = lvl.getAttribute('w:ilvl');
          final numFmt = lvl
              .findElements('w:numFmt')
              .firstOrNull
              ?.getAttribute('w:val');
          if (ilvl != null) {
            _numbering['$abstractNumId:$ilvl'] = numFmt ?? 'bullet';
          }
        }
      }
    }

    // Parse num to abstractNum mapping
    for (final num in numDoc.findAllElements('w:num')) {
      final numId = num.getAttribute('w:numId');
      final abstractNumId = num.findElements(
        'w:abstractNumId',
      ).firstOrNull?.getAttribute('w:val');
      if (numId != null && abstractNumId != null) {
        _numToAbstract[numId] = abstractNumId;
      }
    }
  }

  Future<void> _parseComments(Archive archive) async {
    final commentsFile = archive.files.firstWhereOrNull(
      (f) => f.name == 'word/comments.xml',
    );

    if (commentsFile == null) return;

    final commentsDoc = XmlDocument.parse(
      const Utf8Decoder().convert(commentsFile.readBytes() ?? []),
    );

    for (final comment in commentsDoc.findAllElements('w:comment')) {
      final id = comment.getAttribute('w:id');
      final author = comment.getAttribute('w:author');

      // Extract comment text properly with paragraph boundaries
      final paragraphs = comment.findAllElements('w:p');
      final textParts = <String>[];

      for (final p in paragraphs) {
        final text = p.findAllElements('w:t').map((e) => e.innerText).join();
        if (text.isNotEmpty) {
          textParts.add(text);
        }
      }

      if (id != null) {
        _comments[id] = CommentInfo(
          id: id,
          author: author ?? 'Unknown',
          text: textParts.join(' '),
        );
      }
    }
  }

  Future<void> _parseFootnotes(Archive archive) async {
    final footnotesFile = archive.files.firstWhereOrNull(
      (f) => f.name == 'word/footnotes.xml',
    );

    if (footnotesFile == null) return;

    final footnotesDoc = XmlDocument.parse(
      const Utf8Decoder().convert(footnotesFile.readBytes() ?? []),
    );

    for (final footnote in footnotesDoc.findAllElements('w:footnote')) {
      final id = footnote.getAttribute('w:id');
      if (id != null && id != '0' && id != '-1') {
        // Skip separator and continuation
        // Extract footnote text properly
        final paragraphs = footnote.findAllElements('w:p');
        final textParts = <String>[];

        for (final p in paragraphs) {
          final text = _extractParagraphContent(p);
          if (text.isNotEmpty) {
            textParts.add(text);
          }
        }

        _footnotes.add(FootnoteInfo(id: id, text: textParts.join(' ')));
      }
    }
  }

  Future<void> _extractMediaFiles(Archive archive) async {
    if (outputMediaPath == null) return;

    final mediaDir = Directory(outputMediaPath!);
    if (!mediaDir.existsSync()) {
      await mediaDir.create(recursive: true);
    }

    for (final file in archive.files) {
      if (file.name.startsWith('word/media/')) {
        final fileName = path.basename(file.name);
        final outputFile = File(path.join(outputMediaPath!, fileName));

        // Use streaming write for large images
        final outputStream = OutputFileStream(outputFile.path);
        file.writeContent(outputStream);
        await outputStream.close();

        // Map both the full path and just the filename
        _mediaFiles[file.name] = fileName;
        _mediaFiles[fileName] = fileName;
      }
    }
  }

  Future<bool> _processElement(XmlElement element, bool inCodeBlock) async {
    switch (element.name.local) {
      case 'p':
        return _processParagraph(element, inCodeBlock);
      case 'tbl':
        _processTable(element);
        return false;
      default:
        return inCodeBlock;
    }
  }

  bool _processParagraph(XmlElement p, bool inCodeBlock) {
    var isInCodeBlock = inCodeBlock;
    final pPr = p.getElement('w:pPr');
    final styleEl = pPr?.getElement('w:pStyle')?.getAttribute('w:val');
    final numPr = pPr?.getElement('w:numPr');

    // Check if this is a code block style
    final bool isCodeBlockStyle = styleEl == config.codeBlockStyle;

    // Handle code blocks
    if (isCodeBlockStyle) {
      final content = _extractParagraphContent(p);

      if (!isInCodeBlock) {
        // Start new code block
        _output
          ..writeln('```')
          ..writeln(content);
        return true;
      } else {
        // Continue code block
        _output.writeln(content);
        return true;
      }
    } else if (isInCodeBlock) {
      // End code block
      _output
        ..writeln('```')
        ..writeln();
      isInCodeBlock = false;
    }

    // Determine paragraph prefix
    String prefix = '';
    if (styleEl != null && config.styleMapping.containsKey(styleEl)) {
      prefix = config.styleMapping[styleEl]!;
    } else if (styleEl != null &&
        config.customStyleHandlers.containsKey(styleEl)) {
      prefix = config.customStyleHandlers[styleEl]!;
    } else if (numPr != null) {
      prefix = _getListPrefix(numPr);
    }

    // Process content
    final content = _extractParagraphContent(p);

    // Handle horizontal rules
    if (content == '---' || content == '***' || content == '___') {
      _output
        ..writeln(content)
        ..writeln();
      return false;
    }

    if (content.isNotEmpty ||
        (config.preserveEmptyParagraphs && prefix.isEmpty)) {
      _output.writeln('$prefix$content');

      // Add spacing
      if (prefix.startsWith('#')) {
        _output.writeln();
      } else if (!_isListItem(prefix) && prefix != '> ') {
        _output.writeln();
      }
    }

    return false;
  }

  String _getListPrefix(XmlElement numPr) {
    final ilvl = numPr.getElement('w:ilvl')?.getAttribute('w:val') ?? '0';
    final numId = numPr.getElement('w:numId')?.getAttribute('w:val');

    if (numId == null) return '';

    final level = int.tryParse(ilvl) ?? 0;
    final indent = ' ' * (level * 2);

    // Look up numbering format through the num -> abstract mapping
    final abstractId = _numToAbstract[numId];
    String? numFmt;
    if (abstractId != null) {
      numFmt = _numbering['$abstractId:$ilvl'];
    }

    // Update list state
    _listState.updateList(numId, ilvl, numFmt);
    final listInfo = _listState.getList(numId);

    if (numFmt == 'decimal') {
      return '$indent${listInfo?.lastIndex ?? 1}. ';
    } else if (numFmt == 'lowerLetter') {
      final letter = String.fromCharCode(96 + (listInfo?.lastIndex ?? 1));
      return '$indent$letter. ';
    } else if (numFmt == 'upperLetter') {
      final letter = String.fromCharCode(64 + (listInfo?.lastIndex ?? 1));
      return '$indent$letter. ';
    } else {
      // Bulleted list
      final bullet = config.bulletStyles[level % config.bulletStyles.length];
      return '$indent$bullet ';
    }
  }

  bool _isListItem(String prefix) {
    return prefix.trimLeft().startsWith('-') ||
        prefix.trimLeft().startsWith('*') ||
        prefix.trimLeft().startsWith('+') ||
        RegExp(r'^\s*(\d+|[a-zA-Z])\.\s').hasMatch(prefix);
  }

  String _extractParagraphContent(XmlElement p) {
    final parts = <String>[];

    for (final child in p.children) {
      if (child is XmlElement) {
        switch (child.name.local) {
          case 'r':
            parts.add(_processRun(child));
          case 'hyperlink':
            parts.add(_processHyperlink(child));
          case 'commentRangeStart':
            if (config.includeComments) {
              final id = child.getAttribute('w:id');
              if (id != null) {
                _activeComments.add(id);
              }
            }
          case 'commentRangeEnd':
            if (config.includeComments) {
              final id = child.getAttribute('w:id');
              if (id != null && _activeComments.contains(id)) {
                _activeComments.remove(id);
                if (_comments.containsKey(id)) {
                  final comment = _comments[id]!;
                  parts.add('^[${comment.author}: ${comment.text}]');
                }
              }
            }
        }
      }
    }

    return parts.join();
  }

  String _processRun(XmlElement r) {
    final textBuffer = StringBuffer();

    // Check for footnote reference
    final footnoteRef = r.getElement('w:footnoteReference');
    if (footnoteRef != null) {
      final id = footnoteRef.getAttribute('w:id');
      if (id != null) {
        return '[^$id]';
      }
    }

    // Extract text
    for (final t in r.findAllElements('w:t')) {
      textBuffer.write(t.innerText);
    }

    // Handle breaks
    if (r.findElements('w:br').isNotEmpty) {
      textBuffer.write('  \n'); // Markdown line break
    }

    // Handle tabs
    if (r.findElements('w:tab').isNotEmpty) {
      textBuffer.write('\t');
    }

    // Handle images
    final drawing = r.getElement('w:drawing');
    if (drawing != null) {
      final image = _extractImage(drawing);
      if (image != null) {
        return image;
      }
    }

    // Handle embedded objects
    final object = r.getElement('w:object');
    if (object != null) {
      return '[Embedded Object]';
    }

    // Apply formatting
    final rPr = r.getElement('w:rPr');
    final text = textBuffer.toString();
    if (rPr != null && text.isNotEmpty) {
      return _applyFormatting(text, rPr);
    }

    return text;
  }

  String _applyFormatting(String text, XmlElement rPr) {
    var txt = text;

    final isBold =
        rPr.findElements('w:b').isNotEmpty &&
        rPr.findElements('w:b').first.getAttribute('w:val') != 'false';
    final isItalic =
        rPr.findElements('w:i').isNotEmpty &&
        rPr.findElements('w:i').first.getAttribute('w:val') != 'false';
    final isStrike = rPr.findElements('w:strike').isNotEmpty;
    final isUnderline = rPr.findElements('w:u').isNotEmpty;
    final isSubscript = rPr
        .findElements('w:vertAlign')
        .any((e) => e.getAttribute('w:val') == 'subscript');
    final isSuperscript = rPr
        .findElements('w:vertAlign')
        .any((e) => e.getAttribute('w:val') == 'superscript');
    final isCode = _isCodeFormatting(rPr);

    // Apply code formatting first
    if (isCode) {
      return '`$txt`';
    }

    // Apply other formatting
    if (isSubscript) {
      txt = '<sub>$txt</sub>';
    } else if (isSuperscript) {
      txt = '<sup>$txt</sup>';
    }

    if (isBold && isItalic) {
      txt = '***$txt***';
    } else if (isBold) {
      txt = '**$txt**';
    } else if (isItalic) {
      txt = '*$txt*';
    }

    if (isStrike) {
      txt = '~~$txt~~';
    }

    if (isUnderline) {
      switch (config.underlineMode) {
        case UnderlineMode.html:
          txt = '<u>$txt</u>';
        case UnderlineMode.plusPlus:
          txt = '++$txt++';
        case UnderlineMode.ignore:
          // Do nothing
          break;
      }
    }

    return txt;
  }

  bool _isCodeFormatting(XmlElement rPr) {
    // Check for courier fonts
    final font = rPr
        .getElement('w:rFonts')
        ?.getAttribute('w:ascii')
        ?.toLowerCase();
    if (font != null &&
        (font.contains('courier') ||
            font.contains('consolas') ||
            font.contains('monaco'))) {
      return true;
    }

    // Check for shading (often used for inline code)
    if (rPr.findElements('w:shd').isNotEmpty) {
      return true;
    }

    return false;
  }

  String? _extractImage(XmlElement drawing) {
    try {
      // Skip shapes and diagrams
      if (_isShape(drawing)) {
        return null;
      }

      // Extract image data
      final picProps = drawing.findAllElements('pic:cNvPr').firstOrNull;
      final altText =
          picProps?.getAttribute('descr') ??
          picProps?.getAttribute('name') ??
          'Image';

      final blip = drawing.findAllElements('a:blip').firstOrNull;
      final embed = blip?.getAttribute('r:embed');

      if (embed != null) {
        // Look up in relationships
        final rel = _relationships[embed];
        if (rel != null) {
          final imagePath = _resolveImagePath(rel.target);

          // Add width constraint if configured
          if (config.maxImageWidth > 0) {
            return '![$altText]($imagePath =${config.maxImageWidth}x)';
          }
          return '![$altText]($imagePath)';
        }
      }

      return '![$altText](embedded-image)';
    } catch (e) {
      return null;
    }
  }

  bool _isShape(XmlElement drawing) {
    return drawing.findAllElements('wps:wsp').isNotEmpty ||
        drawing.findAllElements('v:shape').isNotEmpty ||
        drawing.findAllElements('mc:AlternateContent').isNotEmpty;
  }

  String _resolveImagePath(String target) {
    if (_mediaFiles.isNotEmpty) {
      // Check if we have this media file
      final mediaKey = 'word/$target';
      if (_mediaFiles.containsKey(mediaKey)) {
        return _mediaFiles[mediaKey]!;
      }

      // Try just the filename
      final filename = path.basename(target);
      if (_mediaFiles.containsKey(filename)) {
        return _mediaFiles[filename]!;
      }
    }

    return target;
  }

  String _processHyperlink(XmlElement hyperlink) {
    final rid = hyperlink.getAttribute('r:id');
    final anchor = hyperlink.getAttribute('w:anchor');

    final linkTextBuffer = StringBuffer();
    for (final r in hyperlink.findAllElements('w:r')) {
      linkTextBuffer.write(_processRun(r));
    }
    final linkText = linkTextBuffer.toString();

    if (anchor != null) {
      return '[$linkText](#$anchor)';
    } else if (rid != null) {
      final rel = _relationships[rid];
      if (rel != null) {
        return '[$linkText](${rel.target})';
      }
    }

    return linkText;
  }

  void _processTable(XmlElement table) {
    final rows = table.findAllElements('w:tr').toList();
    if (rows.isEmpty) return;

    // Reset vertical merge tracking
    _verticalMerges.clear();

    // Analyze table for column alignment
    final columnAlignments = _analyzeTableAlignment(table);

    // Process all rows
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final cells = row.findAllElements('w:tc').toList();
      final cellTexts = <String>[];
      var colIndex = 0;

      for (final cell in cells) {
        // Check for vertical merge
        final vMerge = cell.getElement('w:tcPr')?.getElement('w:vMerge');

        if (vMerge != null && vMerge.getAttribute('w:val') != 'restart') {
          // This is a continuation of a vertical merge
          cellTexts.add(' ');
        } else {
          // Normal cell or start of vertical merge
          final cellText = StringBuffer();
          final paragraphs = cell.findAllElements('w:p').toList();

          for (var j = 0; j < paragraphs.length; j++) {
            final p = paragraphs[j];
            final paragraphText = _extractParagraphContent(p);
            if (paragraphText.isNotEmpty) {
              if (cellText.isNotEmpty) cellText.write('<br>');
              cellText.write(paragraphText);
            }
          }

          final content = cellText.toString().trim();
          cellTexts.add(content.isEmpty ? ' ' : content.replaceAll('|', r'\|'));

          // Track vertical merge start
          if (vMerge != null && vMerge.getAttribute('w:val') == 'restart') {
            _verticalMerges.add(VerticalMergeCell(row: i, col: colIndex));
          }
        }

        // Handle column spans
        final gridSpan = cell
            .getElement('w:tcPr')
            ?.getElement('w:gridSpan')
            ?.getAttribute('w:val');
        final spanCount = int.tryParse(gridSpan ?? '1') ?? 1;

        // Add empty cells for column spans
        for (var k = 1; k < spanCount; k++) {
          cellTexts.add(' ');
          colIndex++;
        }

        colIndex++;
      }

      _output.writeln('| ${cellTexts.join(' | ')} |');

      // Add separator after first row
      if (i == 0) {
        final separators = <String>[];
        for (var j = 0; j < cellTexts.length; j++) {
          final alignment = j < columnAlignments.length
              ? columnAlignments[j]
              : 'left';
          switch (alignment) {
            case 'center':
              separators.add(':---:');
            case 'right':
              separators.add('---:');
            default:
              separators.add('---');
          }
        }
        _output.writeln('|${separators.join('|')}|');
      }
    }

    _output.writeln();
  }

  List<String> _analyzeTableAlignment(XmlElement table) {
    final alignments = <String>[];

    // Get first row to analyze columns
    final firstRow = table.findAllElements('w:tr').firstOrNull;
    if (firstRow != null) {
      for (final cell in firstRow.findAllElements('w:tc')) {
        final jc = cell
            .getElement('w:tcPr')
            ?.getElement('w:jc')
            ?.getAttribute('w:val');
        alignments.add(jc ?? 'left');
      }
    }

    return alignments;
  }
}

// Helper classes
class Relationship {
  Relationship({
    required this.id,
    required this.type,
    required this.target,
  });
  final String id;
  final String type;
  final String target;
}

class CommentInfo {
  CommentInfo({
    required this.id,
    required this.author,
    required this.text,
  });
  final String id;
  final String author;
  final String text;
}

class FootnoteInfo {
  FootnoteInfo({
    required this.id,
    required this.text,
  });
  final String id;
  final String text;
}

class VerticalMergeCell {
  VerticalMergeCell({
    required this.row,
    required this.col,
  });
  final int row;
  final int col;
}

/// Base exception for all DOCX conversion errors
abstract class DocxException implements Exception {
  String get message;

  @override
  String toString() => message;
}

/// Exception thrown when file format is not supported
class UnsupportedFormatException extends DocxException {
  UnsupportedFormatException(this.message);
  @override
  final String message;

  @override
  String toString() => 'UnsupportedFormatException: $message';
}

/// Exception thrown when DOCX parsing fails
class DocxParsingException extends DocxException {
  DocxParsingException(this.message);
  @override
  final String message;

  @override
  String toString() => 'DocxParsingException: $message';
}

// Extension method for convenience
extension DocxToMarkdown on String {
  /// Converts this file path (must be .docx) to markdown
  Future<String> docxToMarkdown({
    String? outputMediaPath,
    DocxToMarkdownConfig? config,
  }) async {
    final converter = DocxToMarkdownConverter(
      outputMediaPath: outputMediaPath,
      config: config,
    );
    return converter.convertFile(this);
  }
}
