import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class ConferenceScreen extends StatefulWidget {
  final String conferenceID;
  final String userName;
  const ConferenceScreen({super.key, required this.conferenceID, required this.userName});

  @override
  State<ConferenceScreen> createState() => _ConferenceScreenState();
}

class _ConferenceScreenState extends State<ConferenceScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int? _appID;
  String? _appSign;

  @override
  void initState() {
    super.initState();
    _initializeCall();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.cyan)));
    if (_errorMessage != null) return Scaffold(backgroundColor: Colors.black, body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white))));

    return SafeArea(
      child: ZegoUIKitPrebuiltVideoConference(
        appID: _appID!,
        appSign: _appSign!,
        userID: widget.userName.replaceAll(' ', '_'),
        userName: widget.userName,
        conferenceID: widget.conferenceID,
        config: ZegoUIKitPrebuiltVideoConferenceConfig(
          video: ZegoUIKitVideoConfig.preset1080P(),
          bottomMenuBarConfig: ZegoBottomMenuBarConfig(
            buttons: [
              ZegoMenuBarButtonName.chatButton, // 💬 تم إرجاع الشات
              ZegoMenuBarButtonName.toggleScreenSharingButton,
              ZegoMenuBarButtonName.toggleMicrophoneButton,
              ZegoMenuBarButtonName.toggleCameraButton,
              ZegoMenuBarButtonName.switchCameraButton,
              ZegoMenuBarButtonName.leaveButton, // 🚀 تم إضافة زر إنهاء المكالمة
            ],
          ),
        ),
      ),
    );
  }
}
