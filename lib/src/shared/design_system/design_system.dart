/// Design System for Context Collector
/// Centralizes all design tokens and common UI patterns
library design_system;

import 'package:context_collector/context_collector.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter/material.dart';

part 'ds_colors.dart';
part 'ds_dimensions.dart';
part 'ds_extensions.dart';
part 'ds_helpers.dart';
part 'ds_text_styles.dart';
part 'ds_widgets.dart';

/// Design System configuration
class DesignSystem {
  const DesignSystem._();

  // Border Radii
  static const radiusSmall = 4.0;
  static const radiusMedium = 8.0;
  static const radiusLarge = 12.0;
  static const radiusXLarge = 16.0;

  // Spacing
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;

  // Icon Sizes
  static const iconSizeSmall = 16.0;
  static const iconSizeMedium = 20.0;
  static const iconSizeLarge = 24.0;
  static const iconSizeXLarge = 28.0;

  // Common Durations
  static const durationFast = Duration(milliseconds: 200);
  static const durationMedium = Duration(milliseconds: 300);
  static const durationSlow = Duration(milliseconds: 500);

  // Opacity values
  static const opacityDisabled = 0.38;
  static const opacityHover = 0.04;
  static const opacityPressed = 0.12;
  static const opacityOverlay = 0.8;
  static const opacityBorder = 0.2;
}
