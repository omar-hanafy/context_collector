import 'package:context_collector/src/features/merge/three_way_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThreeWayMerger', () {
    late ThreeWayMerger merger;

    setUp(() {
      merger = ThreeWayMerger();
    });

    test('handles simple case where only remote changed', () async {
      const base = 'original content';
      const local = 'original content'; // user didn\'t change anything
      const remote = 'updated content'; // file changed

      final (result, hasConflicts) = await merger.merge(
        base: base,
        local: local,
        remote: remote,
      );

      expect(result, equals('updated content'));
      expect(hasConflicts, isFalse);
    });

    test('handles simple case where only local changed', () async {
      const base = 'original content';
      const local = 'user edited content'; // user changed it
      const remote = 'original content'; // file didn\'t change

      final (result, hasConflicts) = await merger.merge(
        base: base,
        local: local,
        remote: remote,
      );

      expect(result, equals('user edited content'));
      expect(hasConflicts, isFalse);
    });

    test('handles case where both made identical changes', () async {
      const base = 'original content';
      const local = 'same change'; // user changed it
      const remote = 'same change'; // file changed to same thing

      final (result, hasConflicts) = await merger.merge(
        base: base,
        local: local,
        remote: remote,
      );

      expect(result, equals('same change'));
      expect(hasConflicts, isFalse);
    });

    test('handles successful merge of different changes', () async {
      const base = 'line 1\nline 2\nline 3';
      const local = 'modified line 1\nline 2\nline 3'; // user changed line 1
      const remote = 'line 1\nline 2\nmodified line 3'; // file changed line 3

      final (result, hasConflicts) = await merger.merge(
        base: base,
        local: local,
        remote: remote,
      );

      // Should merge both changes successfully
      expect(result, contains('modified line 1'));
      expect(result, contains('modified line 3'));
      expect(hasConflicts, isFalse);
    });

    test('handles conflicting changes gracefully', () async {
      const base = 'original line';
      const local = 'user changed line'; // user changed it one way
      const remote = 'file changed line'; // file changed it another way

      final (result, hasConflicts) = await merger.merge(
        base: base,
        local: local,
        remote: remote,
      );

      // Should return some result (probably with conflict markers)
      expect(result, isNotEmpty);
      expect(hasConflicts, isTrue);
    });

    test('wouldHaveConflicts predicts conflicts correctly', () {
      const base = 'original';
      const local = 'user edit';
      const remote = 'file edit';

      final hasConflicts = merger.wouldHaveConflicts(
        base: base,
        local: local,
        remote: remote,
      );

      expect(hasConflicts, isTrue);
    });

    test('wouldHaveConflicts returns false for safe merges', () {
      const base = 'line 1\nline 2';
      const local = 'modified line 1\nline 2';
      const remote = 'line 1\nmodified line 2';

      final hasConflicts = merger.wouldHaveConflicts(
        base: base,
        local: local,
        remote: remote,
      );

      expect(hasConflicts, isFalse);
    });

    test('handles line ending normalization', () async {
      const base = 'line 1\r\nline 2';
      const local = 'modified line 1\r\nline 2'; // Windows line endings
      const remote = 'line 1\nmodified line 2'; // Unix line endings

      final (result, hasConflicts) = await merger.merge(
        base: base,
        local: local,
        remote: remote,
      );

      // Should handle different line endings gracefully
      expect(result, contains('modified line 1'));
      expect(result, contains('modified line 2'));
      expect(hasConflicts, isFalse);
    });

    test('singleton pattern works correctly', () {
      final merger1 = ThreeWayMerger();
      final merger2 = ThreeWayMerger();

      expect(identical(merger1, merger2), isTrue);
    });
  });
}
