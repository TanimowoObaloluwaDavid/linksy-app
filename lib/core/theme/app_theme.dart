import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_typography.dart';
import 'tokens.dart';

/// Light and dark themes for Linksy.
///
/// Both themes are authored explicitly rather than derived by inversion —
/// dark surfaces get their own tuned tones because simply flipping light
/// values produces crushed greys and dead borders.
abstract final class AppTheme {
  static const _brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.violet, AppColors.violetDeep],
  );

  // ---------------------------------------------------------------- DARK
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.violet,
      onPrimary: Colors.white,
      primaryContainer: AppColors.violetDeep,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.cyan,
      onSecondary: Color(0xFF04222E),
      secondaryContainer: AppColors.cyanDeep,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.success,
      onTertiary: Color(0xFF04281A),
      error: AppColors.error,
      onError: Color(0xFF2B0A0A),
      surface: AppColors.canvas,
      onSurface: AppColors.text,
      surfaceContainerLowest: AppColors.canvas,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceRaised,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigh,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.hairlineStrong,
      outlineVariant: AppColors.hairline,
    );

    return _base(
      scheme: scheme,
      scaffold: AppColors.canvas,
      fieldFill: AppColors.surfaceRaised,
      onField: AppColors.text,
      hint: AppColors.textFaint,
      brightText: Colors.white,
    );
  }

  // --------------------------------------------------------------- LIGHT
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.violetInk,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE7E1FF),
      onPrimaryContainer: Color(0xFF1E1259),
      secondary: AppColors.cyanDeep,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD6F3FE),
      onSecondaryContainer: Color(0xFF04252F),
      tertiary: AppColors.successInk,
      onTertiary: Colors.white,
      error: AppColors.errorInk,
      onError: Colors.white,
      surface: AppColors.canvasLight,
      onSurface: AppColors.textInk,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.surfaceLight,
      surfaceContainer: AppColors.surfaceRaisedLight,
      surfaceContainerHigh: AppColors.surfaceHighLight,
      surfaceContainerHighest: AppColors.surfaceHighLight,
      onSurfaceVariant: AppColors.textMutedInk,
      outline: AppColors.hairlineStrongLight,
      outlineVariant: AppColors.hairlineLight,
    );

    return _base(
      scheme: scheme,
      scaffold: AppColors.canvasLight,
      fieldFill: Colors.white,
      onField: AppColors.textInk,
      hint: AppColors.textFaintInk,
      brightText: Colors.white,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color fieldFill,
    required Color onField,
    required Color hint,
    required Color brightText,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final border = isDark ? AppColors.hairline : AppColors.hairlineLight;
    final borderStrong =
        isDark ? AppColors.hairlineStrong : AppColors.hairlineStrongLight;

    final textTheme = TextTheme(
      displayLarge: AppType.hero.copyWith(color: scheme.onSurface),
      headlineLarge: AppType.title.copyWith(color: scheme.onSurface),
      headlineMedium: AppType.heading.copyWith(color: scheme.onSurface),
      titleLarge: AppType.subheading.copyWith(color: scheme.onSurface),
      titleMedium: AppType.bodyStrong.copyWith(color: scheme.onSurface),
      bodyLarge: AppType.body.copyWith(color: scheme.onSurface),
      bodyMedium: AppType.body.copyWith(color: scheme.onSurface),
      bodySmall: AppType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: AppType.bodyStrong.copyWith(color: scheme.onSurface),
      labelMedium: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
      labelSmall: AppType.overline.copyWith(color: scheme.onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      fontFamily: AppType.sans,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.subheading.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: border),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ---- Buttons -------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: brightText,
          disabledBackgroundColor: scheme.surfaceContainerHigh,
          disabledForegroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: AppType.bodyStrong,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
          side: BorderSide(color: borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: AppType.bodyStrong,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppType.bodyStrong,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: Insets.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
      ),

      // ---- Inputs --------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.lg,
        ),
        hintStyle: AppType.body.copyWith(color: hint),
        labelStyle: AppType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle:
            AppType.bodySmall.copyWith(color: scheme.primary),
        errorStyle: AppType.caption.copyWith(color: scheme.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),

      // ---- Selection ----------------------------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brightText : border,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : border,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primary,
        side: BorderSide(color: border),
        labelStyle: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: AppType.caption.copyWith(color: brightText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        titleTextStyle: AppType.subheading.copyWith(color: scheme.onSurface),
        contentTextStyle: AppType.body.copyWith(color: scheme.onSurfaceVariant),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: AppType.bodySmall.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.secondary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: border),
        ),
        textStyle: AppType.caption.copyWith(color: scheme.onSurface),
      ),

      splashColor: scheme.primary.withValues(alpha: 0.10),
      highlightColor: scheme.primary.withValues(alpha: 0.06),
    );
  }

  /// Brush used for primary calls to action. Kept as a gradient of the brand
  /// hue only — the cyan is reserved for data-in-transit states.
  static Gradient get brandGradient => _brandGradient;
}