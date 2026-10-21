import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'conference_screen.dart';

class RoomChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String adminId;
  final bool isLocked;
  final String userName;

  const RoomChatScreen({super.key, required this.roomId, required this.roomName, required this.adminId, required this.isLocked, required this.userName});

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final String? currentId = AuthService.currentUserId;
  late bool _isLocked;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.isLocked;
  }

  void _sendMessage() async {
    if (_isLocked) return;
    String text = _controller.text.trim();
    if (text.isEmpty || currentId == null) return;
    _controller.clear();
    FocusScope.of(context).unfocus();

    await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').add({
      'senderId': currentId,
      'senderName': widget.userName,
      'text': text,
      'time': FieldValue.serverTimestamp(),
    });
  }

  void _toggleLock() async {
    bool newLock = !_isLocked;
    await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).update({'isLocked': newLock});
    setState(() => _isLocked = newLock);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newLock ? 'تم قفل الدردشة' : 'تم فتح الدردشة')));
  }

  void _deleteMessage(String msgId) async {
    await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').doc(msgId).delete();
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = currentId == widget.adminId;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName),
            if (_isLocked) const Text('مغلق بواسطة الأدمن', style: TextStyle(fontSize: 10, color: Colors.red)),
          ],
        ),
        actions: [
          // 🎥 زر بدء مكالمة الفيديو
          IconButton(
            icon: const Icon(Icons.video_camera_front, color: Colors.greenAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ConferenceScreen(conferenceID: widget.roomId, userName: widget.userName)
              ));
            },
          ),
          // 🔒 زر قفل الروم (للأدمن فقط)
          if (isAdmin)
            IconButton(
              icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: _isLocked ? Colors.red : Colors.amber),
              onPressed: _toggleLock,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').orderBy('time', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                var messages = snapshot.data!.docs;
                if (messages.isEmpty) return const Center(child: Text('لا توجد رسائل بعد.', style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msgDoc = messages[index];
                    var msg = msgDoc.data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentId;

                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(msg['senderName'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                if (isAdmin && !isMe)
                                  GestureDetector(
                                    onTap: () => _deleteMessage(msgDoc.id),
                                    child: const Icon(Icons.delete, color: Colors.red, size: 16),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
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
                    enabled: !_isLocked, // تعطيل الإرسال إذا كان الروم مقفلاً
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isLocked ? 'الروم مغلق من قبل الأدمن...' : 'اكتب رسالة...',
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
                  backgroundColor: _isLocked ? Colors.grey : AppTheme.primaryColor,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _isLocked ? null : _sendMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
