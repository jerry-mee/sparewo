// lib/constants/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFFF9800); // Orange
  static const Color secondary = Color(0xFF1A1B4B); // Dark Blue
  static const Color background = Color(0xFFF5F5F5); // Light Gray
  static const Color text = Color(0xFF2D2D2D); // Dark Gray
  static const Color textLight = Color(0xFF757575); // Medium Gray
  static const Color error = Color(0xFFD32F2F); // Red
  static const Color success = Color(0xFF388E3C); // Green
  static const Color accent = Color(0xFF00BCD4); // Cyan

  // New colors added
  static const Color ctaButton = Color(0xFF1A1B4B); // For CTA buttons
  static const Color cardBackground =
      Colors.white; // Background color for cards
  static const Color shadow = Colors.black; // Shadow color
  static const Color iconColor = Color(
    0xFF1A1B4B,
  ); // Icon color (same as secondary)

  static MaterialColor primarySwatch =
      MaterialColor(primary.toARGB32(), <int, Color>{
        50: primary.withValues(alpha: 0.1),
        100: primary.withValues(alpha: 0.2),
        200: primary.withValues(alpha: 0.3),
        300: primary.withValues(alpha: 0.4),
        400: primary.withValues(alpha: 0.5),
        500: primary.withValues(alpha: 0.6),
        600: primary.withValues(alpha: 0.7),
        700: primary.withValues(alpha: 0.8),
        800: primary.withValues(alpha: 0.9),
        900: primary,
      });
}

class AppTextStyles {
  static final TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.2,
  );

  static final TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.3,
  );

  static final TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
  );

  static final TextStyle body1 = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
    height: 1.5,
  );

  static final TextStyle body2 = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.5,
  );

  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.5,
  );

  // New text styles added
  static final TextStyle categoryLabel = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary, // Using secondary color for labels
    height: 1.2,
  );

  static final TextStyle categoryDescription = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.4,
  );
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      primaryColor: AppColors.primary,
      primarySwatch: AppColors.primarySwatch,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1,
        displayMedium: AppTextStyles.heading2,
        displaySmall: AppTextStyles.heading3,
        bodyLarge: AppTextStyles.body1,
        bodyMedium: AppTextStyles.body2,
        labelLarge: AppTextStyles.button,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors
            .cardBackground, // Ensuring cards use the correct background color
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
