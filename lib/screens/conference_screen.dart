import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class ConferenceScreen extends StatelessWidget {
  final String conferenceID;
  final String userName;

  const ConferenceScreen({super.key, required this.conferenceID, required this.userName});

  @override
  Widget build(BuildContext context) {
    // ⚠️ ضع المفاتيح الخاصة بك هنا ⚠️
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
