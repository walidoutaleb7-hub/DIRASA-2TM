import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class ConferenceScreen extends StatelessWidget {
  final String conferenceID;
  final String userName;

  const ConferenceScreen({super.key, required this.conferenceID, required this.userName});

  @override
  Widget build(BuildContext context) {
    // ⚠️ ضع المفاتيح الخاصة بك هنا ⚠️
    const int appID = 123456789; 
    const String appSign = 'your_app_sign_here'; 

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
