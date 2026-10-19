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
    // 1. طلب أذونات الكاميرا والمايك من الهاتف
    var status = await [Permission.camera, Permission.microphone].request();
    if (!status[Permission.camera]!.isGranted || !status[Permission.microphone]!.isGranted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'يجب السماح بالوصول للكاميرا والمايك لإجراء المكالمة.';
      });
      return;
    }

    // 2. جلب المفاتيح من خادم Render
    try {
      final response = await http.get(Uri.parse('https://dirasa-2tm.onrender.com/api/zego-credentials'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _appID = data['appID'];
          _appSign = data['appSign'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في جلب مفاتيح المكالمة من الخادم. تأكد من إعدادات Render.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال بالشبكة. تأكد من الإنترنت.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('رجوع'),
                )
              ],
            ),
          ),
        ),
      );
    }

    // 3. تشغيل واجهة Zego بالمفاتيح التي تم جلبها
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
              ZegoMenuBarButtonName.chatButton,
              ZegoMenuBarButtonName.toggleScreenSharingButton,
              ZegoMenuBarButtonName.toggleMicrophoneButton,
              ZegoMenuBarButtonName.switchCameraButton,
            ],
          ),
        ),
      ),
    );
  }
}
