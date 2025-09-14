import 'package:flutter/material.dart';

extension UiSnackbars on BuildContext {
  void showOk(String message, {Duration? duration}) {
    final cs = Theme.of(this).colorScheme;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: cs.onPrimary, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: cs.primary,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void showErr(String message, {Duration? duration}) {
    final cs = Theme.of(this).colorScheme;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void showInfo(String message, {Duration? duration}) {
    final cs = Theme.of(this).colorScheme;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cs.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

extension NumFormat on num {
  /// Format number in compact form (1.2k, 3.4M, etc).
  String compact() {
    final n = this;
    if (n < 1000) return n.toString();
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(0)}k';
    if (n < 10000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    return '${(n / 1000000).toStringAsFixed(0)}M';
  }
}
