import 'package:context_collector/src/features/editor/data/monaco_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monacoDocumentUriForFileId', () {
    test('is stable for the same file id', () {
      expect(
        monacoDocumentUriForFileId('file-123'),
        monacoDocumentUriForFileId('file-123'),
      );
    });

    test('is distinct across different file ids', () {
      expect(
        monacoDocumentUriForFileId('file-a'),
        isNot(monacoDocumentUriForFileId('file-b')),
      );
    });

    test('uses the context-collector file scheme so models never collide '
        'with the view-all preview document', () {
      final uri = monacoDocumentUriForFileId('file-123');
      expect(uri.scheme, 'context-collector');
      expect(uri.host, 'file');
    });

    test('keeps ids with path separators inside a single segment', () {
      final uri = monacoDocumentUriForFileId('a/b c');
      expect(uri.pathSegments, ['a/b c']);
    });
  });
}
