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
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4)); // انتظار 4 ثوانٍ لعرض الأنميشن
    if (!mounted) return;

    String? name = await AuthService.getUserName();
    Widget nextScreen = name == null ? const LoginScreen() : const DashboardScreen();

    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => nextScreen,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 800),
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
