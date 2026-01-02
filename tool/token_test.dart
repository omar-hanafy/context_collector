import 'package:context_collector/src/features/editor/data/token_count_isolate.dart';

Future<void> main() async {
  final iso = TokenCounterIsolate();
  final total = await iso.computeTotal([
    'Hello world. This is a test string to ensure tokens are counted.',
  ], model: 'gpt-4o');
  print('total: $total');
  await iso.dispose();
}
