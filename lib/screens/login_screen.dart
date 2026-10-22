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
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  
  bool _isLoading = false;
  bool _isFocused1 = false;
  bool _isFocused2 = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _animController.forward();

    _focusNode1.addListener(() => setState(() => _isFocused1 = _focusNode1.hasFocus));
    _focusNode2.addListener(() => setState(() => _isFocused2 = _focusNode2.hasFocus));
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _login() async {
    String fName = _firstNameController.text.trim();
    String lName = _lastNameController.text.trim();
    
    if (fName.isEmpty || lName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال الاسم الأول والثاني')));
      return;
    }

    setState(() => _isLoading = true);
    String fullName = "$fName $lName";
    
    await AuthService.login(fullName);
    
    if (mounted) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ));
    }
  }

  void _googleLogin() async {
    setState(() => _isLoading = true);
    bool success = await AuthService.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الدخول باستخدام Google.')));
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
          
          // 🚀 إضافة SafeArea لضمان عدم تغطية الأزرار من قبل شريط التنقل
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)]),
                            child: ClipRRect(borderRadius: BorderRadius.circular(40), child: Image.asset('assets/app_icon.png', width: 80, height: 80, fit: BoxFit.cover)),
                          ),
                          const SizedBox(height: 16),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                            child: Text(
                              'DIRASA 2TM',
                              style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مستقبل التعليم يبدأ من هنا',
                            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),
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
                              padding: const EdgeInsets.fromLTRB(32, 32, 32, 32), // 🚀 زيادة المساحة السفلية
                              decoration: BoxDecoration(color: const Color(0xFF121212).withOpacity(0.6), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('مرحباً بك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  const Text('أدخل اسمك للانضمام إلى القسم', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                  const SizedBox(height: 20),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: _isFocused1 ? AppTheme.primaryColor : Colors.white.withOpacity(0.1), width: 1.5)),
                                    child: TextField(controller: _firstNameController, focusNode: _focusNode1, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'الاسم الأول', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), prefixIcon: Icon(Icons.person_outline, color: _isFocused1 ? AppTheme.primaryColor : Colors.white54), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16))),
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: _isFocused2 ? AppTheme.primaryColor : Colors.white.withOpacity(0.1), width: 1.5)),
                                    child: TextField(controller: _lastNameController, focusNode: _focusNode2, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'الاسم الثاني (العائلة)', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), prefixIcon: Icon(Icons.badge_outlined, color: _isFocused2 ? AppTheme.primaryColor : Colors.white54), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16))),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                                      child: Ink(
                                        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('ابدأ الرحلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, color: Colors.white)]),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Center(child: Text('أو', style: TextStyle(color: Colors.grey, fontSize: 12))),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading ? null : _googleLogin,
                                      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                                      label: const Text('الدخول باستخدام Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.2)))),
                                    ),
                                  ),
                                  // 🚀 مساحة إضافية في الأسفل لضمان عدم قطع الزر
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
            ),
          ),
        ],
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
