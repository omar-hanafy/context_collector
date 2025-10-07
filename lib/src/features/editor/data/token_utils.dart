import 'dart:developer';

import 'package:tiktoken/tiktoken.dart';

/// Formats large token counts using a compact friendly string.
String prettyTokens(int n, {bool includeUnit = true}) {
  final base = _formatCount(n);
  return includeUnit ? '$base tokens' : base;
}

/// Counts tokens for the provided [text] using the given [model] encoding.
int countTokens(String text, {String model = 'gpt2'}) {
  final encoding = _encodingForModel(model);
  return encoding.encode(text).length;
}

String _formatCount(int n) {
  if (n >= 1000000) {
    final millions = n / 1000000;
    final formatted = millions == millions.floorToDouble()
        ? millions.toInt().toString()
        : millions.toStringAsFixed(1);
    return '${formatted}m';
  }
  if (n >= 1000) {
    final thousands = n / 1000;
    final formatted = thousands == thousands.floorToDouble()
        ? thousands.toInt().toString()
        : thousands.toStringAsFixed(1);
    return '${formatted}k';
  }
  return n.toString();
}

final Map<String, Tiktoken> _encodingCache = {};

Tiktoken _encodingForModel(String model) {
  return _encodingCache.putIfAbsent(model, () {
    try {
      return encodingForModel(model);
    } catch (_) {
      log('Failed to fetch from $model encoding, falling back to o200k_base');
      for (final fallback in ['o200k_base, cl100k_base']) {
        try {
          return getEncoding(fallback);
        } catch (_) {
          continue;
        }
      }

      log(
        'Failed to fetch from o200k_base encoding, falling back to ${listEncodingNames().first}',
      );
      return getEncoding(listEncodingNames().first);
    }
  });
}
