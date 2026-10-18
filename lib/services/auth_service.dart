import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyVerified = 'isVerified';
  static const String _keyUserName = 'userName';
  static const String secretCode = '1241245656';

  static Future<bool> isVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVerified) ?? false;
  }

  static Future<bool> verifyCode(String code) async {
    if (code == secretCode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyVerified, true);
      return true;
    }
    return false;
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<void> login(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
  }
}
