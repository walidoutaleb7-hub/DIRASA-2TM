import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'conference_screen.dart';

class SubjectRoomDetailScreen extends StatefulWidget {
  final String subjectName;
  final String roomId;
  const SubjectRoomDetailScreen({super.key, required this.subjectName, required this.roomId});

  @override
  State<SubjectRoomDetailScreen> createState() => _SubjectRoomDetailScreenState();
}

class _SubjectRoomDetailScreenState extends State<SubjectRoomDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final String? currentId = AuthService.currentUserId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    AuthService.getUserName().then((name) => setState(() => _userName = name ?? 'طالب'));
  }

  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty || currentId == null) return;
    _controller.clear();

    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('messages').add({
      'senderId': currentId,
      'senderName': _userName ?? 'طالب',
      'text': text,
      'time': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.greenAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ConferenceScreen(conferenceID: widget.roomId, userName: _userName ?? 'طالب')
              ));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('messages').orderBy('time', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                
                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentId;
                    String text = msg['text'] ?? '';
                    
                    // 🔍 كشف روابط اليوتيوب
                    bool isYoutube = text.contains('youtube.com') || text.contains('youtu.be');
                    String? videoId;
                    if (isYoutube) {
                      final regExp = RegExp(r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})');
                      final match = regExp.firstMatch(text);
                      if (match != null) videoId = match.group(1);
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isMe ? AppTheme.primaryColor : Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg['senderName'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            if (isYoutube && videoId != null)
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: YoutubePlayer(
                                  controller: YoutubePlayerController.fromVideoId(
                                    videoId: videoId,
                                    autoPlay: false,
                                    params: const YoutubePlayerParams(showFullscreenButton: true),
                                  ),
                                ),
                              )
                            else
                              Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة أو ألصق رابط يوتيوب...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: AppTheme.bgColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
