part of 'design_system.dart';

/// Main Design System extension on BuildContext
extension DesignSystemExtension on BuildContext {
  DesignSystemTheme get ds => DesignSystemTheme._(this);
}

/// Design System theme access
class DesignSystemTheme {
  const DesignSystemTheme._(this._context);
  final BuildContext _context;

  // Borders
  Border get borderDefault => Border.all(color: _context.borderColor);
  Border get borderPrimary => Border.all(color: _context.primary);
  Border get borderError => Border.all(color: _context.error);

  BorderRadius get radiusSmall =>
      BorderRadius.circular(DesignSystem.radiusSmall);
  BorderRadius get radiusMedium =>
      BorderRadius.circular(DesignSystem.radiusMedium);
  BorderRadius get radiusLarge =>
      BorderRadius.circular(DesignSystem.radiusLarge);
  BorderRadius get radiusXLarge =>
      BorderRadius.circular(DesignSystem.radiusXLarge);

  // Box Decorations
  BoxDecoration get cardDecoration => BoxDecoration(
    color: _context.surface,
    borderRadius: radiusMedium,
    border: borderDefault,
  );

  BoxDecoration get containerDecoration => BoxDecoration(
    color: _context.surfaceContainerHighest,
    borderRadius: radiusLarge,
    border: borderDefault,
  );

  BoxDecoration get primaryContainerDecoration => BoxDecoration(
    color: _context.primaryOverlay,
    borderRadius: radiusMedium,
    border: Border.all(color: _context.primary.addOpacity(0.3)),
  );

  BoxDecoration get errorContainerDecoration => BoxDecoration(
    color: _context.errorOverlay,
    borderRadius: radiusMedium,
    border: Border.all(color: _context.error.addOpacity(0.3)),
  );

  // Shadows
  List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: _context.shadow.addOpacity(0.05),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: _context.shadow.addOpacity(0.1),
      offset: const Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: _context.shadow.addOpacity(0.15),
      offset: const Offset(0, 8),
      blurRadius: 16,
    ),
  ];

  // Spacing helpers
  SizedBox get spaceSmall =>
      const SizedBox(height: DesignSystem.space8, width: DesignSystem.space8);
  SizedBox get spaceMedium =>
      const SizedBox(height: DesignSystem.space16, width: DesignSystem.space16);
  SizedBox get spaceLarge =>
      const SizedBox(height: DesignSystem.space24, width: DesignSystem.space24);

  SizedBox spaceHeight(double height) => SizedBox(height: height);
  SizedBox spaceWidth(double width) => SizedBox(width: width);

  // Common widget styles
  ButtonStyle get textButtonStyle => TextButton.styleFrom(
    splashFactory: NoSplash.splashFactory,
    overlayColor: Colors.transparent,
    foregroundColor: _context.primary,
  );

  ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    side: BorderSide(color: _context.primary),
    splashFactory: NoSplash.splashFactory,
  );

  ButtonStyle get filledButtonStyle => FilledButton.styleFrom(
    splashFactory: NoSplash.splashFactory,
  );

  // Icon button style helper
  ButtonStyle iconButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
  }) => IconButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    highlightColor: Colors.transparent,
  );
}
