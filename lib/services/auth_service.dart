import 'dart:convert';
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

  static Future<bool> login(String name) async {
    try {
      String email = "${name.trim().replaceAll(' ', '_').toLowerCase()}@dirasa.com";
      String password = "DirasaPassword123!";
      UserCredential userCred;

      try {
        userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        } else { return false; }
      }

      if (userCred.user != null) {
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'uid': userCred.user!.uid,
          'status': 'متاح للدراسة',
          'profileImage': '',
          'studyTime': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        await prefs.setString('userId', userCred.user!.uid);
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  static Future<void> updateStudyTime(int minutes) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({'studyTime': FieldValue.increment(minutes)});
    }
  }

  static Future<void> updateStatus(String status) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({'status': status});
    }
  }

  static Future<void> updateProfileImage(List<int> imageBytes) async {
    final user = _auth.currentUser;
    if (user != null) {
      String base64Image = base64Encode(imageBytes);
      await _db.collection('users').doc(user.uid).update({'profileImage': base64Image});
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
    await prefs.remove('userId');
  }
}
