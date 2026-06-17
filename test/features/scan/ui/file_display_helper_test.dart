import 'package:context_collector/src/features/scan/models/file_category.dart';
import 'package:context_collector/src/features/scan/ui/file_display_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileDisplayHelper', () {
    test('getLanguageId maps .docx to markdown', () {
      expect(FileDisplayHelper.getLanguageId('.docx'), 'markdown');
      expect(FileDisplayHelper.getLanguageId('.md'), 'markdown');
    });

    test('getCategoryForExtension maps .docx to documentation', () {
      expect(
        FileDisplayHelper.getCategoryForExtension('.docx'),
        FileCategory.documentation,
      );
    });
  });
}
