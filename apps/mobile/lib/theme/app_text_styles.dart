import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text styles mirroring the design tokens (Familjen Grotesk for
/// display/headline/numeral, Karla for body/label). We fall back to the
/// platform default font family so the app runs with zero extra
/// dependencies -- swap `fontFamily` below for GoogleFonts.familjenGrotesk()
/// / GoogleFonts.karla() if you add the google_fonts package later.
class AppTextStyles {
  final BuildContext context;
  AppTextStyles(this.context);

  final _display = 'FamiljenGrotesk';
  final _body = 'Karla';

  TextStyle get displayLg => TextStyle(
    fontFamily: _display,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: context.colors.primary,
  );

  TextStyle get headlineMd => TextStyle(
    fontFamily: _display,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: context.colors.onSurface,
  );

  TextStyle get headlineSm => TextStyle(
    fontFamily: _display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: context.colors.onSurface,
  );

  TextStyle get bodyLg => TextStyle(
    fontFamily: _body,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: context.colors.onSurfaceVariant,
  );

  TextStyle get bodyMd => TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: context.colors.onSurface,
  );

  TextStyle get labelBold => TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: context.colors.onSurfaceVariant,
  );

  TextStyle get labelMd => TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: context.colors.onSurfaceVariant,
  );

  TextStyle get labelSm => TextStyle(
    fontFamily: _body,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: context.colors.onSurfaceVariant,
  );

  // VESIT Text Styles
  TextStyle get vesitHeadlineLg => GoogleFonts.oswald(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    color: context.colors.vesitTextHeading,
    height: 1.2,
  );

  TextStyle get vesitHeadlineMd => GoogleFonts.oswald(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: context.colors.vesitTextHeading,
    height: 1.2,
  );

  TextStyle get vesitHeadlineSm => GoogleFonts.oswald(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: context.colors.vesitTextHeading,
    height: 1.2,
  );

  TextStyle get vesitBodyLg => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: context.colors.vesitTextBody,
  );

  TextStyle get vesitBodyMd => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: context.colors.vesitTextBody,
  );

  TextStyle get vesitBodySm => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: context.colors.vesitTextBody,
  );

  TextStyle get vesitLabelBold => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: context.colors.vesitTextHeading,
    letterSpacing: 0.5,
  );

  TextStyle get vesitLabelSm => GoogleFonts.roboto(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: context.colors.vesitTextBody,
    letterSpacing: 0.5,
  );

  TextStyle get vesitButtonText => GoogleFonts.oswald(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: context.colors.vesitWhite,
    letterSpacing: 1.0,
  );
}

extension AppTextStylesExtension on BuildContext {
  AppTextStyles get textStyles => AppTextStyles(this);
}
