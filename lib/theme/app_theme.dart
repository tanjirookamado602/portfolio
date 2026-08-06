import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Warm Editorial Colors ---
  static const Color bgPrimary = Color(0xFFF7F3EC); // Warm paper background
  static const Color bgSurface =
      Color(0xFFEFE9DE); // Card/section surface background
  static const Color bgSurfaceElevated = Color(0xFFE8E0D2); // Hover states
  static const Color borderSubtle = Color(0xFFDCD4C4); // 1px hairline borders

  static const Color ink =
      Color(0xFF1C1B1A); // Primary text, headings (near-black)
  static const Color textPrimary = ink;
  static const Color textMuted =
      Color(0xFF8A8378); // Secondary text, captions, labels
  static const Color textFaint = Color(0xFFB3AB9C); // Tertiary/disabled text

  static const Color accentPrimary = Color(0xFFC4432E); // Brick red
  static const Color accentSecondary = Color(0xFF2E4034); // Deep forest green

  static const Color success = Color(0xFF2E4034);
  static const Color error = Color(0xFFA02B1E); // Serious red

  // Missing legacy colors mapped for admin panel compatibility without crash
  static const Color accentPrimaryVariant = Color(0xFFE5E7EB);
  static const Color errorColor = error;
  static const Color successColor = success;
  static const Color accentBlue = Color(0xFF2E4034); // Mapped to forest green
  static const Color accentPurple = Color(0xFFC4432E); // Mapped to brick red
  static const Color accentCyan = Color(0xFF8A8378);
  static const Color accentPink = Color(0xFFC4432E);
  static const Color textGray = Color(0xFF8A8378);

  // Legacy mappings to prevent immediate breakage where hardcoded
  static const Color primaryBackground = bgPrimary;
  static const Color secondaryBackground = bgSurface;
  static const Color cardColor = bgSurface;
  static const Color cardColorLight = bgSurfaceElevated;
  static const Color borderColor = borderSubtle;
  static const Color primaryColor = accentPrimary;
  static const Color textColor = textPrimary;
  static const Color textSecondary = textMuted;

  // --- Typography ---

  static TextStyle get displayLarge => GoogleFonts.fraunces(
        fontSize: 72,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.1,
        letterSpacing: -1.0,
      );

  static TextStyle get displayMedium => GoogleFonts.fraunces(
        fontSize: 44,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get displaySmall => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get titleLarge => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: ink.withOpacity(0.85),
        height: 1.7,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.5,
      );

  static TextStyle get labelMeta => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.5,
      );

  static TextStyle get pullQuoteText => GoogleFonts.fraunces(
        fontSize: 24,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        color: ink.withOpacity(0.9),
      );

  static TextStyle get sectionTitleStyle => displayMedium;
  static TextStyle get cardTitleStyle => titleMedium;
  static TextStyle get bodyTextStyle => bodyMedium;
  static TextStyle get headlineSmall => titleSmall;
  static TextStyle get heroTextStyle => displayLarge;

  // --- Theme Data ---
  // Named darkTheme to avoid breaking main.dart's imports, but fully customized for Warm Editorial light mode
  static ThemeData get darkTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: accentPrimary,
      cardColor: bgSurface,
      colorScheme: const ColorScheme.light(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: bgSurface,
        background: bgPrimary,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: bgPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: borderSubtle, width: 1),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentPrimary, width: 1),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textFaint),
      ),
    );
  }

  // --- Decorations (Flat "Warm Editorial" Style) ---
  static BoxDecoration glassDecoration({
    double radius = 10,
    Color borderColor = borderSubtle,
    double blur = 0,
    List<Color>? gradientColors,
  }) {
    return BoxDecoration(
      color: bgSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
    );
  }

  static BoxDecoration flatDecoration({
    double radius = 10,
    Color borderColor = borderSubtle,
    Color backgroundColor = bgSurface,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
    );
  }

  // Linear Gradients dummy to prevent breaks (returns flat color)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentPrimary, accentPrimary],
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentSecondary, accentSecondary],
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [bgPrimary, bgPrimary],
  );

  static double responsivePadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 1400) return 120;
    if (w > 1200) return 96;
    if (w > 900) return 64;
    if (w > 600) return 32;
    return 24;
  }

  static double maxContentWidth(BuildContext context) => 1200;
}
