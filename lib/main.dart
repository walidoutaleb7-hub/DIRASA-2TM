import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/access_code_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isVerified = await AuthService.isVerified();
  String? userName = await AuthService.getUserName();
  
  runApp(MyApp(isVerified: isVerified, savedUserName: userName));
}

class MyApp extends StatelessWidget {
  final bool isVerified;
  final String? savedUserName;

  const MyApp({super.key, required this.isVerified, this.savedUserName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIRASA 2TM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isVerified 
          ? (savedUserName == null ? const LoginScreen() : const DashboardScreen())
          : const AccessCodeScreen(),
    );
  }
}
