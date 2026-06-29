import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cyber slate colors
  static const Color darkBackground = Color(0xFF0A0F1D); // Deep dark blue-grey
  static const Color darkSurface = Color(0xFF141C2F);    // Elevated surface container
  static const Color darkCard = Color(0xFF1E293B);       // Card background
  
  // Neon indicators
  static const Color cyberCyan = Color(0xFF00F0FF);     // Neon cyan/blue for selections
  static const Color cyberPurple = Color(0xFFAD00FF);   // Purple accent
  static const Color cyberGreen = Color(0xFF00FF85);    // Safe status
  static const Color cyberAmber = Color(0xFFFFB800);    // Caution status
  static const Color cyberRed = Color(0xFFFF2E54);      // Danger status
  
  static const Color textPrimary = Color(0xFFF1F5F9);   // Off-white main text
  static const Color textSecondary = Color(0xFF94A3B8); // Muted slate sub text

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: cyberCyan,
        secondary: cyberPurple,
        surface: darkSurface,
        onSurface: textPrimary,
        error: cyberRed,
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textPrimary),
        bodyMedium: GoogleFonts.inter(color: textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSurface,
          foregroundColor: cyberCyan,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: cyberCyan, width: 1.2),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cyberCyan,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
