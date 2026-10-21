import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.isLocked;
  }

  void _sendMessage({String? text, String? fileUrl, String type = 'text'}) async {
    if (_isLocked) return;
    String msgText = text ?? _controller.text.trim();
    if (msgText.isEmpty && fileUrl == null) return;
    if (fileUrl == null) _controller.clear();
    
    FocusScope.of(context).unfocus();

    await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').add({
      'senderId': currentId,
      'senderName': widget.userName,
      'text': msgText,
      'type': type,
      'fileUrl': fileUrl,
      'time': FieldValue.serverTimestamp(),
    });
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() => _isUploading = true);
      File file = File(image.path);
      
      try {
        String storagePath = 'rooms/${widget.roomId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(storagePath).putFile(file);
        String url = await snapshot.ref.getDownloadURL();
        
        _sendMessage(text: 'صورة', fileUrl: url, type: 'image');
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الرفع: $e')));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _deleteMessage(String msgId) async {
    await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').doc(msgId).delete();
  }

  void _deleteRoom() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('حذف الروم', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد؟ سيتم حذف الروم وجميع رسائله نهائياً.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = currentId == widget.adminId;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.roomName),
          if (_isLocked) const Text('مغلق', style: TextStyle(fontSize: 10, color: Colors.red)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.video_camera_front, color: Colors.greenAccent), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ConferenceScreen(conferenceID: widget.roomId, userName: widget.userName)));
          }),
          if (isAdmin) ...[
            IconButton(icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: _isLocked ? Colors.red : Colors.amber), onPressed: () async {
              bool newLock = !_isLocked;
              await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).update({'isLocked': newLock});
              setState(() => _isLocked = newLock);
            }),
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: _deleteRoom),
          ],
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
                  reverse: true, padding: const EdgeInsets.all(16), itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msgDoc = messages[index];
                    var msg = msgDoc.data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentId;
                    String type = msg['type'] ?? 'text';

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(msg['senderName'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                if (isAdmin && !isMe)
                                  GestureDetector(onTap: () => _deleteMessage(msgDoc.id), child: const Icon(Icons.delete, color: Colors.red, size: 16)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (type == 'image')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(msg['fileUrl'], width: 200, fit: BoxFit.cover),
                              )
                            else
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
          if (_isUploading) const LinearProgressIndicator(color: AppTheme.primaryColor),
          Container(
            padding: const EdgeInsets.all(8),
            color: AppTheme.cardColor,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image, color: Colors.grey), onPressed: _isLocked ? null : _pickImage),
                Expanded(
                  child: TextField(
                    controller: _controller, enabled: !_isLocked, style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isLocked ? 'الروم مغلق...' : 'اكتب رسالة...', hintStyle: const TextStyle(color: Colors.grey),
                      filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isLocked ? Colors.grey : AppTheme.primaryColor,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _isLocked ? null : () => _sendMessage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
