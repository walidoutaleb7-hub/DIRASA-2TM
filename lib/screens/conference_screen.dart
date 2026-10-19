import 'package:flutter/material.dart';
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
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    var status = await [Permission.camera, Permission.microphone].request();
    if (status[Permission.camera]!.isGranted && status[Permission.microphone]!.isGranted) {
      setState(() => _hasPermissions = true);
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
    }

    // ⚠️ ضع مفاتيح Zego هنا ⚠️
    const int appID = 123456789; 
    const String appSign = 'your_app_sign_here'; 

    return SafeArea(
      child: ZegoUIKitPrebuiltVideoConference(
        appID: appID,
        appSign: appSign,
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
