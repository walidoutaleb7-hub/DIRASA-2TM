import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String receiverId;

  const ChatRoomScreen({super.key, required this.chatId, required this.receiverName, required this.receiverId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final String? currentId = AuthService.currentUserId;

  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty || currentId == null) return;
    _controller.clear();

    try {
      // 1. إضافة الرسالة
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
        'senderId': currentId,
        'text': text,
        'time': FieldValue.serverTimestamp(),
      });

      // 2. تحديث بيانات المحادثة (لكي تظهر في القائمة)
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'participants': [currentId, widget.receiverId],
        'names': {currentId: 'أنا', widget.receiverId: widget.receiverName},
        'lastMessage': text,
        'lastTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إرسال الرسالة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats').doc(widget.chatId)
                  .collection('messages').orderBy('time', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                
                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // الرسائل تبدأ من الأسفل
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : AppTheme.cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isMe ? Radius.zero : const Radius.circular(20),
                            bottomRight: isMe ? const Radius.circular(20) : Radius.zero,
                          ),
                        ),
                        child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
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
                      hintText: 'اكتب رسالة...',
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
