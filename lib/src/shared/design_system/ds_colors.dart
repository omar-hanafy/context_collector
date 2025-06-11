part of 'design_system.dart';

/// Design System color utilities
extension DsColors on BuildContext {
  // Quick color helpers with opacity
  Color withOpacity(Color color, double opacity) => color.addOpacity(opacity);

  Color get hoverColor => onSurface.addOpacity(DesignSystem.opacityHover);
  Color get pressedColor => onSurface.addOpacity(DesignSystem.opacityPressed);
  Color get borderColor => onSurface.addOpacity(DesignSystem.opacityBorder);
  Color get disabledColor => onSurface.addOpacity(DesignSystem.opacityDisabled);

  // Common overlay colors
  Color get primaryOverlay => primary.addOpacity(0.1);
  Color get errorOverlay => error.addOpacity(0.1);
  Color get successOverlay => Colors.green.addOpacity(0.1);
}
