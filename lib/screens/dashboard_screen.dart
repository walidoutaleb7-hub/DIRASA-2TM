import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import 'conference_screen.dart';
import 'ai_screen.dart';
import 'social_screen.dart';
import 'chat_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const HomeTab(), const SocialScreen(), const ChatListScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      
      // شريط التنقل العائم
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(0, Icons.grid_view_rounded, 'الرئيسية'),
            _navItem(1, Icons.people_alt_rounded, 'الزملاء'),
            _navItem(2, Icons.forum_rounded, 'الدردشة'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5)) : null,
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('DIRASA 2TM', style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مرحباً، وليد', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('جاهز لتحطيم أهدافك اليوم؟', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 40),
            
            // المؤقت الفخم
            Center(child: _buildCustomTimer()),
            const SizedBox(height: 40),

            // الأدوات
            const Text('أدواتك الذكية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildToolCard(Icons.smart_toy_rounded, 'المساعد', AppTheme.secondaryColor, () => Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const AIScreen(),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation), child: child),
                ))),
                _buildToolCard(Icons.video_call_rounded, 'اجتماع', AppTheme.primaryColor, () => Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ConferenceScreen(conferenceID: 'DIRASA_ROOM', userName: 'Walid'),
                  transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                ))),
                _buildToolCard(Icons.leaderboard_rounded, 'المتصدرين', Colors.orangeAccent, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTimer() {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [AppTheme.primaryColor.withOpacity(0), AppTheme.primaryColor],
          stops: const [0.75, 1.0],
          startAngle: -math.pi / 2,
        ),
        boxShadow: AppTheme.cyanGlow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4), // سمك الحلقة
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.cardColor),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('25:00', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('ابدأ التركيز', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, spreadRadius: 1)],
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
