import 'dart:io';

import 'package:context_collector/src/features/scan/services/path_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PathParserService', () {
    late PathParserService parser;

    setUp(() {
      parser = PathParserService();
    });

    test('parses space-delimited paths', () async {
      const input = '/usr/bin /home/user/docs /var/log';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 3);
      expect(result.validPaths, contains('/usr/bin'));
      expect(result.validPaths, contains('/home/user/docs'));
      expect(result.validPaths, contains('/var/log'));
      expect(result.hasErrors, false);
    });

    test('parses newline-delimited paths', () async {
      const input = '/usr/bin\n/home/user/docs\n/var/log';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 3);
      expect(result.validPaths, contains('/usr/bin'));
      expect(result.validPaths, contains('/home/user/docs'));
      expect(result.validPaths, contains('/var/log'));
      expect(result.hasErrors, false);
    });

    test('parses quoted paths with spaces', () async {
      const input =
          r'"/path with spaces/file.txt" /normal/path "C:\Program Files\App"';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 3);
      expect(result.validPaths, contains('/path with spaces/file.txt'));
      expect(result.validPaths, contains('/normal/path'));
      expect(result.validPaths, contains('C:/Program Files/App'));
      expect(result.hasErrors, false);
    });

    test('handles Windows paths', () async {
      const input = r'C:\Users\John\Documents D:\Projects\MyApp';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 2);
      expect(result.validPaths, contains('C:/Users/John/Documents'));
      expect(result.validPaths, contains('D:/Projects/MyApp'));
      expect(result.hasErrors, false);
    });

    test('splits concatenated Windows paths', () async {
      const input = 'C:/UsersD:/Projects';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 2);
      expect(result.validPaths, contains('C:/Users'));
      expect(result.validPaths, contains('D:/Projects'));
      expect(result.hasErrors, false);
    });

    test('handles mixed Windows and POSIX paths', () async {
      const input = r'C:\Windows\System32 /usr/local/bin D:\Data';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 3);
      expect(result.validPaths, contains('C:/Windows/System32'));
      expect(result.validPaths, contains('/usr/local/bin'));
      expect(result.validPaths, contains('D:/Data'));
      expect(result.hasErrors, false);
    });

    test('ignores paths with .. for security', () async {
      const input = '/valid/path ../parent/path /another/valid';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 2);
      expect(result.validPaths, contains('/valid/path'));
      expect(result.validPaths, contains('/another/valid'));
      expect(result.validPaths, isNot(contains('../parent/path')));
      expect(result.hasErrors, true);
      expect(result.errors.containsKey('../parent/path'), true);
      expect(result.errors['../parent/path'], contains('".."'));
    });

    test('removes duplicates', () async {
      const input = '/home/user /home/user /HOME/USER';
      final result = await parser.parse(input);

      // On case-insensitive systems (macOS/Windows), should deduplicate
      // On case-sensitive systems (Linux), might keep both
      expect(result.validPaths.length, lessThanOrEqualTo(2));
      expect(result.validPaths, contains('/home/user'));
      expect(result.hasErrors, false);
    });

    test('handles empty input', () async {
      const input = '   \n\n   \t   ';
      final result = await parser.parse(input);

      expect(result.validPaths.isEmpty, true);
      expect(result.hasErrors, false);
    });

    test('handles UNC paths on Windows', () async {
      const input = r'\\server\share\folder \\server\share\file.txt';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 2);
      expect(result.validPaths, contains(r'\\server\share\folder'));
      expect(result.validPaths, contains(r'\\server\share\file.txt'));
      expect(result.hasErrors, false);
    });

    test('validates illegal characters based on platform', () async {
      const input = '/path/with<illegal>chars /path/with|pipe';
      final result = await parser.parse(input);

      // On macOS/Linux, < and | are actually valid in filenames
      // Only null character is truly illegal
      if (Platform.isWindows) {
        expect(result.validPaths.isEmpty, true);
        expect(result.hasErrors, true);
        expect(result.errors.length, 2);
        expect(
          result.errors.values.any((msg) => msg.contains('illegal characters')),
          true,
        );
      } else {
        // On Unix systems, these characters are allowed
        expect(result.validPaths.length, 2);
        expect(result.hasErrors, false);
      }
    });

    test('handles paths that are just drive letters', () async {
      const input = r'C: D:/ E:\';
      final result = await parser.parse(input);

      expect(result.validPaths.isEmpty, true);
      expect(result.hasErrors, true);
      expect(result.errors.length, 3);
      expect(
        result.errors.values.every((msg) => msg.contains('drive letter')),
        true,
      );
    });

    test('validates path length limits', () async {
      final longPath = 'C:/${'a' * 300}'; // Over 260 chars on Windows
      final result = await parser.parse(longPath);

      if (Platform.isWindows) {
        expect(result.validPaths.isEmpty, true);
        expect(result.hasErrors, true);
        expect(result.errors.values.first, contains('exceeds maximum length'));
      } else {
        // On non-Windows, 300 chars is fine (4096 is the limit)
        expect(result.validPaths.length, 1);
        expect(result.hasErrors, false);
      }
    });

    test('handles paths with consecutive slashes', () async {
      const input = '/path//with///slashes';
      final result = await parser.parse(input);

      // The path package normalizes consecutive slashes, which is correct behavior
      expect(result.validPaths.length, 1);
      expect(result.validPaths.first, '/path/with/slashes');
      expect(result.hasErrors, false);
    });

    test('handles mixed and nested quotes correctly', () async {
      const input =
          '''"/path/with"quotes"" '/another/with'quotes'' "unclosed/quote''';
      final result = await parser.parse(input);

      // Should handle the complex quote scenarios gracefully
      expect(result.validPaths, isNotEmpty);
      // The paths with escaped quotes inside should be parsed
      expect(result.validPaths.any((p) => p.contains('quotes')), true);
    });

    test('handles relative paths', () async {
      const input = './relative/path ../parent/path src/main.dart';
      final result = await parser.parse(input);

      // Should accept relative paths except those with ..
      expect(result.validPaths.length, 2);
      expect(
        result.validPaths,
        contains('relative/path'),
      ); // path.normalize removes ./
      expect(result.validPaths, contains('src/main.dart'));
      expect(result.hasErrors, true);
      expect(result.errors.containsKey('../parent/path'), true);
    });

    test('handles unicode paths', () async {
      const input = 'C:/Benutzer/résumé.txt /用户/文档/file.txt';
      final result = await parser.parse(input);

      expect(result.validPaths.length, 2);
      expect(result.validPaths, contains('C:/Benutzer/résumé.txt'));
      expect(result.validPaths, contains('/用户/文档/file.txt'));
      expect(result.hasErrors, false);
    });

    test('handles mixed whitespace delimiters', () async {
      // Using string with actual tabs and newlines
      final input = [
        '/path1',
        '\t\t',
        '/path2',
        '\n\n  ',
        '/path3    /path4',
      ].join();
      final result = await parser.parse(input);

      expect(result.validPaths.length, 4);
      expect(result.validPaths, contains('/path1'));
      expect(result.validPaths, contains('/path2'));
      expect(result.validPaths, contains('/path3'));
      expect(result.validPaths, contains('/path4'));
      expect(result.hasErrors, false);
    });

    test('preserves all error information', () async {
      const input = '''
        /valid/path
        ../invalid/path
        /path/with<illegal>
        C:
        /another/valid/path
      ''';
      final result = await parser.parse(input);

      if (Platform.isWindows) {
        expect(result.validPaths.length, 2);
        expect(result.validPaths, contains('/valid/path'));
        expect(result.validPaths, contains('/another/valid/path'));
        expect(result.hasErrors, true);
        expect(result.errors.length, 3);
        expect(result.totalPaths, 5);
      } else {
        // On Unix systems, < is allowed in filenames
        expect(result.validPaths.length, 3);
        expect(result.validPaths, contains('/valid/path'));
        expect(result.validPaths, contains('/path/with<illegal>'));
        expect(result.validPaths, contains('/another/valid/path'));
        expect(result.hasErrors, true);
        expect(result.errors.length, 2);
        expect(result.totalPaths, 5);
      }
    });
  });
}
