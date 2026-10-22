import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMsg;

  void _submit() async {
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _errorMsg = null; });

    String? error;
    if (_isLogin) {
      error = await AuthService.signIn(_emailController.text, _passController.text);
    } else {
      error = await AuthService.signUp("", "", _emailController.text, _passController.text);
    }

    if (mounted) {
      setState(() { _isLoading = false; _errorMsg = error; });
      if (error == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    }
  }

  void _googleLogin() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    String? error = await AuthService.signInWithGoogle();
    if (mounted) {
      setState(() { _isLoading = false; _errorMsg = error; });
      if (error == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    }
  }

  void _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMsg = "أدخل بريدك الإلكتروني أولاً لإرسال الرابط.");
      return;
    }
    setState(() => _isLoading = true);
    String? error = await AuthService.resetPassword(_emailController.text);
    setState(() => _isLoading = false);

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك.'), backgroundColor: Colors.green));
      } else {
        setState(() => _errorMsg = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(top: -100, left: -100, child: _buildBlurredOrb(AppTheme.primaryColor, 350)),
          Positioned(top: 150, right: -150, child: _buildBlurredOrb(AppTheme.secondaryColor, 400)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/app_icon.png', width: 70),
                          const SizedBox(height: 16),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                            child: Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 24),

                          _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email, keyboard: TextInputType.emailAddress),
                          const SizedBox(height: 12),
                          _buildTextField(_passController, 'كلمة المرور', Icons.lock, isPass: true),

                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                            ),

                          if (_errorMsg != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                            ),

                          const SizedBox(height: 16),
                          // 🚀 زر الدخول (بدون ارتفاع ثابت)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                              child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : Text(_isLogin ? 'دخول' : 'إنشاء الحساب', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() { _isLogin = !_isLogin; _errorMsg = null; }),
                            child: Text(_isLogin ? 'ليس لديك حساب؟ إنشاء حساب جديد' : 'لديك حساب بالفعل؟ تسجيل الدخول', style: const TextStyle(color: AppTheme.primaryColor)),
                          ),

                          const Divider(color: Colors.grey),
                          
                          // 🚀 زر Google (الحل الجذري: بدون ارتفاع ثابت واستخدام Row)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _googleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'الدخول باستخدام Google',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPass = false, TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.black.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBlurredOrb(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.3), boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 80, spreadRadius: 40)]),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)),
    );
  }
}
