// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =========================================================================
// 1. Custom Colors Theme Extension
// =========================================================================
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.success,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  final Color success;
  final Color pending;
  final Color approved;
  final Color rejected;

  @override
  AppColorsExtension copyWith({
    Color? success,
    Color? pending,
    Color? approved,
    Color? rejected,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      pending: pending ?? this.pending,
      approved: approved ?? this.approved,
      rejected: rejected ?? this.rejected,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      approved: Color.lerp(approved, other.approved, t)!,
      rejected: Color.lerp(rejected, other.rejected, t)!,
    );
  }
}

// =========================================================================
// 2. Main AppTheme Class
// =========================================================================

class AppTheme {
  static const _primary = Color(0xFFFF9800);
  static const _secondary = Color(0xFF1A1B4B);

  static final _lightColors = AppColorsExtension(
    success: const Color(0xFF388E3C),
    pending: const Color(0xFFFFA726),
    approved: const Color(0xFF66BB6A),
    rejected: const Color(0xFFEF5350),
  );

  static final _darkColors = AppColorsExtension(
    success: const Color(0xFF66BB6A),
    pending: const Color(0xFFFFA726),
    approved: const Color(0xFF81C784),
    rejected: const Color(0xFFE57373),
  );

  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light(useMaterial3: true);
    final colorScheme = baseTheme.colorScheme.copyWith(
      primary: _primary,
      secondary: _secondary,
      error: const Color(0xFFD32F2F),
      surface: Colors.white,
      background: const Color(0xFFF5F5F5),
    );
    return _buildThemeData(baseTheme, colorScheme, _lightColors);
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    final colorScheme = baseTheme.colorScheme.copyWith(
      primary: _primary,
      secondary: _secondary,
      error: const Color(0xFFE57373),
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
    );
    return _buildThemeData(baseTheme, colorScheme, _darkColors);
  }

  static ThemeData _buildThemeData(ThemeData base, ColorScheme colorScheme,
      AppColorsExtension customColors) {
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return base.copyWith(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.background,
      extensions: [customColors],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.brightness == Brightness.light
            ? _secondary
            : colorScheme.surface,
        foregroundColor: colorScheme.brightness == Brightness.light
            ? Colors.white
            : colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.brightness == Brightness.light
              ? Colors.white
              : colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        // FIX: Changed CardTheme to CardThemeData
        color: colorScheme.surface,
        elevation: 1,
        shadowColor: colorScheme.shadow.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withOpacity(0.12),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
