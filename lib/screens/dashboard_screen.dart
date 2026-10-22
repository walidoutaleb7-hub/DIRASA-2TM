import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'conference_screen.dart';
import 'settings_screen.dart';
import 'social_screen.dart';
import 'chat_list_screen.dart';
import 'ai_screen.dart';
import 'leaderboard_screen.dart';
import 'whiteboard_screen.dart';
import 'subject_rooms_screen.dart';
import 'qr_code_screen.dart';
import 'profile_screen.dart';
import 'gpa_calculator_screen.dart';
import 'formula_sheet_screen.dart';
import 'exam_countdown_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final List<Widget> _pages = [const HomeTab(), const SocialScreen(), const ChatListScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.setOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AuthService.setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      AuthService.setOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withOpacity(0.9),
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
  String? _userName;
  final TextEditingController _joinController = TextEditingController();
  bool _isLoading = true;

  int _seconds = 1500;
  bool _isTimerRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    String? name = await AuthService.getUserName();
    setState(() {
      _userName = name ?? 'طالب';
      _isLoading = false;
    });
  }

  // 🚀 زر التشغيل / الإيقاف المؤقت (لا يحفظ، فقط يوقف العداد مؤقتاً)
  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_seconds > 0) {
          setState(() => _seconds--);
        } else {
          timer.cancel();
          setState(() => _isTimerRunning = false);
          _saveStudyTime(); // يحفظ تلقائياً عند اكتمال 25 دقيقة
          setState(() => _seconds = 1500);
        }
      });
    }
  }

  // 🚀 زر الإيقاف النهائي (Stop) يحفظ الوقت ويعيد الضبط
  void _stopAndSaveTimer() async {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
    await _saveStudyTime();
    setState(() => _seconds = 1500);
  }

  Future<void> _saveStudyTime() async {
    int studiedSeconds = 1500 - _seconds;
    if (studiedSeconds > 0) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(AuthService.currentUserId).update({
          'studyTime': FieldValue.increment(studiedSeconds)
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ $studiedSeconds ثانية دراسة!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }

  void _joinRoom(String roomId) {
    if (roomId.trim().isEmpty) return;
    String name = _userName ?? 'مستخدم';
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ConferenceScreen(conferenceID: roomId.trim(), userName: name)
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('DIRASA 2TM', style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(AuthService.currentUserId).snapshots(),
              builder: (context, snapshot) {
                int studyTime = 0;
                if (snapshot.hasData && snapshot.data!.data() != null) {
                  studyTime = (snapshot.data!.data() as Map<String, dynamic>)['studyTime'] ?? 0;
                }
                int minutes = studyTime ~/ 60;
                String displayTime = minutes >= 60 ? '${minutes ~/ 60} ساعة و ${minutes % 60} دقيقة' : (studyTime < 60 ? '$studyTime ثانية' : '$minutes دقيقة');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أهلاً بك، $_userName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text('إجمالي الدراسة: $displayTime', style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 20)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مؤقت التركيز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Text('${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Row(
                    children: [
                      // 🚀 زر الإيقاف النهائي (Stop - يحفظ الوقت)
                      GestureDetector(
                        onTap: _stopAndSaveTimer,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 10)]),
                          child: const Icon(Icons.stop, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 🚀 زر التشغيل / الإيقاف المؤقت (Pause)
                      GestureDetector(
                        onTap: _toggleTimer,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isTimerRunning ? Colors.orange : AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: (_isTimerRunning ? Colors.orange : AppTheme.primaryColor).withOpacity(0.4), blurRadius: 15)],
                          ),
                          child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.secondaryColor.withOpacity(0.2), AppTheme.primaryColor.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.secondaryColor, size: 30),
                  const SizedBox(width: 16),
                  Expanded(child: Text("النجاح هو مجموع جهود صغيرة تتكرر يوماً بعد يوم.", style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic, height: 1.5))),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text('أدواتك الخارقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildToolCard(Icons.smart_toy_rounded, 'المساعد AI', AppTheme.secondaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIScreen()))),
                _buildToolCard(Icons.video_call_rounded, 'اجتماع جديد', AppTheme.primaryColor, () {
                  String newRoom = 'DIRASA_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => QRCodeScreen(roomId: newRoom)));
                }),
                _buildToolCard(Icons.draw_rounded, 'السبورة', Colors.greenAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhiteboardScreen()))),
                _buildToolCard(Icons.emoji_events_rounded, 'المتصدرين', Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
                _buildToolCard(Icons.meeting_room_rounded, 'القاعات', Colors.orangeAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectRoomsScreen()))),
                _buildToolCard(Icons.calculate_rounded, 'حاسبة المعدل', Colors.pinkAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GpaCalculatorScreen()))),
                _buildToolCard(Icons.menu_book_rounded, 'مذكرة القوانين', Colors.lightBlueAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormulaSheetScreen()))),
                _buildToolCard(Icons.calendar_month_rounded, 'عداد الامتحانات', Colors.deepOrangeAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamCountdownScreen()))),
              ],
            ),
            const SizedBox(height: 30),

            const Text('انضمام سريع بغرفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _joinController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'أدخل كود الغرفة هنا...', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                      onSubmitted: _joinRoom,
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor), onPressed: () => _joinRoom(_joinController.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.3)), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 40), const SizedBox(height: 12), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
      ),
    );
  }
}
