import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🚀 الألوان الثابتة (الاحتياطية لبقية الكود)
  static const Color primaryColor = Color(0xFF3B82F6); // الأزرق
  static const Color secondaryColor = Color(0xFFD500F9);
  static const Color bgColor = Color(0xFF000000);
  static const Color cardColor = Color(0xFF121212);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFFD500F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🚀 دالة الثيم التي تقبل اللون الديناميكي من الإعدادات
  static ThemeData getTheme(Color dynamicPrimaryColor) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: dynamicPrimaryColor,
      colorScheme: ColorScheme.dark(
        primary: dynamicPrimaryColor,
        secondary: secondaryColor,
        surface: cardColor,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dynamicPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade800, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dynamicPrimaryColor, width: 2)),
        prefixIconColor: textSecondary,
      ),
    );
  }
}
