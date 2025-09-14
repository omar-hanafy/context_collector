import 'models.dart';

/// Multi-model AI token calculator for estimating token counts.
///
/// Production goals:
/// - Single O(n) scan, Unicode-safe (rune-based) processing
/// - YAGNI-friendly: default to average estimation; per-model optional
class AITokenCalculator {
  // Precompiled regexes to avoid reallocation on hot paths
  static final List<RegExp> _codeRegexes = <RegExp>[
    RegExp(r'^\s*(?:function|def|class|interface|struct|enum)\s+\w+', multiLine: true),
    RegExp(r'(?:if|for|while|switch)\s*\('),
    RegExp(r'[{};]\s*$', multiLine: true),
    RegExp(r'^\s*(?:import|include|require|using)\s+\w+', multiLine: true),
    RegExp(r'(?:const|let|var|int|string|bool)\s+\w+\s*=', multiLine: true),
  ];

  static final RegExp _yamlHeaderRegex = RegExp(r'^---\r?\n', multiLine: true);

  static final List<RegExp> _chatRegexes = <RegExp>[
    RegExp(r'^\s*(User|Assistant|Human|AI|System):\s*'),
    RegExp(r'^\s*(You|Me):\s*'),
    RegExp(r'^\s*\[[^\]]+\]:\s*'),
  ];
  /// Model specifications with context windows and display names.
  static const Map<AIModel, ModelLimits> modelSpecs = {
    // Claude models
    AIModel.claudeOpus: ModelLimits(
      model: AIModel.claudeOpus,
      contextWindow: 200000, // 200K tokens
      displayName: 'Claude Opus',
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
      contextWindow: 16385, // ~16K tokens
      displayName: 'GPT-3.5 Turbo',
    ),

    // Google models
    AIModel.geminiPro: ModelLimits(
      model: AIModel.geminiPro,
      contextWindow: 1000000, // ~1M tokens (approx)
      displayName: 'Gemini Pro',
    ),
    AIModel.gemini15Pro: ModelLimits(
      model: AIModel.gemini15Pro,
      contextWindow: 1000000, // ~1M tokens (approx)
      displayName: 'Gemini 1.5 Pro',
    ),
    AIModel.gemini15Flash: ModelLimits(
      model: AIModel.gemini15Flash,
      contextWindow: 1000000, // ~1M tokens (approx)
      displayName: 'Gemini 1.5 Flash',
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

  /// Average (model-agnostic) divisors by content type (runes per token).
  static const Map<ContentType, double> _universalDivisors = {
    ContentType.general: 3.71,
    ContentType.prose: 3.90,
    ContentType.code: 2.72,
    ContentType.structured: 3.00,
    ContentType.chat: 3.58,
  };

  /// Per-model divisors (runes per token).
  static const Map<(AIModel, ContentType), double> _modelDivisors = {
    // Claude
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

    // OpenAI
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
    (AIModel.gpt35Turbo, ContentType.general): 4.0,
    (AIModel.gpt35Turbo, ContentType.prose): 4.2,
    (AIModel.gpt35Turbo, ContentType.code): 3.0,
    (AIModel.gpt35Turbo, ContentType.structured): 3.2,
    (AIModel.gpt35Turbo, ContentType.chat): 3.8,

    // Google (Gemini)
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

    // xAI Grok
    (AIModel.grok, ContentType.general): 3.5,
    (AIModel.grok, ContentType.prose): 3.6,
    (AIModel.grok, ContentType.code): 2.6,
    (AIModel.grok, ContentType.structured): 2.9,
    (AIModel.grok, ContentType.chat): 3.4,

    // Mistral
    (AIModel.mistral, ContentType.general): 3.4,
    (AIModel.mistral, ContentType.prose): 3.6,
    (AIModel.mistral, ContentType.code): 2.6,
    (AIModel.mistral, ContentType.structured): 2.9,
    (AIModel.mistral, ContentType.chat): 3.3,

    // Llama
    (AIModel.llama, ContentType.general): 3.7,
    (AIModel.llama, ContentType.prose): 3.9,
    (AIModel.llama, ContentType.code): 2.8,
    (AIModel.llama, ContentType.structured): 3.1,
    (AIModel.llama, ContentType.chat): 3.5,
  };

  /// Overhead tokens for each model (system/formatting tokens).
  static const Map<AIModel, int> _modelOverhead = {
    AIModel.claudeOpus: 3,
    AIModel.claudeSonnet: 3,
    AIModel.claudeHaiku: 3,
    AIModel.gpt4: 3,
    AIModel.gpt4Turbo: 3,
    AIModel.gpt35Turbo: 3,
    AIModel.geminiPro: 2,
    AIModel.gemini15Pro: 2,
    AIModel.gemini15Flash: 2,
    AIModel.grok: 3,
    AIModel.mistral: 2,
    AIModel.llama: 2,
  };

  /// Estimates token count for a given text.
  TokenEstimate estimateTokens(
    String text, {
    required AIModel model,
    ContentType? contentType,
    EstimationStrategy strategy = EstimationStrategy.average,
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

    contentType ??= _detectContentType(text);
    final stats = _analyzeCharacters(text);
    final divisor = _getDivisor(model, contentType, strategy);
    final baseTokens = _calculateTokens(stats, divisor);
    final overhead = includeOverhead ? (_modelOverhead[model] ?? 0) : 0;
    final tokens = baseTokens + overhead;

    return TokenEstimate(
      tokens: tokens,
      model: model,
      characterCount: stats.runes,
      contentType: contentType,
      avgCharsPerToken: stats.runes / baseTokens,
    );
  }

  /// Batch estimates tokens for multiple texts.
  Map<String, TokenEstimate> batchEstimateTokens(
    Map<String, String> texts, {
    required AIModel model,
    ContentType? contentType,
    EstimationStrategy strategy = EstimationStrategy.average,
    bool includeOverhead = false,
  }) {
    return texts.map(
      (key, value) => MapEntry(
        key,
        estimateTokens(
          value,
          model: model,
          contentType: contentType,
          strategy: strategy,
          includeOverhead: includeOverhead,
        ),
      ),
    );
  }

  /// Checks if text is within model's token limit.
  TokenLimitCheck checkTokenLimit(
    String text, {
    required AIModel model,
    ContentType? contentType,
    EstimationStrategy strategy = EstimationStrategy.average,
    bool includeOverhead = true,
  }) {
    final estimate = estimateTokens(
      text,
      model: model,
      contentType: contentType,
      strategy: strategy,
      includeOverhead: includeOverhead,
    );
    final maxTokens = modelSpecs[model]!.contextWindow;
    final isWithinLimit = estimate.tokens <= maxTokens;
    final percentageUsed = (estimate.tokens / maxTokens) * 100;
    final tokensRemaining = (maxTokens - estimate.tokens).clamp(0, maxTokens).toInt();

    return TokenLimitCheck(
      estimatedTokens: estimate.tokens,
      isWithinLimit: isWithinLimit,
      percentageUsed: percentageUsed,
      tokensRemaining: tokensRemaining,
      maxTokens: maxTokens,
      model: model,
    );
  }

  /// Truncates text to fit within a specified token limit (Unicode-safe).
  String truncateToTokenLimit(
    String text, {
    required AIModel model,
    required int maxTokens,
    ContentType? contentType,
    EstimationStrategy strategy = EstimationStrategy.average,
    String ellipsis = '...',
  }) {
    final estimate = estimateTokens(
      text,
      model: model,
      contentType: contentType,
      strategy: strategy,
      includeOverhead: false,
    );

    if (estimate.tokens <= maxTokens) {
      return text;
    }

    final ellipsisTokens = estimateTokens(
      ellipsis,
      model: model,
      contentType: contentType,
      strategy: strategy,
      includeOverhead: false,
    ).tokens;
    final adjustedMaxTokens = maxTokens - ellipsisTokens;
    if (adjustedMaxTokens <= 0) return ellipsis;

    final targetRunes = (adjustedMaxTokens * estimate.avgCharsPerToken)
        .floor()
        .clamp(0, estimate.characterCount)
        .toInt();
    if (targetRunes <= 0) return ellipsis;

    final runes = text.runes.toList(growable: false);
    int cut = targetRunes.clamp(0, runes.length).toInt();
    for (var i = cut; i > cut - 32 && i > 0; i--) {
      final r = runes[i - 1];
      if (r == 0x20 || r == 0x0A || r == 0x0009) {
        cut = i;
        break;
      }
    }

    final truncated = String.fromCharCodes(runes.take(cut)).trimRight();
    return truncated + ellipsis;
  }

  /// Splits text into chunks that fit within token limit (Unicode-safe).
  List<String> splitIntoChunks(
    String text, {
    required AIModel model,
    required int maxTokensPerChunk,
    ContentType? contentType,
    EstimationStrategy strategy = EstimationStrategy.average,
    int overlap = 50, // token overlap
  }) {
    final chunks = <String>[];
    if (text.isEmpty) return chunks;
    if (maxTokensPerChunk <= 0) {
      // Defensive: no forward progress possible; return as a single chunk
      chunks.add(text);
      return chunks;
    }

    var remaining = text;
    while (remaining.isNotEmpty) {
      final truncated = truncateToTokenLimit(
        remaining,
        model: model,
        maxTokens: maxTokensPerChunk,
        contentType: contentType,
        strategy: strategy,
        ellipsis: '',
      );

      chunks.add(truncated);

      if (truncated.length < remaining.length) {
        final lastEstimate = estimateTokens(
          truncated,
          model: model,
          contentType: contentType,
          strategy: strategy,
          includeOverhead: false,
        );

        final overlapRunes = (overlap * lastEstimate.avgCharsPerToken)
            .round()
            .clamp(0, truncated.runes.length)
            .toInt();

        final remRunes = remaining.runes.toList(growable: false);
        final startNext = (truncated.runes.length - overlapRunes)
            .clamp(0, truncated.runes.length)
            .toInt();
        remaining = String.fromCharCodes(remRunes.sublist(startNext));
      } else {
        break;
      }
    }

    return chunks;
  }

  // -----------------------------
  // Internals
  // -----------------------------

  /// Analyzes character composition of text in a single pass (rune-based).
  _CharacterStats _analyzeCharacters(String text) {
    int ascii = 0;
    int cjk = 0;
    int emoji = 0;
    int whitespace = 0;
    int punctuation = 0;
    int other = 0;
    int runes = 0;
    int controls = 0; // zero-width joiners / variation selectors

    for (final r in text.runes) {
      runes++;

      // Treat joiners/variation selectors as zero-cost signals
      if (r == 0x200D || // ZWJ
          r == 0x200C || // ZWNJ
          r == 0xFE0F || // VS-16
          r == 0xFE0E) { // VS-15
        controls++;
        continue; // don't classify further
      }

      if (r <= 0x7F) {
        if (r == 0x20 || r == 0x09 || r == 0x0A || r == 0x0D) {
          whitespace++;
        } else if ((r >= 0x21 && r <= 0x2F) ||
            (r >= 0x3A && r <= 0x40) ||
            (r >= 0x5B && r <= 0x60) ||
            (r >= 0x7B && r <= 0x7E)) {
          punctuation++;
        } else {
          ascii++;
        }
      } else if (_isCJK(r)) {
        cjk++;
      } else if (_isEmoji(r)) {
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
      runes: runes,
      controls: controls,
    );
  }

  /// Detects content type based on simple patterns.
  ContentType _detectContentType(String text) {
    if (_looksLikeCode(text)) return ContentType.code;
    if (_looksLikeStructuredData(text)) return ContentType.structured;
    if (_looksLikeChat(text)) return ContentType.chat;
    if (_looksLikeProse(text)) return ContentType.prose;
    return ContentType.general;
  }

  bool _looksLikeCode(String text) {
    var matchCount = 0;
    for (final pattern in _codeRegexes) {
      if (pattern.hasMatch(text)) matchCount++;
    }
    return matchCount >= 2;
  }

  bool _looksLikeStructuredData(String text) {
    final trimmed = text.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']')) ||
        (trimmed.startsWith('<') && trimmed.endsWith('>')) ||
        _yamlHeaderRegex.hasMatch(text)) {
      return true;
    }
    final lines = text.split('\n');
    return lines.where((line) => line.contains(',')).length > 5; // CSV-ish
  }

  bool _looksLikeChat(String text) {
    final lines = text.split('\n');
    var chatLineCount = 0;
    for (final line in lines) {
      for (final pattern in _chatRegexes) {
        if (pattern.hasMatch(line)) {
          chatLineCount++;
          break;
        }
      }
    }
    return chatLineCount >= 2;
  }

  bool _looksLikeProse(String text) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length < 20) return false;
    final noWs = text.replaceAll(RegExp(r'\s+'), '');
    final avgWordLength = noWs.isEmpty ? 0 : noWs.length / words.length;
    final hasSentences = RegExp(r'[.!?]\s+[A-Z]').hasMatch(text);
    return avgWordLength >= 4 && avgWordLength <= 8 && hasSentences;
  }

  /// Choose divisor based on strategy.
  double _getDivisor(AIModel model, ContentType type, EstimationStrategy strategy) {
    if (strategy == EstimationStrategy.perModel) {
      return _modelDivisors[(model, type)] ??
          _modelDivisors[(model, ContentType.general)] ??
          _universalDivisors[ContentType.general]!;
    }
    return _universalDivisors[type] ?? _universalDivisors[ContentType.general]!;
  }

  /// Calculate tokens using language-aware buckets.
  int _calculateTokens(_CharacterStats s, double divisor) {
    final asciiTokens = s.ascii / divisor;
    final whitespaceTokens = s.whitespace / (divisor * 1.7);
    final punctuationTokens = s.punctuation / (divisor * 0.9);

    final cjkTokens = s.cjk * 1.0;
    final emojiTokens = s.emoji * 2.0;
    final otherTokens = s.other * 1.2;

    final total = asciiTokens +
        whitespaceTokens +
        punctuationTokens +
        cjkTokens +
        emojiTokens +
        otherTokens;

    return total <= 1 ? 1 : total.ceil();
  }

  bool _isCJK(int r) {
    return (r >= 0x4E00 && r <= 0x9FFF) || // CJK Unified Ideographs
        (r >= 0x3400 && r <= 0x4DBF) || // CJK Extension A
        (r >= 0x20000 && r <= 0x2EBEF) || // CJK Extensions B–F (combined approx)
        (r >= 0x3040 && r <= 0x309F) || // Hiragana
        (r >= 0x30A0 && r <= 0x30FF) || // Katakana
        (r >= 0xF900 && r <= 0xFAFF) || // Compatibility Ideographs
        (r >= 0xAC00 && r <= 0xD7AF) || // Hangul syllables
        (r >= 0xFF00 && r <= 0xFFEF); // Halfwidth/Fullwidth forms
  }

  bool _isEmoji(int r) {
    return (r >= 0x1F300 && r <= 0x1FAFF) ||
        (r >= 0x1F600 && r <= 0x1F64F) ||
        (r >= 0x1F680 && r <= 0x1F6FF) ||
        (r >= 0x2600 && r <= 0x26FF) ||
        (r >= 0x2700 && r <= 0x27BF);
  }
}

/// Internal class for character statistics (rune-based)
class _CharacterStats {
  _CharacterStats({
    required this.ascii,
    required this.cjk,
    required this.emoji,
    required this.whitespace,
    required this.punctuation,
    required this.other,
    required this.runes,
    required this.controls,
  });

  final int ascii;
  final int cjk;
  final int emoji;
  final int whitespace;
  final int punctuation;
  final int other;
  final int runes;
  final int controls;
}
