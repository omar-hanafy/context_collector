import 'package:context_collector/src/features/editor/data/token_counter/token_counter.dart';

Future<void> main() async {
  final iso = TokenCounter();
  final total = await iso.computeTotal([
    'Hello world. This is a test string to ensure tokens are counted.',
  ], model: 'gpt-4o');
  print('total: $total');
  await iso.dispose();
}
