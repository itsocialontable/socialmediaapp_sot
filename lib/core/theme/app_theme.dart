import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base
  static const Color background = Color(0xFF0D1714);
  static const Color surface = Color(0xFF16211E);
  static const Color surfaceLight = Color(0xFF22313D);
  static const Color border = Color(0xFF2C3E50);

  // Brand
  static const Color primary = Color(0xFF113023); // Green
  static const Color primaryLight = Color(0xFF1B4A36); // Light Green
  static const Color secondary = Color(0xFF35466B); // Blue
  static const Color accent = Color(0xFFFFFFFF); // White

  // Role Colors
  static const Color adminColor = Color(0xFF113023);
  static const Color designerColor = Color(0xFF35466B);
  static const Color smmColor = Color(0xFF4A5D89);
  static const Color clientColor = Color(0xFF1B4A36);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF78909C);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF42A5F5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF113023), Color(0xFF35466B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [Color(0xFF113023), Color(0xFF35466B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient designerGradient = LinearGradient(
    colors: [Color(0xFF35466B), Color(0xFF4A5D89)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient smmGradient = LinearGradient(
    colors: [Color(0xFF1B4A36), Color(0xFF35466B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient clientGradient = LinearGradient(
    colors: [Color(0xFF113023), Color(0xFF1B4A36)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF0D1714),
      Color(0xFF113023),
      Color(0xFF35466B),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),

      textTheme:
      GoogleFonts.soraTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.sora(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),

        displayMedium: GoogleFonts.sora(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),

        headlineLarge: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        headlineMedium: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        titleLarge: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        titleMedium: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),

        bodyLarge: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),

        bodyMedium: GoogleFonts.sora(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),

        bodySmall: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),

        labelLarge: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.3,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),

        hintStyle: GoogleFonts.sora(
          color: AppColors.textMuted,
          fontSize: 14,
        ),

        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 54),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          textStyle: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),

          elevation: 0,
        ),
      ),

      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),

      dividerColor: AppColors.border,

      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
      ),
    );
  }
}