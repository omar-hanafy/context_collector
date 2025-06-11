part of 'design_system.dart';

/// Common dimension configurations
class DsDimensions {
  const DsDimensions._();

  // Button dimensions
  static const buttonHeightSmall = 32.0;
  static const buttonHeightMedium = 40.0;
  static const buttonHeightLarge = 48.0;

  // Input field dimensions
  static const inputHeightSmall = 36.0;
  static const inputHeightMedium = 44.0;
  static const inputHeightLarge = 52.0;

  // Common paddings
  static const paddingSmall = EdgeInsets.all(8);
  static const paddingMedium = EdgeInsets.all(16);
  static const paddingLarge = EdgeInsets.all(24);

  static const paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: 8);
  static const paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: 16);
  static const paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: 24);

  static const paddingVerticalSmall = EdgeInsets.symmetric(vertical: 8);
  static const paddingVerticalMedium = EdgeInsets.symmetric(vertical: 16);
  static const paddingVerticalLarge = EdgeInsets.symmetric(vertical: 24);

  // List item paddings
  static const listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const listItemPaddingCompact = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  // Dialog dimensions
  static const dialogWidth = 900.0;
  static const dialogHeight = 700.0;
  static const dialogPadding = EdgeInsets.all(24);

  // Sidebar dimensions
  static const sidebarWidth = 280.0;
  static const sidebarPadding = EdgeInsets.all(16);
}
