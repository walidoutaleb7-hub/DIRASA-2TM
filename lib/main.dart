import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(home: Scaffold(backgroundColor: Colors.red, body: Center(child: Text('Error: ${details.exception}', style: const TextStyle(color: Colors.white)))));
    };
    try { await Firebase.initializeApp(); } catch (e) { debugPrint("Firebase Error: $e"); }
    runApp(const MyApp());
  }, (error, stackTrace) { debugPrint("Caught error: $error"); });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIRASA 2TM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(), // 🚀 البدء بشاشة الأنميشن
    );
  }
}
