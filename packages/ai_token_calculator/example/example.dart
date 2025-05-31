import 'package:ai_token_calculator/ai_token_calculator.dart';

void main() {
  final calculator = AITokenCalculator();

  const sampleText = '''
  The quick brown fox jumps over the lazy dog. 
  This is a sample text to demonstrate token counting across different AI models.
  ''';

  const codeSnippet = '''
  function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
  }
  ''';

  print('=== AI Token Calculator Demo ===\n');

  // Example 1: Basic token estimation
  print('1. Basic Token Estimation:');
  print('-' * 40);

  for (final model in [AIModel.claudeOpus, AIModel.gpt4, AIModel.geminiPro]) {
    final estimate = calculator.estimateTokens(
      sampleText,
      model: model,
    );
    print(
        '${AITokenCalculator.modelSpecs[model]!.displayName}: ${estimate.tokens} tokens');
  }

  // Example 2: Code vs Prose
  print('\n2. Content Type Detection:');
  print('-' * 40);

  final proseEstimate = calculator.estimateTokens(
    sampleText,
    model: AIModel.claudeSonnet,
  );
  final codeEstimate = calculator.estimateTokens(
    codeSnippet,
    model: AIModel.claudeSonnet,
  );

  print('Prose detected as: ${proseEstimate.contentType.name}');
  print('Code detected as: ${codeEstimate.contentType.name}');
  print('Prose tokens: ${proseEstimate.tokens}');
  print('Code tokens: ${codeEstimate.tokens}');

  // Example 3: Token limit checking
  print('\n3. Token Limit Checking:');
  print('-' * 40);

  final longText = 'Hello world! ' * 10000; // Very long text

  final limitCheck = calculator.checkTokenLimit(
    longText,
    model: AIModel.gpt35Turbo,
  );

  print(
      'Model: ${AITokenCalculator.modelSpecs[limitCheck.model]!.displayName}');
  print('Estimated tokens: ${limitCheck.estimatedTokens}');
  print('Max tokens: ${limitCheck.maxTokens}');
  print('Usage: ${limitCheck.percentageUsed.toStringAsFixed(1)}%');
  print('Warning level: ${limitCheck.warningLevel.name}');

  // Example 4: Text truncation
  print('\n4. Text Truncation:');
  print('-' * 40);

  final textToTruncate =
      'This is a long text that needs to be truncated to fit within a specific token limit. ' *
          10;

  final truncated = calculator.truncateToTokenLimit(
    textToTruncate,
    model: AIModel.claudeHaiku,
    maxTokens: 50,
  );

  print('Original length: ${textToTruncate.length} chars');
  print('Truncated length: ${truncated.length} chars');
  print('Truncated text: "${truncated.substring(0, 50)}..."');

  // Example 5: Batch processing
  print('\n5. Batch Processing:');
  print('-' * 40);

  final texts = {
    'email': 'Dear John, I hope this email finds you well...',
    'code': 'const sum = (a, b) => a + b;',
    'json': '{"name": "John", "age": 30, "city": "New York"}',
  };

  final batchResults = calculator.batchEstimateTokens(
    texts,
    model: AIModel.gemini15Pro,
  )..forEach((key, estimate) {
      print('$key: ${estimate.tokens} tokens (${estimate.contentType.name})');
    });

  // Example 6: Text chunking
  print('\n6. Text Chunking:');
  print('-' * 40);

  final longDocument =
      'This is a very long document that needs to be split into smaller chunks. ' *
          50;

  final chunks = calculator.splitIntoChunks(
    longDocument,
    model: AIModel.mistral,
    maxTokensPerChunk: 100,
    overlap: 10,
  );

  print('Document split into ${chunks.length} chunks');
  for (var i = 0; i < chunks.length && i < 3; i++) {
    final chunkEstimate = calculator.estimateTokens(
      chunks[i],
      model: AIModel.mistral,
    );
    print('Chunk ${i + 1}: ${chunkEstimate.tokens} tokens');
  }

  // Example 7: Model comparison
  print('\n7. Model Context Window Comparison:');
  print('-' * 40);

  final models = [
    AIModel.claudeOpus,
    AIModel.gpt4,
    AIModel.gemini15Pro,
    AIModel.grok,
  ];

  for (final model in models) {
    final spec = AITokenCalculator.modelSpecs[model]!;
    print(
        '${spec.displayName}: ${spec.contextWindow.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} tokens');
  }
}
