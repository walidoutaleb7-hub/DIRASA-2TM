import 'dart:async';
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
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _debounce;
  
  Map<String, dynamic>? _replyToMessage;

  void _onTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // تحديث حالة الكتابة في Firebase
    _db.collection('chats').doc(widget.chatId).set({
      'typing': {currentId: text.isNotEmpty}
    }, SetOptions(merge: true));

    _debounce = Timer(const Duration(seconds: 2), () {
      _db.collection('chats').doc(widget.chatId).set({
        'typing': {currentId: false}
      }, SetOptions(merge: true));
    });
  }

  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty || currentId == null) return;
    _controller.clear();
    setState(() => _replyToMessage = null);

    Map<String, dynamic> messageData = {
      'senderId': currentId,
      'text': text,
      'time': FieldValue.serverTimestamp(),
      'reactions': {}, // مصفوفة فارغة للتفاعلات
    };

    if (_replyToMessage != null) {
      messageData['replyTo'] = {
        'text': _replyToMessage!['text'],
        'senderName': _replyToMessage!['senderId'] == currentId ? 'أنت' : widget.receiverName,
      };
    }

    try {
      await _db.collection('chats').doc(widget.chatId).collection('messages').add(messageData);

      await _db.collection('chats').doc(widget.chatId).set({
        'participants': [currentId, widget.receiverId],
        'names': {currentId: 'أنا', widget.receiverId: widget.receiverName},
        'lastMessage': text,
        'lastTime': FieldValue.serverTimestamp(),
        'typing': {currentId: false}
      }, SetOptions(merge: true));
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إرسال الرسالة')));
    }
  }

  void _addReaction(String messageId, String emoji) async {
    var msgRef = _db.collection('chats').doc(widget.chatId).collection('messages').doc(messageId);
    await _db.runTransaction((transaction) async {
      var snapshot = await transaction.get(msgRef);
      Map<String, dynamic> reactions = snapshot.data()?['reactions'] ?? {};
      List<String> users = List<String>.from(reactions[emoji] ?? []);
      
      if (users.contains(currentId)) {
        users.remove(currentId); // إزالة التفاعل إذا كان موجوداً
      } else {
        users.add(currentId!); // إضافة التفاعل
      }
      
      reactions[emoji] = users;
      transaction.update(msgRef, {'reactions': reactions});
    });
  }

  void _deleteMessage(String messageId) async {
    await _db.collection('chats').doc(widget.chatId).collection('messages').doc(messageId).delete();
  }

  void _showMessageOptions(DocumentSnapshot msgDoc) {
    var msg = msgDoc.data() as Map<String, dynamic>;
    bool isMe = msg['senderId'] == currentId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // التفاعلات السريعة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '👍', '😂', '🔥', '😮'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _addReaction(msgDoc.id, emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  );
                }).toList(),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.white),
                title: const Text('رد', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyToMessage = msg);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('حذف الرسالة', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(msgDoc.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            // مؤشر الكتابة
            StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('chats').doc(widget.chatId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.data() != null) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  bool isTyping = data['typing']?[widget.receiverId] ?? false;
                  if (isTyping) {
                    return const Text('يكتب الآن...', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor));
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('chats').doc(widget.chatId).collection('messages').orderBy('time', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                
                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msgDoc = messages[index];
                    var msg = msgDoc.data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentId;
                    Map<String, dynamic> reactions = msg['reactions'] ?? {};
                    
                    return GestureDetector(
                      onDoubleTap: () => _addReaction(msgDoc.id, '❤️'), // دبل كليك للقلب
                      onLongPress: () => _showMessageOptions(msgDoc), // ضغط مطول للخيارات
                      child: Align(
                        alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primaryColor : AppTheme.cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isMe ? Radius.zero : const Radius.circular(20),
                              bottomRight: isMe ? const Radius.circular(20) : Radius.zero,
                            ),
                            border: isMe ? null : Border.all(color: Colors.grey.shade800),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // عرض الرد
                              if (msg['replyTo'] != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border(left: BorderSide(color: isMe ? Colors.white70 : AppTheme.primaryColor, width: 3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(msg['replyTo']['senderName'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text(msg['replyTo']['text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              
                              // نص الرسالة
                              Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                              
                              // عرض التفاعلات
                              if (reactions.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 4,
                                    children: reactions.entries.where((e) => (e.value as List).isNotEmpty).map((entry) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                                        child: Text('${entry.key} ${(entry.value as List).length}', style: const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // شريط الرد
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الرد على:', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                        Text(_replyToMessage!['text'], style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _replyToMessage = null)),
                ],
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
                    onChanged: _onTextChanged, // لتشغيل مؤشر الكتابة
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
