# Changelog

## 2.1.0

### Improvements
- Implemented research-backed divisors for each model based on official documentation
- Improved accuracy to ±5% for code and ±8% for prose
- Added byte-level tokenization awareness for non-ASCII characters
- Added model-specific overhead tokens (+3 for Claude/GPT, +2 for others)
- Enhanced confidence scores based on real error margins
- Better handling of UTF-8 byte counting for improved non-ASCII estimation

### New Features
- Added `includeOverhead` parameter to account for system/formatting tokens
- Research-based divisors for all content types per model

## 2.0.0

### Breaking Changes
- Complete rewrite to support multiple AI models
- Removed API-based token counting
- Renamed main class from `TokenCalculator` to `AITokenCalculator`
- Changed method signatures to require `model` parameter

### New Features
- Support for 12+ AI models including Claude, GPT, Gemini, Grok, Mistral, and Llama
- Automatic content type detection (code, prose, chat, structured data)
- Model-specific tokenization rules for better accuracy
- Text chunking with configurable overlap
- No external dependencies - pure Dart implementation
- Improved accuracy for non-ASCII characters (CJK, emoji)

### Improvements
- Faster performance (no network calls)
- Better handling of different character types
- More accurate estimates based on content type
- Comprehensive model context window information

## 1.0.0

- Initial release with Claude token counting
- API-based accurate counting
- Local estimation fallback
