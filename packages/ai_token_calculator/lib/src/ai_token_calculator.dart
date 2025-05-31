import 'models.dart';

/// Multi-model AI token calculator for estimating token counts
class AITokenCalculator {
  /// Model specifications with context windows and display names
  static const Map<AIModel, ModelLimits> modelSpecs = {
    // Claude models
    AIModel.claudeOpus: ModelLimits(
      model: AIModel.claudeOpus,
      contextWindow: 200000, // 200K tokens
      displayName: 'claude Opus',
    ),
    AIModel.claudeSonnet: ModelLimits(
      model: AIModel.claudeSonnet,
      contextWindow: 200000, // 200K tokens
      displayName: 'Claude Sonnet',
    ),
    AIModel.claudeHaiku: ModelLimits(
      model: AIModel.claudeHaiku,
      contextWindow: 200000, // 200K tokens
      displayName: 'Claude Haiku',
    ),

    // OpenAI models
    AIModel.gpt4: ModelLimits(
      model: AIModel.gpt4,
      contextWindow: 128000, // 128K tokens
      displayName: 'GPT-4',
    ),
    AIModel.gpt4Turbo: ModelLimits(
      model: AIModel.gpt4Turbo,
      contextWindow: 128000, // 128K tokens
      displayName: 'GPT-4 Turbo',
    ),
    AIModel.gpt35Turbo: ModelLimits(
      model: AIModel.gpt35Turbo,
      contextWindow: 16385, // 16K tokens
      displayName: 'GPT-3.5 Turbo',
    ),

    // Google models
    AIModel.geminiPro: ModelLimits(
      model: AIModel.geminiPro,
      contextWindow: 1000000, // 1M tokens
      displayName: 'Gemini Pro',
    ),

    // Others
    AIModel.grok: ModelLimits(
      model: AIModel.grok,
      contextWindow: 131072, // 128K tokens
      displayName: 'Grok',
    ),
    AIModel.mistral: ModelLimits(
      model: AIModel.mistral,
      contextWindow: 32768, // 32K tokens
      displayName: 'Mistral',
    ),
    AIModel.llama: ModelLimits(
      model: AIModel.llama,
      contextWindow: 32768, // 32K tokens
      displayName: 'Llama',
    ),
  };

  /// Research-backed divisors by model and content type
  static const Map<(AIModel, ContentType), double> _modelDivisors = {
    // Claude models (Anthropic) - from research
    (AIModel.claudeOpus, ContentType.general): 3.3,
    (AIModel.claudeOpus, ContentType.prose): 3.5,
    (AIModel.claudeOpus, ContentType.code): 2.5,
    (AIModel.claudeOpus, ContentType.structured): 2.8,
    (AIModel.claudeOpus, ContentType.chat): 3.2,
    (AIModel.claudeSonnet, ContentType.general): 3.3,
    (AIModel.claudeSonnet, ContentType.prose): 3.5,
    (AIModel.claudeSonnet, ContentType.code): 2.5,
    (AIModel.claudeSonnet, ContentType.structured): 2.8,
    (AIModel.claudeSonnet, ContentType.chat): 3.2,
    (AIModel.claudeHaiku, ContentType.general): 3.3,
    (AIModel.claudeHaiku, ContentType.prose): 3.5,
    (AIModel.claudeHaiku, ContentType.code): 2.5,
    (AIModel.claudeHaiku, ContentType.structured): 2.8,
    (AIModel.claudeHaiku, ContentType.chat): 3.2,

    // GPT-4 models (OpenAI) - from research
    (AIModel.gpt4, ContentType.general): 4.0,
    (AIModel.gpt4, ContentType.prose): 4.2,
    (AIModel.gpt4, ContentType.code): 3.0,
    (AIModel.gpt4, ContentType.structured): 3.2,
    (AIModel.gpt4, ContentType.chat): 3.8,
    (AIModel.gpt4Turbo, ContentType.general): 4.0,
    (AIModel.gpt4Turbo, ContentType.prose): 4.2,
    (AIModel.gpt4Turbo, ContentType.code): 3.0,
    (AIModel.gpt4Turbo, ContentType.structured): 3.2,
    (AIModel.gpt4Turbo, ContentType.chat): 3.8,

    // GPT-3.5 - from research
    (AIModel.gpt35Turbo, ContentType.general): 4.0,
    (AIModel.gpt35Turbo, ContentType.prose): 4.2,
    (AIModel.gpt35Turbo, ContentType.code): 3.0,
    (AIModel.gpt35Turbo, ContentType.structured): 3.2,
    (AIModel.gpt35Turbo, ContentType.chat): 3.8,

    // Gemini models (Google) - from research
    (AIModel.geminiPro, ContentType.general): 4.0,
    (AIModel.geminiPro, ContentType.prose): 4.2,
    (AIModel.geminiPro, ContentType.code): 2.7,
    (AIModel.geminiPro, ContentType.structured): 3.0,
    (AIModel.geminiPro, ContentType.chat): 3.9,
    (AIModel.gemini15Pro, ContentType.general): 4.0,
    (AIModel.gemini15Pro, ContentType.prose): 4.2,
    (AIModel.gemini15Pro, ContentType.code): 2.7,
    (AIModel.gemini15Pro, ContentType.structured): 3.0,
    (AIModel.gemini15Pro, ContentType.chat): 3.9,
    (AIModel.gemini15Flash, ContentType.general): 4.0,
    (AIModel.gemini15Flash, ContentType.prose): 4.2,
    (AIModel.gemini15Flash, ContentType.code): 2.7,
    (AIModel.gemini15Flash, ContentType.structured): 3.0,
    (AIModel.gemini15Flash, ContentType.chat): 3.9,

    // Grok (xAI) - from research
    (AIModel.grok, ContentType.general): 3.5,
    (AIModel.grok, ContentType.prose): 3.6,
    (AIModel.grok, ContentType.code): 2.6,
    (AIModel.grok, ContentType.structured): 2.9,
    (AIModel.grok, ContentType.chat): 3.4,

    // Mistral (approximated, similar to Claude)
    (AIModel.mistral, ContentType.general): 3.4,
    (AIModel.mistral, ContentType.prose): 3.6,
    (AIModel.mistral, ContentType.code): 2.6,
    (AIModel.mistral, ContentType.structured): 2.9,
    (AIModel.mistral, ContentType.chat): 3.3,

    // Llama (approximated, between GPT and Claude)
    (AIModel.llama, ContentType.general): 3.7,
    (AIModel.llama, ContentType.prose): 3.9,
    (AIModel.llama, ContentType.code): 2.8,
    (AIModel.llama, ContentType.structured): 3.1,
    (AIModel.llama, ContentType.chat): 3.5,
  };

  /// Overhead tokens for each model (system/formatting tokens)
  static const Map<AIModel, int> _modelOverhead = {
    // Claude and GPT add ~3 tokens for role formatting
    AIModel.claudeOpus: 3,
    AIModel.claudeSonnet: 3,
    AIModel.claudeHaiku: 3,
    AIModel.gpt4: 3,
    AIModel.gpt4Turbo: 3,
    AIModel.gpt35Turbo: 3,
    // Gemini and others add ~2-3 tokens
    AIModel.geminiPro: 2,
    AIModel.gemini15Pro: 2,
    AIModel.gemini15Flash: 2,
    AIModel.grok: 3,
    AIModel.mistral: 2,
    AIModel.llama: 2,
  };

  /// Estimates token count for a given text and AI model
  ///
  /// This method uses model-specific heuristics to estimate token counts:
  /// - Different models have different tokenization approaches
  /// - Content type affects the estimation
  /// - Non-ASCII characters are handled differently per model
  TokenEstimate estimateTokens(
    String text, {
    required AIModel model,
    ContentType? contentType,
    bool includeOverhead = false,
  }) {
    if (text.isEmpty) {
      final overhead = includeOverhead ? (_modelOverhead[model] ?? 0) : 0;
      return TokenEstimate(
        tokens: overhead,
        model: model,
        characterCount: 0,
        contentType: contentType ?? ContentType.general,
        avgCharsPerToken: 0,
      );
    }

    // Auto-detect content type if not provided
    contentType ??= _detectContentType(text);

    // Count character types
    final charStats = _analyzeCharacters(text);

    // Get model-specific divisor from research
    final divisor = _getModelDivisor(model, contentType, charStats);

    // Calculate tokens with improved accuracy
    final baseTokens = _calculateTokens(charStats, divisor, model);

    // Add overhead if requested
    final overhead = includeOverhead ? (_modelOverhead[model] ?? 0) : 0;
    final tokens = baseTokens + overhead;

    return TokenEstimate(
      tokens: tokens,
      model: model,
      characterCount: text.length,
      contentType: contentType,
      avgCharsPerToken: text.length / baseTokens,
    );
  }

  /// Batch estimates tokens for multiple texts
  Map<String, TokenEstimate> batchEstimateTokens(
    Map<String, String> texts, {
    required AIModel model,
    ContentType? contentType,
    bool includeOverhead = false,
  }) {
    return texts.map(
      (key, value) => MapEntry(
        key,
        estimateTokens(
          value,
          model: model,
          contentType: contentType,
          includeOverhead: includeOverhead,
        ),
      ),
    );
  }

  /// Checks if text is within model's token limit
  TokenLimitCheck checkTokenLimit(
    String text, {
    required AIModel model,
    ContentType? contentType,
    bool includeOverhead = true,
  }) {
    final estimate = estimateTokens(
      text,
      model: model,
      contentType: contentType,
      includeOverhead: includeOverhead,
    );
    final maxTokens = modelSpecs[model]!.contextWindow;
    final isWithinLimit = estimate.tokens <= maxTokens;
    final percentageUsed = (estimate.tokens / maxTokens) * 100;
    final tokensRemaining = maxTokens - estimate.tokens;

    return TokenLimitCheck(
      estimatedTokens: estimate.tokens,
      isWithinLimit: isWithinLimit,
      percentageUsed: percentageUsed,
      tokensRemaining: tokensRemaining.clamp(0, maxTokens),
      maxTokens: maxTokens,
      model: model,
    );
  }

  /// Truncates text to fit within a specified token limit
  String truncateToTokenLimit(
    String text, {
    required AIModel model,
    required int maxTokens,
    ContentType? contentType,
    String ellipsis = '...',
  }) {
    final estimate = estimateTokens(
      text,
      model: model,
      contentType: contentType,
      includeOverhead: false,
    );

    if (estimate.tokens <= maxTokens) {
      return text;
    }

    // Calculate target character count
    final ellipsisTokens = estimateTokens(
      ellipsis,
      model: model,
      contentType: contentType,
      includeOverhead: false,
    ).tokens;
    final adjustedMaxTokens = maxTokens - ellipsisTokens;
    final targetChars = (adjustedMaxTokens * estimate.avgCharsPerToken).floor();

    if (targetChars <= 0) {
      return ellipsis;
    }

    // Find a good break point
    var truncateAt = targetChars.clamp(0, text.length);

    // Try to break at word boundary
    for (var i = truncateAt; i > truncateAt - 20 && i > 0; i--) {
      if (text[i] == ' ' || text[i] == '\n') {
        truncateAt = i;
        break;
      }
    }

    return text.substring(0, truncateAt).trimRight() + ellipsis;
  }

  /// Splits text into chunks that fit within token limit
  List<String> splitIntoChunks(
    String text, {
    required AIModel model,
    required int maxTokensPerChunk,
    ContentType? contentType,
    int overlap = 50, // Token overlap between chunks
  }) {
    final chunks = <String>[];

    if (text.isEmpty) {
      return chunks;
    }

    var remaining = text;
    while (remaining.isNotEmpty) {
      final truncated = truncateToTokenLimit(
        remaining,
        model: model,
        maxTokens: maxTokensPerChunk,
        contentType: contentType,
        ellipsis: '',
      );

      chunks.add(truncated);

      // Calculate where to start next chunk (with overlap)
      if (truncated.length < remaining.length) {
        // Find overlap point
        final overlapChars = (overlap *
                _getModelDivisor(model, contentType ?? ContentType.general,
                    _analyzeCharacters(truncated)))
            .round();
        final startNext =
            (truncated.length - overlapChars).clamp(0, truncated.length);
        remaining = remaining.substring(startNext);
      } else {
        break;
      }
    }

    return chunks;
  }

  /// Analyzes character composition of text
  _CharacterStats _analyzeCharacters(String text) {
    int ascii = 0;
    int cjk = 0;
    int emoji = 0;
    int whitespace = 0;
    int punctuation = 0;
    int other = 0;
    int bytes = 0;

    // Count UTF-8 bytes for better non-ASCII estimation
    bytes = text.codeUnits.fold(0, (sum, unit) {
      if (unit <= 0x7F) {
        return sum + 1;
      }
      if (unit <= 0x7FF) {
        return sum + 2;
      }
      if (unit <= 0xFFFF) {
        return sum + 3;
      }
      return sum + 4;
    });

    for (final rune in text.runes) {
      if (rune <= 0x7F) {
        if (rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D) {
          whitespace++;
        } else if ((rune >= 0x21 && rune <= 0x2F) ||
            (rune >= 0x3A && rune <= 0x40) ||
            (rune >= 0x5B && rune <= 0x60) ||
            (rune >= 0x7B && rune <= 0x7E)) {
          punctuation++;
        } else {
          ascii++;
        }
      } else if (_isCJK(rune)) {
        cjk++;
      } else if (_isEmoji(rune)) {
        emoji++;
      } else {
        other++;
      }
    }

    return _CharacterStats(
      ascii: ascii,
      cjk: cjk,
      emoji: emoji,
      whitespace: whitespace,
      punctuation: punctuation,
      other: other,
      total: text.length,
      bytes: bytes,
    );
  }

  /// Detects content type based on text patterns
  ContentType _detectContentType(String text) {
    // Check for code patterns
    if (_looksLikeCode(text)) {
      return ContentType.code;
    }

    // Check for structured data patterns
    if (_looksLikeStructuredData(text)) {
      return ContentType.structured;
    }

    // Check for chat patterns
    if (_looksLikeChat(text)) {
      return ContentType.chat;
    }

    // Check for prose patterns
    if (_looksLikeProse(text)) {
      return ContentType.prose;
    }

    return ContentType.general;
  }

  bool _looksLikeCode(String text) {
    final codePatterns = [
      RegExp(r'^\s*(?:function|def|class|interface|struct|enum)\s+\w+'),
      RegExp(r'(?:if|for|while|switch)\s*\('),
      RegExp(r'[{};]\s*$', multiLine: true),
      RegExp(r'^\s*(?:import|include|require|using)\s+'),
      RegExp(r'(?:const|let|var|int|string|bool)\s+\w+\s*='),
    ];

    var matchCount = 0;
    for (final pattern in codePatterns) {
      if (pattern.hasMatch(text)) {
        matchCount++;
      }
    }

    return matchCount >= 2;
  }

  bool _looksLikeStructuredData(String text) {
    final trimmed = text.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']')) ||
        (trimmed.startsWith('<') && trimmed.endsWith('>')) ||
        text.contains('---\n') || // YAML
        text.split('\n').where((line) => line.contains(',')).length > 5; // CSV
  }

  bool _looksLikeChat(String text) {
    final lines = text.split('\n');
    final chatPatterns = [
      RegExp(r'^\s*(User|Assistant|Human|AI|System):\s*'),
      RegExp(r'^\s*(You|Me):\s*'),
      RegExp(r'^\s*\[.+\]:\s*'), // [timestamp] or [username]
    ];

    var chatLineCount = 0;
    for (final line in lines) {
      for (final pattern in chatPatterns) {
        if (pattern.hasMatch(line)) {
          chatLineCount++;
          break;
        }
      }
    }

    return chatLineCount >= 2;
  }

  bool _looksLikeProse(String text) {
    // Simple check: average word length and sentence patterns
    final words = text.split(RegExp(r'\s+'));
    if (words.length < 20) {
      return false;
    }

    final avgWordLength =
        text.replaceAll(RegExp(r'\s+'), '').length / words.length;
    final hasSentences = RegExp(r'[.!?]\s+[A-Z]').hasMatch(text);

    return avgWordLength >= 4 && avgWordLength <= 8 && hasSentences;
  }

  /// Gets model-specific character divisor from research
  double _getModelDivisor(
      AIModel model, ContentType contentType, _CharacterStats stats) {
    // Use research-backed divisor
    final divisor = _modelDivisors[(model, contentType)] ??
        _modelDivisors[(model, ContentType.general)] ??
        3.5; // Fallback

    // For high non-ASCII content, adjust based on byte-level tokenization
    // Research shows non-ASCII bytes often map 1:1 to tokens
    final nonAsciiRatio = (stats.cjk + stats.emoji + stats.other) / stats.total;
    if (nonAsciiRatio > 0.3) {
      // Heavy non-ASCII content - use byte count estimation
      return divisor * 0.7;
    }

    return divisor;
  }

  /// Calculates tokens with improved byte-level awareness
  int _calculateTokens(_CharacterStats stats, double divisor, AIModel model) {
    // ASCII characters divided by model-specific divisor
    final asciiTokens = stats.ascii / divisor;
    final whitespaceTokens = stats.whitespace / (divisor * 1.5);
    final punctuationTokens = stats.punctuation / (divisor * 0.8);

    // Non-ASCII: Research shows byte-level BPE tokenization
    // Most non-ASCII characters become 1 token per byte
    final nonAsciiBytes =
        stats.bytes - (stats.ascii + stats.whitespace + stats.punctuation);
    final nonAsciiTokens = nonAsciiBytes * 0.95; // Slight compression from BPE

    final totalTokens =
        asciiTokens + whitespaceTokens + punctuationTokens + nonAsciiTokens;

    return totalTokens.ceil();
  }

  bool _isCJK(int rune) {
    return (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK Unified Ideographs
        (rune >= 0x3040 && rune <= 0x309F) || // Hiragana
        (rune >= 0x30A0 && rune <= 0x30FF) || // Katakana
        (rune >= 0xAC00 && rune <= 0xD7AF); // Hangul
  }

  bool _isEmoji(int rune) {
    return (rune >= 0x1F300 && rune <= 0x1F9FF) || // Misc symbols & pictographs
        (rune >= 0x1F600 && rune <= 0x1F64F) || // Emoticons
        (rune >= 0x1F680 && rune <= 0x1F6FF) || // Transport & map
        (rune >= 0x2600 && rune <= 0x26FF); // Misc symbols
  }
}

/// Internal class for character statistics
class _CharacterStats {
  _CharacterStats({
    required this.ascii,
    required this.cjk,
    required this.emoji,
    required this.whitespace,
    required this.punctuation,
    required this.other,
    required this.total,
    required this.bytes,
  });

  final int ascii;
  final int cjk;
  final int emoji;
  final int whitespace;
  final int punctuation;
  final int other;
  final int total;
  final int bytes;
}
