import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgColor = Color(0xFF000000); // أسود مطلق
  static const Color primaryColor = Color(0xFF00F0FF); // سيان نيون
  static const Color secondaryColor = Color(0xFF9D00FF); // بنفسجي نيون
  static const Color cardColor = Color(0xFF0A0A0A); // أسود فاحم للبطاقات
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E8E93);

  // توهجات نيون
  static List<BoxShadow> get cyanGlow => [
    BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
    BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 40, spreadRadius: 5),
  ];

  static List<BoxShadow> get purpleGlow => [
    BoxShadow(color: secondaryColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
    BoxShadow(color: secondaryColor.withOpacity(0.1), blurRadius: 40, spreadRadius: 5),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF9D00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryColor,
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
        titleLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        bodyLarge: GoogleFonts.cairo(color: textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.cairo(color: textSecondary, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.white)),
    );
  }
}
