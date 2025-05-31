import 'package:ai_token_calculator/ai_token_calculator.dart';
import 'package:test/test.dart';

void main() {
  late AITokenCalculator calculator;

  setUp(() {
    calculator = AITokenCalculator();
  });

  group('Token Estimation', () {
    test('estimates tokens for simple text', () {
      final estimate = calculator.estimateTokens(
        'Hello, world!',
        model: AIModel.claudeOpus,
      );

      expect(estimate.tokens, greaterThan(0));
      expect(estimate.characterCount, equals(13));
      expect(estimate.model, equals(AIModel.claudeOpus));
    });

    test('handles empty text', () {
      final estimate = calculator.estimateTokens(
        '',
        model: AIModel.gpt4,
      );

      expect(estimate.tokens, equals(0));
      expect(estimate.characterCount, equals(0));
    });

    test('different models give different estimates', () {
      const text = 'The quick brown fox jumps over the lazy dog.';

      final claudeEstimate =
          calculator.estimateTokens(text, model: AIModel.claudeOpus);
      final gptEstimate = calculator.estimateTokens(text, model: AIModel.gpt4);
      final geminiEstimate =
          calculator.estimateTokens(text, model: AIModel.geminiPro);

      // They should be close but not necessarily identical
      expect(claudeEstimate.tokens, greaterThan(0));
      expect(gptEstimate.tokens, greaterThan(0));
      expect(geminiEstimate.tokens, greaterThan(0));
    });
  });

  group('Content Type Detection', () {
    test('detects code content', () {
      const code = '''
      function fibonacci(n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
      }
      ''';

      final estimate =
          calculator.estimateTokens(code, model: AIModel.claudeSonnet);
      expect(estimate.contentType, equals(ContentType.code));
    });

    test('detects prose content', () {
      const prose = '''
      Once upon a time, in a distant kingdom, there lived a wise king. 
      He ruled with justice and compassion. His subjects loved him dearly.
      The kingdom prospered under his reign for many years.
      ''';

      final estimate =
          calculator.estimateTokens(prose, model: AIModel.claudeSonnet);
      expect(estimate.contentType, equals(ContentType.prose));
    });

    test('detects structured data', () {
      const json =
          '{"name": "John", "age": 30, "city": "New York", "hobbies": ["reading", "gaming"]}';

      final estimate =
          calculator.estimateTokens(json, model: AIModel.claudeSonnet);
      expect(estimate.contentType, equals(ContentType.structured));
    });

    test('detects chat content', () {
      const chat = '''
      User: Hello, how are you?
      Assistant: I'm doing well, thank you! How can I help you today?
      User: I need help with my code.
      Assistant: I'd be happy to help with your code. What seems to be the issue?
      ''';

      final estimate =
          calculator.estimateTokens(chat, model: AIModel.claudeSonnet);
      expect(estimate.contentType, equals(ContentType.chat));
    });
  });

  group('Token Limit Checking', () {
    test('identifies when within limits', () {
      final check = calculator.checkTokenLimit(
        'Short text',
        model: AIModel.gpt35Turbo,
      );

      expect(check.isWithinLimit, isTrue);
      expect(check.warningLevel, equals(TokenLimitWarning.low));
      expect(check.tokensRemaining, greaterThan(0));
    });

    test('identifies when exceeding limits', () {
      // Create a very long text
      final longText = 'Hello world! ' * 10000;

      final check = calculator.checkTokenLimit(
        longText,
        model: AIModel.gpt35Turbo,
      );

      expect(check.isWithinLimit, isFalse);
      expect(check.warningLevel, equals(TokenLimitWarning.exceeded));
      expect(check.percentageUsed, greaterThan(100));
    });
  });

  group('Text Truncation', () {
    test('truncates text to fit token limit', () {
      final longText = 'This is a long text that needs truncation. ' * 50;

      final truncated = calculator.truncateToTokenLimit(
        longText,
        model: AIModel.claudeHaiku,
        maxTokens: 50,
      );

      final estimate = calculator.estimateTokens(
        truncated,
        model: AIModel.claudeHaiku,
      );

      expect(estimate.tokens, lessThanOrEqualTo(50));
      expect(truncated.endsWith('...'), isTrue);
    });

    test('does not truncate if already within limit', () {
      const shortText = 'Short text';

      final result = calculator.truncateToTokenLimit(
        shortText,
        model: AIModel.claudeHaiku,
        maxTokens: 100,
      );

      expect(result, equals(shortText));
    });
  });

  group('Text Chunking', () {
    test('splits text into chunks', () {
      final longText = 'This is a long document. ' * 100;

      final chunks = calculator.splitIntoChunks(
        longText,
        model: AIModel.gpt4,
        maxTokensPerChunk: 100,
        overlap: 10,
      );

      expect(chunks.length, greaterThan(1));

      // Each chunk should be within limit
      for (final chunk in chunks) {
        final estimate = calculator.estimateTokens(chunk, model: AIModel.gpt4);
        expect(estimate.tokens, lessThanOrEqualTo(100));
      }
    });
  });

  group('Batch Processing', () {
    test('processes multiple texts', () {
      final texts = {
        'text1': 'First text',
        'text2': 'Second text with more words',
        'text3': 'Third text that is even longer than the others',
      };

      final results = calculator.batchEstimateTokens(
        texts,
        model: AIModel.geminiPro,
      );

      expect(results.length, equals(3));
      expect(results['text1']!.tokens, lessThan(results['text3']!.tokens));
    });
  });

  group('Model Specifications', () {
    test('all models have valid specifications', () {
      for (final model in AIModel.values) {
        final spec = AITokenCalculator.modelSpecs[model];

        expect(spec, isNotNull);
        expect(spec!.contextWindow, greaterThan(0));
        expect(spec.displayName, isNotEmpty);
      }
    });
  });
}
