import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Timer? _debounce;
  Map<String, dynamic>? _replyToMessage;

  // متغيرات الصوت
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _db.collection('chats').doc(widget.chatId).set({
      'typing': {currentId: text.isNotEmpty}
    }, SetOptions(merge: true));

    _debounce = Timer(const Duration(seconds: 2), () {
      _db.collection('chats').doc(widget.chatId).set({
        'typing': {currentId: false}
      }, SetOptions(merge: true));
    });
  }

  // 🎙️ دالة بدء التسجيل
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب السماح بالوصول للمايك')));
      }
    } catch (e) {
      print("Recording Error: $e");
    }
  }

  // ⏹️ دالة إيقاف التسجيل ورفعه
  Future<void> _stopAndSendRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        File file = File(path);
        String fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        // 1. رفع الملف إلى Firebase Storage
        final ref = _storage.ref().child('chats/${widget.chatId}/$fileName');
        await ref.putFile(file);
        String downloadUrl = await ref.getDownloadURL();

        // 2. إرسال الرسالة الصوتية
        _sendMessage(text: '🎙️ رسالة صوتية', type: 'audio', audioUrl: downloadUrl);
      }
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  void _sendMessage({String? text, String type = 'text', String? audioUrl}) async {
    String msgText = text ?? _controller.text.trim();
    if (msgText.isEmpty && audioUrl == null) return;
    
    _controller.clear();
    setState(() => _replyToMessage = null);

    Map<String, dynamic> messageData = {
      'senderId': currentId,
      'text': msgText,
      'type': type,
      if (audioUrl != null) 'audioUrl': audioUrl,
      'time': FieldValue.serverTimestamp(),
      'reactions': {},
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
        'lastMessage': type == 'audio' ? '🎙️ رسالة صوتية' : msgText,
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
      if (users.contains(currentId)) users.remove(currentId);
      else users.add(currentId!);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '👍', '😂', '🔥', '😮'].map((emoji) {
                  return GestureDetector(
                    onTap: () { Navigator.pop(context); _addReaction(msgDoc.id, emoji); },
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  );
                }).toList(),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.white),
                title: const Text('رد', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); setState(() => _replyToMessage = msg); },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('حذف الرسالة', style: TextStyle(color: Colors.redAccent)),
                  onTap: () { Navigator.pop(context); _deleteMessage(msgDoc.id); },
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
            StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('chats').doc(widget.chatId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.data() != null) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  bool isTyping = data['typing']?[widget.receiverId] ?? false;
                  if (isTyping) return const Text('يكتب الآن...', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor));
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
                    bool isAudio = msg['type'] == 'audio';

                    return GestureDetector(
                      onDoubleTap: () => _addReaction(msgDoc.id, '❤️'),
                      onLongPress: () => _showMessageOptions(msgDoc),
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
                              
                              // عرض الصوت أو النص
                              if (isAudio)
                                AudioPlayerWidget(url: msg['audioUrl'], isMe: isMe)
                              else
                                Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                              
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
                    onChanged: _onTextChanged,
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
                // 🎙️ زر المايك يظهر إذا كان الحقل فارغاً
                _controller.text.isEmpty
                    ? GestureDetector(
                        onLongPressStart: (_) => _startRecording(), // الضغط المطول لبدء التسجيل
                        onLongPressEnd: (_) => _stopAndSendRecording(), // رفع الإصبع للإرسال
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: _isRecording ? Colors.red : AppTheme.primaryColor,
                          child: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: Colors.white),
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendMessage()),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🎧 ويدجت مشغل الصوت المدمج
class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  const AudioPlayerWidget({super.key, required this.url, required this.isMe});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setUrl(widget.url);
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 30),
          onPressed: () {
            if (_isPlaying) _player.pause();
            else _player.play();
          },
        ),
        Expanded(
          child: StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? const Duration(seconds: 1);
              return LinearProgressIndicator(
                value: position.inMilliseconds / duration.inMilliseconds,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
      ],
    );
  }
}
