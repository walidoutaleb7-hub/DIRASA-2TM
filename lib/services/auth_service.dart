import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<void> updateUserData(String name, String status, String? base64Image) async {
    final user = _auth.currentUser;
    if (user != null) {
      Map<String, dynamic> data = {'name': name, 'status': status};
      if (base64Image != null) data['profileImage'] = base64Image;
      await _db.collection('users').doc(user.uid).update(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, name);
    }
  }

  static Future<String?> signUp(String fName, String lName, String email, String password) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      if (userCred.user != null) {
        String fullName = "$fName $lName";
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': fullName, 'email': email.trim(), 'uid': userCred.user!.uid,
          'status': 'متاح للدراسة', 'isOnline': true, 'studyTime': 0, 'createdAt': FieldValue.serverTimestamp(),
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, fullName);
        return null; 
      }
      return "حدث خطأ";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return "هذا البريد مسجل بالفعل.";
      return e.message;
    } catch (e) { return e.toString(); }
  }

  static Future<String?> signIn(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      if (userCred.user != null) {
        String name = userCred.user!.email?.split('@')[0] ?? 'مستخدم';
        DocumentSnapshot doc = await _db.collection('users').doc(userCred.user!.uid).get();
        
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          // 🚀 إصلاح تاريخ الانضمام للحسابات القديمة
          if (data['createdAt'] == null) {
            await _db.collection('users').doc(userCred.user!.uid).update({'createdAt': FieldValue.serverTimestamp()});
          }
        }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        return null; 
      }
      return "فشل الدخول";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "لا يوجد حساب بهذا البريد.";
      if (e.code == 'wrong-password') return "كلمة المرور غير صحيحة.";
      return e.message;
    } catch (e) { return "خطأ في الاتصال."; }
  }

  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; 
    } catch (e) { return "تأكد من صحة البريد."; }
  }

  static Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: '745868828443-v5mvqkeue2rqadpsibqbq1lnjdkh59iv.apps.googleusercontent.com');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return "تم الإلغاء";
      
      final GoogleSignInAuthentication auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken);
      UserCredential userCred = await _auth.signInWithCredential(credential);
      
      if (userCred.user != null) {
        String fullName = userCred.user!.displayName ?? 'مستخدم جوجل';
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': fullName, 'email': userCred.user!.email, 'uid': userCred.user!.uid,
          'status': 'متاح للدراسة', 'isOnline': true, 'studyTime': 0, 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, fullName);
        return null; 
      }
      return "فشل";
    } catch (e) { 
      // 🚀 إظهار الخطأ الحقيقي
      return "فشل جوجل: ${e.toString().substring(0, (e.toString().length > 50 ? 50 : e.toString().length))}"; 
    }
  }

  static Future<void> logout() async {
    try { await _auth.signOut(); } catch (_) {}
    try { await GoogleSignIn().signOut(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
  }
}
