import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/neon_timer.dart';
import '../services/auth_service.dart';
import 'conference_screen.dart';
import 'settings_screen.dart';
import 'social_screen.dart';
import 'chat_list_screen.dart';
import 'ai_screen.dart';
import 'leaderboard_screen.dart';
import 'whiteboard_screen.dart';
import 'subject_rooms_screen.dart';
import 'profile_screen.dart';

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
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, // يسمح للشريط بالطفو
        body: _pages[_currentIndex],
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                selectedItemColor: AppTheme.primaryColor,
                unselectedItemColor: AppTheme.textSecondary,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
                  BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'الزملاء'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'المحادثات'),
                ],
              ),
            ),
          ),
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
  String _userName = '';
  final TextEditingController _roomController = TextEditingController();
  int _seconds = 1500;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final name = await AuthService.getUserName();
    setState(() => _userName = name ?? 'مستخدم');
  }

  void _joinMeeting(String roomId) {
    if (roomId.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConferenceScreen(conferenceID: roomId, userName: _userName)));
  }

  void _toggleTimer() {
    setState(() => _isTimerRunning = !_isTimerRunning);
    if (!_isTimerRunning && _seconds < 1500) {
      int studiedMinutes = (1500 - _seconds) ~/ 60;
      if (studiedMinutes > 0) AuthService.updateStudyTime(studiedMinutes);
      setState(() => _seconds = 1500);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('DIRASA 2TM'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // مساحة للشريط العائم
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أهلاً، $_userName', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: AppTheme.textPrimary)),
            const Text('جاهز للإبداع اليوم؟', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 30),
            
            // المؤقت الدائري الفخم
            Center(
              child: NeonTimer(
                seconds: _seconds,
                isRunning: _isTimerRunning,
                onToggle: _toggleTimer,
              ),
            ),
            const SizedBox(height: 40),

            // الأدوات
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureBtn('المساعد', Icons.smart_toy_outlined, Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIScreen()))),
                  _buildFeatureBtn('المتصدرين', Icons.emoji_events_outlined, Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
                  _buildFeatureBtn('السبورة', Icons.draw_outlined, Colors.greenAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhiteboardScreen()))),
                  _buildFeatureBtn('القاعات', Icons.meeting_room_outlined, Colors.blueAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectRoomsScreen()))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // زر الاجتماع
            _buildAnimatedButton(
              onTap: () {
                String newRoom = 'DIRASA_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                showDialog(context: context, builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.cardColor,
                  title: const Text('غرفة جاهزة (امسح الكود)'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(padding: const EdgeInsets.all(10), color: Colors.white, child: QrImageView(data: newRoom, size: 200)),
                    const SizedBox(height: 10),
                    Text(newRoom, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ]),
                  actions: [
                    TextButton(onPressed: () { Navigator.pop(context); _joinMeeting(newRoom); }, child: const Text('دخول الغرفة')),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
                  ],
                ));
              },
              title: 'إنشاء اجتماع جديد',
              subtitle: 'ابدأ غرفة فيديو فورية',
              icon: Icons.video_camera_front_outlined,
            ),
            const SizedBox(height: 16),

            // الانضمام
            GlassCard(
              child: Column(
                children: [
                  const Row(children: [Icon(Icons.keyboard, color: AppTheme.accentColor), SizedBox(width: 10), Text('الانضمام بكود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 16),
                  TextField(controller: _roomController, decoration: const InputDecoration(hintText: 'أدخل كود الغرفة', prefixIcon: Icon(Icons.keyboard_outlined))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, 
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white), 
                      onPressed: () => _joinMeeting(_roomController.text.trim()), 
                      child: const Text('انضمام')
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton({required VoidCallback onTap, required String title, required String subtitle, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
