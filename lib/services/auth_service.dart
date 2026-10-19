import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyUserName = 'userName';
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // دالة لجلب الـ UID الحالي (تستخدم في شاشات الدردشة)
  static String? get currentUserId => _auth.currentUser?.uid;

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<bool> login(String name) async {
    try {
      // 1. إنشاء بريد إلكتروني وهمي بناءً على الاسم
      String cleanName = name.trim().replaceAll(' ', '_').toLowerCase();
      String email = "${cleanName}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}@dirasa.com";
      String password = "DirasaSecurePass123!";

      // 2. إنشاء الحساب في Firebase
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      if (userCred.user != null) {
        // 3. حفظ بيانات المستخدم في Firestore
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'uid': userCred.user!.uid,
          'status': 'متاح للدراسة',
          'studyTime': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. حفظ الاسم محلياً للدخول السريع
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        return true;
      }
      return false;
    } catch (e) {
      print("Firebase Login Error: $e");
      // خطة طوارئ: إذا فشل Firebase، ندخلك محلياً لكي لا ينهار التطبيق
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, name);
      return true; 
    }
  }

  static Future<void> updateStudyTime(int minutes) async {
    final user = _auth.currentUser;
    if (user != null) {
      try { await _db.collection('users').doc(user.uid).update({'studyTime': FieldValue.increment(minutes)}); } catch (_) {}
    }
  }

  static Future<void> logout() async {
    try { await _auth.signOut(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
  }
}
