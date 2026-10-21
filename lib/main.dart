import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try { 
      await Firebase.initializeApp(); 
      await ThemeService.loadTheme(); // 🚀 تحميل اللون المحفوظ
    } catch (e) { debugPrint("Initialization Error: $e"); }
    runApp(const MyApp());
  }, (error, stackTrace) { debugPrint("Caught error: $error"); });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 الاستماع لتغيير اللون وتطبيقه على كل التطبيق
    return ValueListenableBuilder<Color>(
      valueListenable: ThemeService.primaryColor,
      builder: (context, currentColor, child) {
        return MaterialApp(
          title: 'DIRASA 2TM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(currentColor),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
