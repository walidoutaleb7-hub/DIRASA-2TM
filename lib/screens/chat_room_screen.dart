import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isUploading = false;

  void _sendMessage({String? text, String? base64Img}) async {
    if (text == null && base64Img == null) return;
    _controller.clear();
    
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
      'senderId': currentId,
      'text': text,
      'imageBase64': base64Img,
      'time': FieldValue.serverTimestamp(),
    });
    
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'participants': [currentId, widget.receiverId],
      'names': {currentId: 'أنا', widget.receiverId: widget.receiverName},
      'lastMessage': base64Img != null ? '📸 صورة' : text,
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20, maxWidth: 400);
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      final bytes = await pickedFile.readAsBytes();
      String base64Img = base64Encode(bytes);
      await _sendMessage(base64Img: base64Img);
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('time', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true, padding: const EdgeInsets.all(16), itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentId;
                    String? img = msg['imageBase64'];

                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16), border: Border.all(color: isMe ? AppTheme.primaryColor : Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (img != null)
                              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(base64Decode(img), width: 200, fit: BoxFit.cover)),
                            if (msg['text'] != null && msg['text'].isNotEmpty) ...[
                              if (img != null) const SizedBox(height: 8),
                              Text(msg['text'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(color: AppTheme.primaryColor),
          Container(
            padding: const EdgeInsets.all(8), color: AppTheme.cardColor,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image, color: Colors.grey), onPressed: _isUploading ? null : _pickImage),
                Expanded(
                  child: TextField(
                    controller: _controller, style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20)),
                    onSubmitted: (val) => _sendMessage(text: val),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(backgroundColor: AppTheme.primaryColor, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendMessage(text: _controller.text))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
