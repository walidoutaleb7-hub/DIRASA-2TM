import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  
  late Animation<double> _iconScale;
  late Animation<double> _textFade;
  late Animation<double> _glowOpacity;

  String? _savedUserName; // لجلب البيانات أثناء الأنميشن

  @override
  void initState() {
    super.initState();
    
    // أنيميشن الدخول
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)));
    
    // أنيميشن النبض المستمر (Pulse)
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _controller.forward();
    
    // 🚀 جلب البيانات مبكراً (أثناء عمل الأنميشن) لمنع التقطيع
    _preloadData();
  }

  void _preloadData() async {
    _savedUserName = await AuthService.getUserName();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 3500)); // انتظار 3.5 ثوانٍ
    if (!mounted) return;

    // إذا لم تكن البيانات وصلت بعد، ننتظرها
    if (_savedUserName == null) {
      _savedUserName = await AuthService.getUserName();
    }

    Widget nextScreen = _savedUserName == null ? const LoginScreen() : const DashboardScreen();

    // 🚀 انتقال سينمائي سلس (Fade + Scale)
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => nextScreen,
      transitionDuration: const Duration(milliseconds: 1000), // مدة أطول لانتقال ناعم
      transitionsBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تشغيل الانتقال
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToNext());

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Stack(
        children: [
          // 1. الكرات المضيئة في الخلفية
          Positioned(top: -100, left: -100, child: _buildBlurredOrb(AppTheme.primaryColor, 400)),
          Positioned(bottom: -150, right: -100, child: _buildBlurredOrb(AppTheme.secondaryColor, 500)),

          // 2. المحتوى الرئيسي
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الأيقونة مع توهج نابض
                ScaleTransition(
                  scale: _iconScale,
                  child: AnimatedBuilder(
                    animation: _glowOpacity,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(_glowOpacity.value),
                              blurRadius: 60,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.asset('assets/app_icon.png', width: 140, height: 140, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // النص المتدرج
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                        child: const Text(
                          'DIRASA 2TM',
                          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 3.0, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'مستقبل التعليم يبدأ من هنا',
                        style: TextStyle(fontSize: 16, color: Colors.grey, letterSpacing: 2.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredOrb(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }
}
