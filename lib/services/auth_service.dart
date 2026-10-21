import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AuthService {
  static const String _keyUserName = 'userName';
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<void> setOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      try { await _db.collection('users').doc(user.uid).update({'isOnline': isOnline, 'lastSeen': FieldValue.serverTimestamp()}); } catch (_) {}
    }
  }

  static Future<String?> signUp(String fName, String lName, String email, String password) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      if (userCred.user != null) {
        String fullName = "$fName $lName";
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': fullName, 'firstName': fName, 'lastName': lName, 'email': email.trim(), 'uid': userCred.user!.uid,
          'status': 'متاح للدراسة', 'isOnline': true, 'studyTime': 0, 'createdAt': FieldValue.serverTimestamp(),
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, fullName);
        return null; 
      }
      return "حدث خطأ غير معروف";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return "هذا البريد مسجل بالفعل.";
      if (e.code == 'weak-password') return "كلمة المرور ضعيفة جداً (6 أحرف على الأقل).";
      return e.message;
    } catch (e) { return e.toString(); }
  }

  static Future<String?> signIn(String email, String password) async {
    try {
      // 1. محاولة تسجيل الدخول عبر Firebase Auth
      UserCredential userCred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      
      if (userCred.user != null) {
        // 2. إذا نجحت المصادقة، نحاول جلب الاسم من Firestore
        String name = 'مستخدم';
        try {
          DocumentSnapshot doc = await _db.collection('users').doc(userCred.user!.uid).get();
          if (doc.exists) {
            name = (doc.data() as Map<String, dynamic>)['name'] ?? 'مستخدم';
          } else {
            // إذا لم يكن هناك ملف، ننشئ واحداً تلقائياً
            name = userCred.user!.email?.split('@')[0] ?? 'مستخدم';
            await _db.collection('users').doc(userCred.user!.uid).set({
              'name': name, 'email': userCred.user!.email, 'uid': userCred.user!.uid,
              'status': 'متاح للدراسة', 'isOnline': true, 'studyTime': 0, 'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (firestoreError) {
          // إذا فشل Firestore، لا نمنع الدخول، نستخدم الاسم الافتراضي
          print("Firestore Fetch Error: $firestoreError");
          name = userCred.user!.email?.split('@')[0] ?? 'مستخدم';
        }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        return null; // نجاح الدخول
      }
      return "فشل الدخول";
    } on FirebaseAuthException catch (e) {
      // إظهار الخطأ الحقيقي من Firebase Auth
      if (e.code == 'user-not-found') return "لا يوجد حساب بهذا البريد.";
      if (e.code == 'wrong-password') return "كلمة المرور غير صحيحة.";
      if (e.code == 'invalid-email') return "صيغة البريد الإلكتروني غير صحيحة.";
      if (e.code == 'network-request-failed') return "فشل الاتصال بالشبكة. تأكد من الإنترنت.";
      return "خطأ: ${e.message}";
    } catch (e) { 
      return "خطأ غير متوقع: ${e.toString()}";
    }
  }

  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; 
    } catch (e) { return "تأكد من صحة البريد الإلكتروني."; }
  }

  static Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return "تم الإلغاء";
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      UserCredential userCred = await _auth.signInWithCredential(credential);

      if (userCred.user != null) {
        String fullName = userCred.user!.displayName ?? 'مستخدم جوجل';
        try {
          await _db.collection('users').doc(userCred.user!.uid).set({
            'name': fullName, 'email': userCred.user!.email, 'uid': userCred.user!.uid,
            'status': 'متاح للدراسة', 'isOnline': true, 'studyTime': 0, 'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) { print("Firestore error on Google SignIn: $e"); }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, fullName);
        return null; 
      }
      return "فشل الدخول";
    } catch (e) {
      return "فشل الدخول بجوجل. تأكد من إعدادات Firebase.";
    }
  }

  static Future<void> logout() async {
    try { await _auth.signOut(); } catch (e) { print("SignOut Error: $e"); }
    try { await GoogleSignIn().signOut(); } catch (e) { print("Google SignOut Error: $e"); }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserName);
    } catch (e) { print("Prefs Error: $e"); }
  }
}
