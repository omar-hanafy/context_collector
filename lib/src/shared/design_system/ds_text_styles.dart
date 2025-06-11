part of 'design_system.dart';

/// Text style utilities
extension DsTextStyles on BuildContext {
  // Common text style modifications
  TextStyle? withWeight(TextStyle? style, FontWeight weight) =>
      style?.copyWith(fontWeight: weight);

  TextStyle? withColor(TextStyle? style, Color color) =>
      style?.copyWith(color: color);

  TextStyle? withSize(TextStyle? style, double size) =>
      style?.copyWith(fontSize: size);

  // Pre-configured text styles
  TextStyle? get labelBold => withWeight(labelLarge, FontWeight.w600);
  TextStyle? get labelMuted => withColor(labelMedium, onSurfaceVariant);
  TextStyle? get bodyMuted =>
      withColor(bodyMedium, onSurfaceVariant.addOpacity(0.7));
  TextStyle? get titleBold => withWeight(titleMedium, FontWeight.w600);

  // Monospace text style
  TextStyle? monoStyle([double? size]) => TextStyle(
    fontFamily: 'monospace',
    fontSize: size ?? 14,
  );
}
