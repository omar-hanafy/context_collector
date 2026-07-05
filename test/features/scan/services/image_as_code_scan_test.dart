import 'dart:io';

import 'package:context_collector/src/features/scan/models/scan_result.dart';
import 'package:context_collector/src/features/scan/models/scanned_file.dart';
import 'package:context_collector/src/features/scan/services/unified_file_service.dart';
import 'package:context_collector/src/features/settings/domain/filter_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('image-as-code scanning', () {
    test('default blacklist allows SVG files', () {
      expect(FilterSettings.defaultBlacklist, isNot(contains('.svg')));
    });

    test('saved legacy blacklists are migrated to allow SVG files', () {
      final settings = FilterSettings.fromJson(const {
        'blacklistedExtensions': ['.svg', '.png'],
      });

      expect(settings.blacklistedExtensions, isNot(contains('.svg')));
      expect(settings.blacklistedExtensions, contains('.png'));
    });

    test('loadFileContent reads SVG as text', () async {
      final directory = await Directory.systemTemp.createTemp(
        'context_collector_svg_load_test',
      );
      addTearDown(() => directory.delete(recursive: true));

      final svgFile = File('${directory.path}/icon.svg');
      await svgFile.writeAsString(
        '<svg viewBox="0 0 1 1" xmlns="http://www.w3.org/2000/svg"></svg>',
      );

      final loaded = await UnifiedFileService.loadFileContent(
        ScannedFile.fromFile(svgFile),
      );

      expect(loaded.error, isNull);
      expect(loaded.content, contains('<svg'));
    });

    test(
      'scanDirectory includes SVG while still skipping binary images',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'context_collector_image_as_code_test',
        );
        addTearDown(() => directory.delete(recursive: true));

        final svgFile = File('${directory.path}/icon.svg');
        final pngFile = File('${directory.path}/icon.png');
        await svgFile.writeAsString(
          '<svg viewBox="0 0 1 1" xmlns="http://www.w3.org/2000/svg"></svg>',
        );
        await pngFile.writeAsBytes([0, 1, 2, 3]);

        final foundNames = <String>[];
        await UnifiedFileService.scanDirectory(
          directoryPath: directory.path,
          blacklist: FilterSettings.defaultBlacklist,
          source: ScanSource.browse,
          onBatchFound: (files) {
            foundNames.addAll(files.map((file) => file.name));
          },
        );

        expect(foundNames, contains('icon.svg'));
        expect(foundNames, isNot(contains('icon.png')));
      },
    );
  });
}
