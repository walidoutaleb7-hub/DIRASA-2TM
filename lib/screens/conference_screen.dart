import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class ConferenceScreen extends StatelessWidget {
  final String conferenceID;
  final String userName;

  const ConferenceScreen({super.key, required this.conferenceID, required this.userName});

  @override
  Widget build(BuildContext context) {
    const int appID = 123456789; // ضع AppID هنا
    const String appSign = 'your_app_sign_here'; // ضع AppSign هنا

    return SafeArea(
      child: ZegoUIKitPrebuiltVideoConference(
        appID: appID,
        appSign: appSign,
        userID: userName.replaceAll(' ', '_'),
        userName: userName,
        conferenceID: conferenceID,
        config: ZegoUIKitPrebuiltVideoConferenceConfig(
          // التصحيح: استخدام preset1080P() بدلاً من المعامل resolution
          video: ZegoUIKitVideoConfig.preset1080P(),
          bottomMenuBarConfig: ZegoBottomMenuBarConfig(
            buttons: [
              ZegoMenuBarButtonName.chatButton,
              ZegoMenuBarButtonName.toggleScreenSharingButton,
              ZegoMenuBarButtonName.toggleMicrophoneButton,
              ZegoMenuBarButtonName.switchCameraButton,
            ],
          ),
          // التصحيح: استخدام معامل layout بشكل صحيح
          layout: ZegoLayout.gallery(
            showNewScreenSharingViewInFullscreenMode: true,
          ),
        ),
      ),
    );
  }
}
