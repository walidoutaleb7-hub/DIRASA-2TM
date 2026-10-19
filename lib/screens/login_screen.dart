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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isFocused = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن عند فتح الشاشة
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    _animController.forward();

    // الاستماع لتركيز الحقل لتغيير التوهج
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await AuthService.login(_nameController.text.trim());
    if (mounted) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Stack(
        children: [
          // 1. الكرات المضيئة في الخلفية (Cinematic Orbs)
          Positioned(
            top: -100, left: -100,
            child: _buildBlurredOrb(AppTheme.primaryColor, 350),
          ),
          Positioned(
            top: 150, right: -150,
            child: _buildBlurredOrb(AppTheme.secondaryColor, 400),
          ),
          Positioned(
            bottom: -150, left: -50,
            child: _buildBlurredOrb(Colors.blueAccent, 300),
          ),

          // 2. محتوى الشاشة
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // الجزء العلوي: الأيقونة والاسم
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // الأيقونة مع توهج
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset('assets/app_icon.png', width: 100, height: 100, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // نص متدرج (Gradient Text)
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                        child: Text(
                          'DIRASA 2TM',
                          style: GoogleFonts.cairo(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مستقبل التعليم يبدأ من هنا',
                        style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1),

                // 3. لوحة الزجاج السفلية (Floating Glass Panel)
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212).withOpacity(0.6),
                            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مرحباً بك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 8),
                              const Text('أدخل اسمك للانضمام إلى القسم', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 30),

                              // حقل الإدخال المضيء
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isFocused ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                  boxShadow: _isFocused ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 15)] : [],
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  focusNode: _focusNode,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: 'الاسم الكامل',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                    prefixIcon: Icon(Icons.person_outline, color: _isFocused ? AppTheme.primaryColor : Colors.white54),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // زر الدخول الفخم
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: _isLoading 
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text('ابدأ الرحلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                            ],
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لإنشاء الكرات المضيئة الضبابية
  Widget _buildBlurredOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.3),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 80, spreadRadius: 40)],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
