import 'dart:io';

import 'package:archive/archive.dart';
import 'package:context_collector/src/features/scan/models/scan_result.dart';
import 'package:context_collector/src/features/scan/models/scanned_file.dart';
import 'package:context_collector/src/features/scan/services/unified_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnifiedFileService .docx conversion', () {
    test('loadFileContent converts docx content to markdown', () async {
      final directory = await Directory.systemTemp.createTemp('docx_test_');
      addTearDown(() => directory.delete(recursive: true));

      final docxFile = File('${directory.path}/sample.docx');
      await docxFile.writeAsBytes(_minimalDocxBytes('Hello from docx'));

      final scannedFile = ScannedFile.fromFile(
        docxFile,
        source: ScanSource.browse,
      );

      final loaded = await UnifiedFileService.loadFileContent(scannedFile);

      expect(loaded.error, isNull);
      expect(loaded.content, contains('Hello from docx'));
    });

    test(
      'loadFileContent returns a docx-specific error for invalid docx files',
      () async {
        final directory = await Directory.systemTemp.createTemp('docx_test_');
        addTearDown(() => directory.delete(recursive: true));

        final docxFile = File('${directory.path}/broken.docx');
        await docxFile.writeAsString('not a zip package');

        final scannedFile = ScannedFile.fromFile(
          docxFile,
          source: ScanSource.browse,
        );

        final loaded = await UnifiedFileService.loadFileContent(scannedFile);

        expect(loaded.content, isNull);
        expect(loaded.error, startsWith('Cannot read .docx file:'));
      },
    );
  });
}

List<int> _minimalDocxBytes(String text) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        '[Content_Types].xml',
        '''
<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        '_rels/.rels',
        '''
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'word/document.xml',
        '''
<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r>
        <w:t>$text</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>''',
      ),
    );

  return ZipEncoder().encode(archive);
}
