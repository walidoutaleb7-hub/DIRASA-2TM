import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConferenceScreen extends StatefulWidget {
  final String conferenceID;
  final String userName;
  const ConferenceScreen({super.key, required this.conferenceID, required this.userName});

  @override
  State<ConferenceScreen> createState() => _ConferenceScreenState();
}

class _ConferenceScreenState extends State<ConferenceScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  int? _appID;
  String? _appSign;

  bool _isLeaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));
    _initializeCall();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    var status = await [Permission.camera, Permission.microphone].request();
    if (!status[Permission.camera]!.isGranted || !status[Permission.microphone]!.isGranted) {
      setState(() { _isLoading = false; _errorMessage = 'يجب السماح بالوصول للكاميرا والمايك.'; });
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://dirasa-2tm.onrender.com/api/zego-credentials'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() { _appID = data['appID']; _appSign = data['appSign']; _isLoading = false; });
      } else {
        setState(() { _isLoading = false; _errorMessage = 'فشل جلب المفاتيح من الخادم.'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'خطأ في الاتصال بالشبكة.'; });
    }
  }

  Future<void> _showLeaveAnimation() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);
    _animController.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLeaving) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.red.withOpacity(0.3), width: 2)),
                    child: const Icon(Icons.call_end, color: Colors.redAccent, size: 60),
                  ),
                  const SizedBox(height: 30),
                  const Text('تم إنهاء المكالمة', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('إلى اللقاء في المرة القادمة', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))));
    if (_errorMessage != null) return Scaffold(backgroundColor: Colors.black, body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white))));

    // 🚀 الحل المضمون: استخدام uid من Firebase لضمان أن كل مستخدم فريد 100%
    final currentUser = FirebaseAuth.instance.currentUser;
    final String uniqueUserID = currentUser?.uid ?? widget.userName.replaceAll(' ', '_');

    return SafeArea(
      child: ZegoUIKitPrebuiltVideoConference(
        appID: _appID!,
        appSign: _appSign!,
        userID: uniqueUserID, 
        userName: widget.userName,
        conferenceID: widget.conferenceID,
        config: ZegoUIKitPrebuiltVideoConferenceConfig(
          turnOnCameraWhenJoining: false,
          turnOnMicrophoneWhenJoining: false,
          video: ZegoUIKitVideoConfig.preset1080P(),
          bottomMenuBarConfig: ZegoBottomMenuBarConfig(
            buttons: [
              ZegoMenuBarButtonName.chatButton,
              ZegoMenuBarButtonName.toggleScreenSharingButton,
              ZegoMenuBarButtonName.toggleMicrophoneButton,
              ZegoMenuBarButtonName.toggleCameraButton,
              ZegoMenuBarButtonName.switchCameraButton,
              ZegoMenuBarButtonName.leaveButton,
            ],
          ),
          onLeaveConfirmation: (context) async {
            _showLeaveAnimation();
            return false;
          },
        ),
      ),
    );
  }
}
