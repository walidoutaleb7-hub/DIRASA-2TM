import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyUserName = 'userName';
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<bool> login(String name) async {
    try {
      // محاولة تسجيل الدخول عبر Firebase
      String email = "${name.trim().replaceAll(' ', '_').toLowerCase()}@dirasa.com";
      String password = "DirasaPassword123!";
      UserCredential userCred;

      try {
        userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        } else { throw e; }
      }

      if (userCred.user != null) {
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'uid': userCred.user!.uid,
          'status': 'متاح للدراسة',
          'studyTime': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        return true;
      }
      return false;
    } catch (e) {
      // 🚨 خطة الطوارئ: إذا فشل Firebase، ندخلك محلياً لكي تستخدم التطبيق
      print("Firebase failed, using local fallback: $e");
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
