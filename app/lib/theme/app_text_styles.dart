import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text styles mirroring the design tokens (Familjen Grotesk for
/// display/headline/numeral, Karla for body/label). We fall back to the
/// platform default font family so the app runs with zero extra
/// dependencies -- swap `fontFamily` below for GoogleFonts.familjenGrotesk()
/// / GoogleFonts.karla() if you add the google_fonts package later.
class AppTextStyles {
  AppTextStyles._();

  static const _display = 'FamiljenGrotesk';
  static const _body = 'Karla';

  static const displayLg = TextStyle(
    fontFamily: _display,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.primary,
  );

  static const headlineMd = TextStyle(
    fontFamily: _display,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.onSurface,
  );

  static const headlineSm = TextStyle(
    fontFamily: _display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static const bodyLg = TextStyle(
    fontFamily: _body,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  static const bodyMd = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const labelBold = TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.onSurfaceVariant,
  );

  static const labelMd = TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
  );

  static const labelSm = TextStyle(
    fontFamily: _body,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
  );
}
