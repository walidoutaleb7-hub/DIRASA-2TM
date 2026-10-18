import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AccessCodeScreen extends StatefulWidget {
  const AccessCodeScreen({super.key});
  @override
  State<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _error = '';

  void _checkCode() async {
    final isValid = await AuthService.verifyCode(_codeController.text);
    if (isValid) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } else {
      setState(() => _error = 'رمز الدخول غير صحيح، حاول مرة أخرى.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 64, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 32),
              const Text('DIRASA 2TM', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('نظام إدارة المؤتمرات والدراسة', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              const SizedBox(height: 48),
              TextField(
                controller: _codeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: 'أدخل رمز القسم',
                  hintStyle: const TextStyle(letterSpacing: 0, fontSize: 16),
                  errorText: _error.isEmpty ? null : _error,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkCode,
                  child: const Text('تأكيد الدخول'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
