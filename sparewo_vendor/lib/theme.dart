import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorColors {
  static const Color primary = Color(0xFFFF9800);
  static const Color secondary = Color(0xFF1A1B4B);
  static const Color background = Color(0xFFF5F5F5);
  static const Color text = Color(0xFF2D2D2D);
  static const Color textLight = Color(0xFF757575);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color pending = Color(0xFFFFA726);
  static const Color approved = Color(0xFF66BB6A);
  static const Color rejected = Color(0xFFEF5350);
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
}

class VendorTextStyles {
  static final TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: VendorColors.text,
    height: 1.3,
  );

  static final TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: VendorColors.text,
    height: 1.3,
  );

  static final TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: VendorColors.text,
    height: 1.3,
  );

  static final TextStyle body1 = GoogleFonts.poppins(
    fontSize: 16,
    color: VendorColors.text,
    height: 1.5,
  );

  static final TextStyle body2 = GoogleFonts.poppins(
    fontSize: 14,
    color: VendorColors.textLight,
    height: 1.5,
  );

  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.5,
  );

  static final TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    color: VendorColors.textLight,
    height: 1.5,
  );
}

class VendorTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: VendorColors.primary,
      scaffoldBackgroundColor: VendorColors.background,
      colorScheme: const ColorScheme.light(
        primary: VendorColors.primary,
        secondary: VendorColors.secondary,
        error: VendorColors.error,
        surface: VendorColors.cardBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VendorColors.secondary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: VendorTextStyles.heading3.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: VendorColors.cardBackground,
        elevation: 2,
        shadowColor: VendorColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VendorColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
          textStyle: VendorTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VendorColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(color: VendorColors.primary),
          textStyle:
              VendorTextStyles.button.copyWith(color: VendorColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VendorColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle:
              VendorTextStyles.button.copyWith(color: VendorColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VendorColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VendorColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VendorColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VendorColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VendorColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: VendorTextStyles.body2,
        hintStyle: VendorTextStyles.body2,
        errorStyle:
            VendorTextStyles.caption.copyWith(color: VendorColors.error),
      ),
      dividerTheme: const DividerThemeData(
        color: VendorColors.divider,
        space: 1,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: VendorTextStyles.heading1,
        displayMedium: VendorTextStyles.heading2,
        displaySmall: VendorTextStyles.heading3,
        bodyLarge: VendorTextStyles.body1,
        bodyMedium: VendorTextStyles.body2,
        labelLarge: VendorTextStyles.button,
        bodySmall: VendorTextStyles.caption,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
