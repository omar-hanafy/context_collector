import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

export 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// Extension on BuildContext to provide convenient theme color access
extension ThemeColorsExtension on BuildContext {
  // ColorScheme colors
  Color get primary => themeData.primary;

  Color get onPrimary => themeData.onPrimary;

  Color get primaryContainer => themeData.primaryContainer;

  Color get onPrimaryContainer => themeData.onPrimaryContainer;

  Color get secondary => themeData.secondary;

  Color get onSecondary => themeData.onSecondary;

  Color get secondaryContainer => themeData.secondaryContainer;

  Color get onSecondaryContainer => themeData.onSecondaryContainer;

  Color get tertiary => themeData.tertiary;

  Color get onTertiary => themeData.onTertiary;

  Color get tertiaryContainer => themeData.tertiaryContainer;

  Color get onTertiaryContainer => themeData.onTertiaryContainer;

  Color get error => themeData.error;

  Color get onError => themeData.onError;

  Color get errorContainer => themeData.errorContainer;

  Color get onErrorContainer => themeData.onErrorContainer;

  Color get background => themeData.surface;

  Color get onBackground => themeData.onSurface;

  Color get surface => themeData.surfaceContainerHighest;

  Color get surfaceContainerHighest => themeData.surfaceContainerHighest;

  Color get onSurface => themeData.onSurface;

  Color get onSurfaceVariant => themeData.onSurfaceVariant;

  Color get outline => themeData.outline;

  Color get outlineVariant => themeData.outlineVariant;

  Color get shadow => themeData.shadow;

  Color get scrim => themeData.scrim;

  Color get inverseSurface => themeData.inverseSurface;

  Color get onInverseSurface => themeData.onInverseSurface;

  Color get inversePrimary => themeData.inversePrimary;

  Color get surfaceTint => themeData.surfaceTint;

  TextTheme get textTheme => themeData.textTheme;
}

/// Extension on BuildContext to provide convenient text style access
extension TextStylesExtension on BuildContext {
  // Display styles
  TextStyle? get displayLarge => textTheme.displayLarge;

  TextStyle? get displayMedium => textTheme.displayMedium;

  TextStyle? get displaySmall => textTheme.displaySmall;

  // Headline styles
  TextStyle? get headlineLarge => textTheme.headlineLarge;

  TextStyle? get headlineMedium => textTheme.headlineMedium;

  TextStyle? get headlineSmall => textTheme.headlineSmall;

  // Title styles
  TextStyle? get titleLarge => textTheme.titleLarge;

  TextStyle? get titleMedium => textTheme.titleMedium;

  TextStyle? get titleSmall => textTheme.titleSmall;

  // Label styles
  TextStyle? get labelLarge => textTheme.labelLarge;

  TextStyle? get labelMedium => textTheme.labelMedium;

  TextStyle? get labelSmall => textTheme.labelSmall;

  // Body styles
  TextStyle? get bodyLarge => textTheme.bodyLarge;

  TextStyle? get bodyMedium => textTheme.bodyMedium;

  TextStyle? get bodySmall => textTheme.bodySmall;

  // Copy methods for convenience (mirrors the fhu pattern)
  TextStyle? displayLargeCopy({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) => displayLarge?.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle? titleMediumCopy({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) => titleMedium?.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle? bodyMediumCopy({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) => bodyMedium?.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle? labelSmallCopy({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) => labelSmall?.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );
}
