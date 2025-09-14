import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// Neutral slate accent (not green)
const Color kBrandSeed = Color(0xFF6B7280);

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.focusRing,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color focusRing;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? focusRing,
  }) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
    focusRing: focusRing ?? this.focusRing,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
    );
  }
}

class IosSwitchAdaptation extends Adaptation<SwitchThemeData> {
  const IosSwitchAdaptation();

  @override
  SwitchThemeData adapt(ThemeData theme, SwitchThemeData defaultValue) {
    if (theme.platform != TargetPlatform.iOS) return defaultValue;
    final s = theme.colorScheme;
    return defaultValue.copyWith(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return s.onSurface.setOpacity(0.38);
        }
        if (states.contains(WidgetState.selected)) return s.onPrimary;
        return s.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return s.onSurface.setOpacity(0.12);
        }
        if (states.contains(WidgetState.selected)) return s.primary;
        return s.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return s.outlineVariant;
      }),
      trackOutlineWidth: const WidgetStatePropertyAll(1),
      splashRadius: 20,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(
    ColorScheme.fromSeed(
      seedColor: kBrandSeed,
      brightness: Brightness.light,
    ).copyWith(
      // Clean white canvas (ChatGPT-like light)
      surface: const Color(0xFFF7F7F8),
      surfaceContainerHighest: const Color(0xFFECEDEF),
      outlineVariant: const Color(0xFFE1E3E6),
    ),
    Brightness.light,
  );

  static ThemeData get darkTheme => _build(
    ColorScheme.fromSeed(
      seedColor: kBrandSeed,
      brightness: Brightness.dark,
    ).copyWith(
      // Layered grays (ChatGPT-like dark)
      surface: const Color(0xFF0E1217),
      surfaceContainerHighest: const Color(0xFF171C22),
      outlineVariant: const Color(0xFF2A3139),
    ),
    Brightness.dark,
  );

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final status = AppColors(
      success: isDark ? const Color(0xFF5BD69E) : const Color(0xFF0F9D58),
      onSuccess: isDark ? const Color(0xFF003824) : Colors.white,
      warning: isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00),
      onWarning: isDark ? const Color(0xFF3B2200) : Colors.white,
      info: isDark ? const Color(0xFF7AB8FF) : const Color(0xFF1E88E5),
      onInfo: isDark ? const Color(0xFF001E3A) : Colors.white,
      focusRing: scheme.primary.setOpacity(0.30),
    );

    // Neutral fade overlay: no ripple, just opacity on press/hover.
    final neutralOverlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return scheme.onSurface.setOpacity(0.10);
      }
      if (states.contains(WidgetState.hovered)) {
        return scheme.onSurface.setOpacity(0.06);
      }
      if (states.contains(WidgetState.focused)) {
        // ring handled via focusColor; keep overlay neutral/transparent
        return Colors.transparent;
      }
      return Colors.transparent;
    });

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      visualDensity: VisualDensity.defaultDensityForPlatform(
        defaultTargetPlatform,
      ),
      adaptations: const [IosSwitchAdaptation()],
      extensions: [status],
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      applyElevationOverlayColor: false,

      // 🔕 Remove ripple globally; rely on overlayColor fades instead.
      splashFactory: NoSplash.splashFactory,
    );

    WidgetStateProperty<Color?> selectedDisabledElse({
      required Color selected,
      required Color disabled,
      required Color otherwise,
    }) => WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return disabled;
      if (states.contains(WidgetState.selected)) return selected;
      return otherwise;
    });

    final appBarTheme = AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      toolbarHeight: 40,
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    );

    final inputTheme = const InputDecorationTheme().copyWith(
      isDense: false,
      filled: true,
      fillColor: isDark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerHighest,
      iconColor: scheme.onSurfaceVariant,
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
      helperStyle: TextStyle(color: scheme.onSurfaceVariant),
      errorStyle: TextStyle(color: scheme.error),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    );

    final elevatedButtons = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // Avoid infinite width in unconstrained (Row) contexts.
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        foregroundColor: scheme.onPrimary,
        backgroundColor: scheme.primary,
        disabledBackgroundColor: scheme.onSurface.setOpacity(0.12),
        disabledForegroundColor: scheme.onSurface.setOpacity(0.38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).copyWith(overlayColor: neutralOverlay),
    );

    final filledButtons = FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Avoid infinite width in unconstrained (Row) contexts.
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        foregroundColor: scheme.onSecondaryContainer,
        backgroundColor: scheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).copyWith(overlayColor: neutralOverlay),
    );

    final outlinedButtons = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        // Avoid infinite width in unconstrained (Row) contexts.
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).copyWith(overlayColor: neutralOverlay),
    );

    final textButtons = TextButtonThemeData(
      style: TextButton.styleFrom(
        // Avoid infinite width in unconstrained (Row) contexts.
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).copyWith(overlayColor: neutralOverlay),
    );

    final iconButtons = IconButtonThemeData(
      style:
          IconButton.styleFrom(
            padding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ).copyWith(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return scheme.onSurface.setOpacity(0.38);
              }
              if (states.contains(WidgetState.pressed)) {
                return scheme.onSurface; // keep icon color neutral on press
              }
              return scheme.onSurface;
            }),
            overlayColor: neutralOverlay,
          ),
    );

    final checkboxTheme = CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: scheme.outline),
      fillColor: selectedDisabledElse(
        selected: scheme.primary,
        disabled: scheme.onSurface.setOpacity(0.12),
        otherwise: Colors.transparent,
      ),
      checkColor: selectedDisabledElse(
        selected: scheme.onPrimary,
        disabled: scheme.onSurface.setOpacity(0.38),
        otherwise: scheme.onSurface,
      ),
      visualDensity: VisualDensity.standard,
    );

    final radioTheme = RadioThemeData(
      fillColor: selectedDisabledElse(
        selected: scheme.primary,
        disabled: scheme.onSurface.setOpacity(0.38),
        otherwise: scheme.onSurfaceVariant,
      ),
      // overlay for radios is handled through InkWellTheme (neutralOverlay)
      visualDensity: VisualDensity.standard,
    );

    final switchTheme = SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.setOpacity(0.38);
        }
        if (states.contains(WidgetState.selected)) return scheme.onPrimary;
        return scheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.setOpacity(0.12);
        }
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return scheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return scheme.outlineVariant;
      }),
      trackOutlineWidth: const WidgetStatePropertyAll(1),
    );

    final chipTheme = ChipThemeData(
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: TextStyle(color: scheme.onSurface),
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.secondaryContainer,
      disabledColor: scheme.onSurface.setOpacity(0.12),
      secondarySelectedColor: scheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );

    final cardTheme = CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );

    final dialogTheme = DialogThemeData(
      elevation: 8,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
    );

    final snackBarTheme = SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      backgroundColor: isDark
          ? scheme.surfaceContainerHigh
          : scheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: isDark ? scheme.onSurface : scheme.onInverseSurface,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: isDark ? scheme.primary : scheme.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final dividerTheme = DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 0,
    );

    final tooltipTheme = TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      textStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(milliseconds: 2800),
    );

    final progressTheme = ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: scheme.surfaceContainerHighest,
    );

    const scrollbarTheme = ScrollbarThemeData(
      thumbVisibility: WidgetStatePropertyAll(true),
      thickness: WidgetStatePropertyAll(6),
      radius: Radius.circular(8),
    );

    return base.copyWith(
      appBarTheme: appBarTheme,
      inputDecorationTheme: inputTheme,
      elevatedButtonTheme: elevatedButtons,
      filledButtonTheme: filledButtons,
      outlinedButtonTheme: outlinedButtons,
      textButtonTheme: textButtons,
      iconButtonTheme: iconButtons,
      checkboxTheme: checkboxTheme,
      radioTheme: radioTheme,
      switchTheme: switchTheme,
      chipTheme: chipTheme,
      cardTheme: cardTheme,
      dialogTheme: dialogTheme,
      snackBarTheme: snackBarTheme,
      dividerTheme: dividerTheme,
      tooltipTheme: tooltipTheme,
      progressIndicatorTheme: progressTheme,
      scrollbarTheme: scrollbarTheme,

      // Keep hover neutral and focus ring; remove legacy ripple colors.
      hoverColor: scheme.onSurface.setOpacity(0.04),
      focusColor: status.focusRing,
      splashColor: Colors.transparent,
      // Subtle pressed feedback for generic InkWell users
      highlightColor: scheme.onSurface.setOpacity(0.06),
    );
  }
}
