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

  // 🟢 دالة تحديث حالة الاتصال
  static Future<void> setOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _db.collection('users').doc(user.uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Error updating online status: $e");
      }
    }
  }

  static Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      UserCredential userCred = await _auth.signInWithCredential(credential);

      if (userCred.user != null) {
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': userCred.user!.displayName ?? 'مستخدم جوجل',
          'email': userCred.user!.email,
          'uid': userCred.user!.uid,
          'status': 'متاح للدراسة',
          'isOnline': true,
          'studyTime': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, userCred.user!.displayName ?? 'مستخدم');
        return true;
      }
      return false;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return false;
    }
  }

  static Future<bool> login(String name) async {
    try {
      String cleanName = name.trim().replaceAll(' ', '_').toLowerCase();
      String email = "${cleanName}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}@dirasa.com";
      String password = "DirasaSecurePass123!";
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      if (userCred.user != null) {
        await _db.collection('users').doc(userCred.user!.uid).set({
          'name': name, 'email': email, 'uid': userCred.user!.uid,
          'status': 'متاح للدراسة', 'isOnline': true, 'studyTime': 0, 'createdAt': FieldValue.serverTimestamp(),
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        return true;
      }
      return false;
    } catch (e) {
      try {
        UserCredential anonCred = await _auth.signInAnonymously();
        if (anonCred.user != null) {
           await _db.collection('users').doc(anonCred.user!.uid).set({
            'name': name, 'uid': anonCred.user!.uid,
            'status': 'متاح للدراسة', 'isOnline': true, 'studyTime': 0, 'createdAt': FieldValue.serverTimestamp(),
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUserName, name);
          return true;
        }
      } catch (anonError) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, name);
      return true; 
    }
  }

  static Future<void> logout() async {
    await setOnlineStatus(false); // إخفاء النقطة الخضراء عند الخروج
    try { await GoogleSignIn().signOut(); await _auth.signOut(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
  }
}
