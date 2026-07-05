import 'package:context_collector/src/features/scan/models/file_category.dart';
import 'package:context_collector/src/features/scan/ui/file_display_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileDisplayHelper', () {
    test('getLanguageId maps .docx to markdown', () {
      expect(FileDisplayHelper.getLanguageId('.docx'), 'markdown');
      expect(FileDisplayHelper.getLanguageId('.md'), 'markdown');
    });

    test('getLanguageId maps XML and JSON image-as-code formats', () {
      expect(FileDisplayHelper.getLanguageId('.svg'), 'xml');
      expect(FileDisplayHelper.getLanguageId('.drawio'), 'xml');
      expect(FileDisplayHelper.getLanguageId('.dio'), 'xml');
      expect(FileDisplayHelper.getLanguageId('.excalidraw'), 'json');
    });

    test('getCategoryForExtension maps .docx to documentation', () {
      expect(
        FileDisplayHelper.getCategoryForExtension('.docx'),
        FileCategory.documentation,
      );
    });

    test('getCategoryForExtension maps image-as-code formats', () {
      for (final extension
          in FileDisplayHelper.imageAsCodeExtensionCatalog.keys) {
        expect(
          FileDisplayHelper.getCategoryForExtension(extension),
          FileCategory.imageAsCode,
        );
      }
    });
  });
}
