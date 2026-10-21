import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const Color blueColor = Color(0xFF3B82F6); // الأزرق (للشباب)
  static const Color pinkColor = Color(0xFFEC4899); // الزهري (للفتيات)
  
  // المتغير الذي سيتم مراقبته لتغيير اللون في كل التطبيق
  static final ValueNotifier<Color> primaryColor = ValueNotifier(blueColor);

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('primaryColor');
    if (colorValue != null) {
      primaryColor.value = Color(colorValue);
    }
  }

  static Future<void> setTheme(Color color) async {
    primaryColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
  }
}
