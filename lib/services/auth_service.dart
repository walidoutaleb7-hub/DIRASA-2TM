import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyVerified = 'isVerified';
  static const String _keyUserName = 'userName';
  static const String secretCode = '1241245656';

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // تسجيل الدخول أو إنشاء حساب جديد في Firebase
  static Future<bool> login(String name) async {
    try {
      // نصنع بريد إلكتروني وهمي وكلمة مرور ثابتة لكي لا يزعج المستخدم
      String email = "${name.trim().replaceAll(' ', '_').toLowerCase()}@dirasa.com";
      String password = "DirasaPassword123!";

      UserCredential userCred;
      try {
        // محاولة تسجيل الدخول
        userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // إذا لم يكن الحساب موجوداً، ننشئ حساباً جديداً
          userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        } else {
          return false;
        }
      }

      // حفظ بيانات المستخدم في قاعدة بيانات Firestore
      if (userCred.user != null) {
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'uid': userCred.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        await prefs.setString('userId', userCred.user!.uid); // حفظ المعرف للاستخدام لاحقاً
        return true;
      }
      return false;
    } catch (e) {
      print("Error logging in: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
    await prefs.remove('userId');
  }
}
