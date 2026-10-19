import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await AuthService.login(_nameController.text.trim());
    if (mounted) Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => const DashboardScreen(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // خلفية متوهجة
          Positioned(
            top: -100, right: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor.withOpacity(0.15), boxShadow: AppTheme.cyanGlow)),
          ),
          Positioned(
            bottom: -100, left: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.secondaryColor.withOpacity(0.15), boxShadow: AppTheme.purpleGlow)),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 80, color: AppTheme.primaryColor),
                  const SizedBox(height: 20),
                  Text('DIRASA 2TM', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 10),
                  const Text('مستقبل التعليم يبدأ هنا', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 50),
                  
                  GlassCard(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'أدخل اسمك',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        icon: Icon(Icons.person, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      text: _isLoading ? 'جاري الدخول...' : 'ابدأ الرحلة',
                      icon: Icons.arrow_forward,
                      onTap: _isLoading ? () {} : _login,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
