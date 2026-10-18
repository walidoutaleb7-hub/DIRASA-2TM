import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  bool isVerified = prefs.getBool('isVerified') ?? false;
  String? userName = prefs.getString('userName');
  
  runApp(MyApp(isVerified: isVerified, savedUserName: userName));
}

class MyApp extends StatelessWidget {
  final bool isVerified;
  final String? savedUserName;

  const MyApp({super.key, required this.isVerified, this.savedUserName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIRASA 2TM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: isVerified 
          ? (savedUserName == null ? const LoginScreen() : const DashboardScreen())
          : const AccessCodeScreen(),
    );
  }
}

// 🔒 1. شاشة الرمز السري
class AccessCodeScreen extends StatefulWidget {
  const AccessCodeScreen({super.key});
  @override
  State<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _error = '';

  void _checkCode() async {
    if (_codeController.text == '1241245656') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isVerified', true);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } else {
      setState(() => _error = 'الرمز السري غير صحيح!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 80, color: Colors.indigo),
                  const SizedBox(height: 20),
                  const Text('DIRASA 2TM', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 10),
                  const Text('الرجاء إدخال رمز القسم للدخول', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'الرمز السري',
                      errorText: _error.isEmpty ? null : _error,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _checkCode, child: const Text('تأكيد الدخول')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 👤 2. شاشة تسجيل الدخول
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _login() async {
    if (_nameController.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 100, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text('مرحباً بك في DIRASA 2TM', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _login, child: const Text('دخول إلى التطبيق')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🏠 3. الشاشة الرئيسية (لوحة التحكم)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = '';
  final TextEditingController _roomController = TextEditingController();
  int _seconds = 1500; // 25 دقيقة
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? 'مستخدم');
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _joinMeeting(String roomId) {
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال معرف الغرفة')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConferencePage(conferenceID: roomId, userName: _userName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DIRASA 2TM', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أهلاً بك، $_userName 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Card(
              color: Colors.indigo[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مؤقت التركيز', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const SizedBox(height: 5),
                        Text('${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: const CircleBorder(), padding: const EdgeInsets.all(15)),
                      onPressed: () {
                        setState(() => _isTimerRunning = !_isTimerRunning);
                      },
                      child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildActionCard(
              title: 'إنشاء اجتماع جديد',
              icon: Icons.video_call,
              color: Colors.green,
              onTap: () {
                String newRoom = 'DIRASA_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                _joinMeeting(newRoom);
              },
            ),
            const SizedBox(height: 15),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.meeting_room, color: Colors.orange),
                        SizedBox(width: 10),
                        Text('الانضمام إلى غرفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _roomController,
                      decoration: InputDecoration(
                        hintText: 'أدخل كود الغرفة (مثال: 1234)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: () => _joinMeeting(_roomController.text.trim()),
                        child: const Text('انضمام'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 30)),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// 📹 4. شاشة المكالمة
class ConferencePage extends StatelessWidget {
  final String conferenceID;
  final String userName;

  const ConferencePage({super.key, required this.conferenceID, required this.userName});

  @override
  Widget build(BuildContext context) {
    // 👇 هنا ضع مفاتيحك 👇
    const int appID = 742182118; 
    const String appSign = 'f7567d498c977acaac73b2b814743e05170d993f282c28d1141c4bc29a749c74'; 

    return SafeArea(
      child: ZegoUIKitPrebuiltVideoConference(
        appID: appID,
        appSign: appSign,
        userID: userName.replaceAll(' ', '_'),
        userName: userName,
        conferenceID: conferenceID,
        config: ZegoUIKitPrebuiltVideoConferenceConfig(
          videoConfig: ZegoVideoConfig(resolution: ZegoVideoConfigPreset.preset1080p),
          bottomMenuBarConfig: ZegoBottomMenuBarConfig(
            buttons: [
              ZegoMenuBarButtonName.chatButton,
              ZegoMenuBarButtonName.toggleScreenSharingButton,
              ZegoMenuBarButtonName.toggleMicrophoneButton,
              ZegoMenuBarButtonName.switchCameraButton,
            ],
          ),
          layout: ZegoLayout.gallery(
            showNewScreenSharingViewInFullscreenMode: true,
          ),
        ),
      ),
    );
  }
}
