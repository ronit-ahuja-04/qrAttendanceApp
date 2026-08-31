import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color surface;
  final Color surfaceDim;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color error;
  final Color wall;
  final Color debossedWell;
  final Color amberGlow;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color vesitPrimary;
  final Color vesitGold;
  final Color vesitWhite;
  final Color vesitGray;
  final Color vesitTextHeading;
  final Color vesitTextBody;
  final Color vesitGreen;
  final Color vesitOrange;
  final Color vesitRed;

  const AppThemeColors({
    required this.surface,
    required this.surfaceDim,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.error,
    required this.wall,
    required this.debossedWell,
    required this.amberGlow,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.vesitPrimary,
    required this.vesitGold,
    required this.vesitWhite,
    required this.vesitGray,
    required this.vesitTextHeading,
    required this.vesitTextBody,
    required this.vesitGreen,
    required this.vesitOrange,
    required this.vesitRed,
  });

  @override
  AppThemeColors copyWith({
    Color? surface,
    Color? surfaceDim,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? primary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? error,
    Color? wall,
    Color? debossedWell,
    Color? amberGlow,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? inverseSurface,
    Color? inverseOnSurface,
    Color? vesitPrimary,
    Color? vesitGold,
    Color? vesitWhite,
    Color? vesitGray,
    Color? vesitTextHeading,
    Color? vesitTextBody,
    Color? vesitGreen,
    Color? vesitOrange,
    Color? vesitRed,
  }) {
    return AppThemeColors(
      surface: surface ?? this.surface,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      error: error ?? this.error,
      wall: wall ?? this.wall,
      debossedWell: debossedWell ?? this.debossedWell,
      amberGlow: amberGlow ?? this.amberGlow,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      inverseOnSurface: inverseOnSurface ?? this.inverseOnSurface,
      vesitPrimary: vesitPrimary ?? this.vesitPrimary,
      vesitGold: vesitGold ?? this.vesitGold,
      vesitWhite: vesitWhite ?? this.vesitWhite,
      vesitGray: vesitGray ?? this.vesitGray,
      vesitTextHeading: vesitTextHeading ?? this.vesitTextHeading,
      vesitTextBody: vesitTextBody ?? this.vesitTextBody,
      vesitGreen: vesitGreen ?? this.vesitGreen,
      vesitOrange: vesitOrange ?? this.vesitOrange,
      vesitRed: vesitRed ?? this.vesitRed,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      wall: Color.lerp(wall, other.wall, t)!,
      debossedWell: Color.lerp(debossedWell, other.debossedWell, t)!,
      amberGlow: Color.lerp(amberGlow, other.amberGlow, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondaryContainer: Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      inverseOnSurface: Color.lerp(inverseOnSurface, other.inverseOnSurface, t)!,
      vesitPrimary: Color.lerp(vesitPrimary, other.vesitPrimary, t)!,
      vesitGold: Color.lerp(vesitGold, other.vesitGold, t)!,
      vesitWhite: Color.lerp(vesitWhite, other.vesitWhite, t)!,
      vesitGray: Color.lerp(vesitGray, other.vesitGray, t)!,
      vesitTextHeading: Color.lerp(vesitTextHeading, other.vesitTextHeading, t)!,
      vesitTextBody: Color.lerp(vesitTextBody, other.vesitTextBody, t)!,
      vesitGreen: Color.lerp(vesitGreen, other.vesitGreen, t)!,
      vesitOrange: Color.lerp(vesitOrange, other.vesitOrange, t)!,
      vesitRed: Color.lerp(vesitRed, other.vesitRed, t)!,
    );
  }

  static const light = AppThemeColors(
    surface: Color(0xFFFFFFFF),
    surfaceDim: Color(0xFFFAFAFA),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF4F4F5), // subtle grey for cards
    surfaceContainerHigh: Color(0xFFE4E4E7),
    surfaceContainerHighest: Color(0xFFD4D4D8),
    onSurface: Color(0xFF09090B), // Near-black for extreme readability
    onSurfaceVariant: Color(0xFF71717A), // Crisp secondary text
    outline: Color(0xFFE5E5E5), // 1px borders
    outlineVariant: Color(0xFFD4D4D8),
    primary: Color(0xFF002147), // Deep Vesit Navy
    primaryContainer: Color(0xFF002147),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFF3F3F46),
    error: Color(0xFFEF4444), // Premium Red
    wall: Color(0xFFFAFAFA),
    debossedWell: Color(0xFFF4F4F5),
    amberGlow: Color(0x1F002147),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    secondaryContainer: Color(0xFFE0E7FF),
    onSecondaryContainer: Color(0xFF09090B),
    inverseSurface: Color(0xFF18181B),
    inverseOnSurface: Color(0xFFFAFAFA),
    vesitPrimary: Color(0xFF002147),
    vesitGold: Color(0xFFD97706), // Rich Gold
    vesitWhite: Color(0xFFFFFFFF),
    vesitGray: Color(0xFFF4F4F5),
    vesitTextHeading: Color(0xFF09090B),
    vesitTextBody: Color(0xFF52525B), // Slightly darker body text for readability
    vesitGreen: Color(0xFF16A34A),
    vesitOrange: Color(0xFFEA580C),
    vesitRed: Color(0xFFDC2626),
  );

  static const dark = AppThemeColors(
    surface: Color(0xFF09090B), // Very dark sleek grey, almost black
    surfaceDim: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF09090B),
    surfaceContainer: Color(0xFF18181B), // Elevated card background
    surfaceContainerHigh: Color(0xFF27272A),
    surfaceContainerHighest: Color(0xFF3F3F46),
    onSurface: Color(0xFFFAFAFA), // Crisp white text for ultimate readability
    onSurfaceVariant: Color(0xFFA1A1AA), // Premium secondary grey
    outline: Color(0xFF27272A), // Subtle structural borders
    outlineVariant: Color(0xFF3F3F46),
    primary: Color(0xFF3B82F6), // Vibrant premium blue that pops in dark mode
    primaryContainer: Color(0xFF1E3A8A), // Deep blue for active elements
    onPrimaryContainer: Color(0xFFEFF6FF),
    secondary: Color(0xFFA1A1AA),
    error: Color(0xFFDC2626), // Deep rich red, not pinkish
    wall: Color(0xFF000000),
    debossedWell: Color(0xFF18181B),
    amberGlow: Color(0x263B82F6),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEF2F2),
    secondaryContainer: Color(0xFF27272A),
    onSecondaryContainer: Color(0xFFFAFAFA),
    inverseSurface: Color(0xFFFAFAFA),
    inverseOnSurface: Color(0xFF18181B),
    vesitPrimary: Color(0xFF3B82F6),
    vesitGold: Color(0xFFFBBF24), // Vibrant gold accent
    vesitWhite: Color(0xFF18181B), // Maps 'white cards' to nice dark grey
    vesitGray: Color(0xFF27272A),
    vesitTextHeading: Color(0xFFFFFFFF), // Pure white headings
    vesitTextBody: Color(0xFFD4D4D8), // Highly readable body text
    vesitGreen: Color(0xFF22C55E),
    vesitOrange: Color(0xFFD97706), // Deeper richer amber-orange
    vesitRed: Color(0xFFDC2626), // Match deep red
  );

  Color getAttendanceColor(double percentage) {
    if (percentage >= 75) return vesitGreen;
    if (percentage >= 70) return vesitGold;
    if (percentage >= 50) return vesitOrange;
    return vesitRed;
  }
}

extension AppColorsExtension on BuildContext {
  AppThemeColors get colors => Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
}
