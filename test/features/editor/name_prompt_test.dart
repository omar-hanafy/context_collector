import 'package:context_collector/src/shared/dialogs/name_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps its controller alive through dialog teardown', (
    tester,
  ) async {
    Future<String?>? promptResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                promptResult = promptForNewFileName(
                  context,
                  initialName: 'pasted.txt',
                );
              },
              child: const Text('Open prompt'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open prompt'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'notes.md');
    await tester.tap(find.text('Create'));

    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(await promptResult, 'notes.md');
    expect(tester.takeException(), isNull);
  });
}
