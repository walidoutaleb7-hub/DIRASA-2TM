import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
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
  Map<String, dynamic>? _replyToMessage;
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  final RegExp _urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');

  void _sendMessage({String? text, String? base64Img, String? audioUrl, String type = 'text'}) async {
    String msgText = text ?? _controller.text.trim();
    if (msgText.isEmpty && base64Img == null && audioUrl == null) return;
    if (base64Img == null && audioUrl == null) _controller.clear();
    
    setState(() => _replyToMessage = null);
    FocusScope.of(context).unfocus();

    Map<String, dynamic> msgData = {
      'senderId': currentId, 'text': msgText,
      'type': type, 'imageBase64': base64Img, 'audioUrl': audioUrl, 
      'reactions': {}, 'isEdited': false, 'time': FieldValue.serverTimestamp(),
    };

    if (_replyToMessage != null) {
      msgData['replyTo'] = {
        'text': _replyToMessage!['text'] ?? 'صورة',
        'senderName': _replyToMessage!['senderId'] == currentId ? 'أنت' : widget.receiverName,
      };
    }

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add(msgData);
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'participants': [currentId, widget.receiverId],
      'names': {currentId: 'أنا', widget.receiverId: widget.receiverName},
      'lastMessage': type == 'image' ? '📸 صورة' : (type == 'audio' ? '🎙️ رسالة صوتية' : msgText),
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20, maxWidth: 400);
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      final bytes = await pickedFile.readAsBytes();
      await _sendMessage(base64Img: base64Encode(bytes), type: 'image');
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        setState(() => _isRecording = true);
      }
    } catch (e) { print("Recording Error: $e"); }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        File file = File(path);
        String base64Audio = base64Encode(await file.readAsBytes());
        await _sendMessage(audioUrl: base64Audio, type: 'audio');
      }
    } catch (e) { print("Upload Error: $e"); }
  }

  void _addReaction(String msgId, String emoji) async {
    var msgRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc(msgId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var snapshot = await transaction.get(msgRef);
      Map<String, dynamic> reactions = snapshot.data()?['reactions'] ?? {};
      List<String> users = List<String>.from(reactions[emoji] ?? []);
      if (users.contains(currentId)) users.remove(currentId); else users.add(currentId!);
      reactions[emoji] = users;
      transaction.update(msgRef, {'reactions': reactions});
    });
  }

  void _deleteMessage(String msgId) async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc(msgId).delete();
  }

  void _downloadImage(String base64Img) async {
    try {
      Uint8List bytes = base64Decode(base64Img);
      await Gal.putImageBytes(bytes, name: 'dirasa_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الصورة في المعرض!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
    }
  }

  void _editMessage(String msgId, String oldText) {
    TextEditingController editCtrl = TextEditingController(text: oldText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('تعديل الرسالة', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(filled: true, fillColor: AppTheme.bgColor),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (editCtrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc(msgId).update({
                  'text': editCtrl.text.trim(),
                  'isEdited': true,
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(DocumentSnapshot msgDoc) {
    var msg = msgDoc.data() as Map<String, dynamic>;
    bool isMe = msg['senderId'] == currentId;
    String type = msg['type'] ?? 'text';

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
              if (type == 'text')
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.white),
                  title: const Text('نسخ النص', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص')));
                  },
                ),
              if (isMe && type == 'text')
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blueAccent),
                  title: const Text('تعديل الرسالة', style: TextStyle(color: Colors.blueAccent)),
                  onTap: () { Navigator.pop(context); _editMessage(msgDoc.id, msg['text']); },
                ),
              if (type == 'image')
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.greenAccent),
                  title: const Text('حفظ الصورة', style: TextStyle(color: Colors.greenAccent)),
                  onTap: () { Navigator.pop(context); _downloadImage(msg['imageBase64']); },
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

  Widget _buildTextWithLinks(String text, bool isMe, bool isEdited) {
    final List<TextSpan> spans = [];
    final matches = _urlRegExp.allMatches(text);
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()..onTap = () async {
          final Uri uri = Uri.parse(url);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الرابط')));
          }
        },
      ));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    if (isEdited) {
      spans.add(const TextSpan(text: ' (معدلة)', style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: isMe ? Colors.white : Colors.white, fontSize: 16),
        children: spans,
      ),
    );
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
                    var msgDoc = messages[index];
                    var msg = msgDoc.data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentId;
                    String type = msg['type'] ?? 'text';
                    String? img = msg['imageBase64'];
                    String? audio = msg['audioUrl'];
                    Map<String, dynamic> reactions = msg['reactions'] ?? {};
                    bool isEdited = msg['isEdited'] ?? false;

                    return GestureDetector(
                      onDoubleTap: () => _addReaction(msgDoc.id, '❤️'),
                      onLongPress: () => _showMessageOptions(msgDoc),
                      child: Align(
                        alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12), 
                          padding: type == 'image' ? EdgeInsets.zero : const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: type == 'image' ? null : BoxDecoration(
                            color: isMe ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor, 
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: isMe ? AppTheme.primaryColor : Colors.white10)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg['replyTo'] != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: isMe ? Colors.white70 : AppTheme.primaryColor, width: 3))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(msg['replyTo']['senderName'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                      Text(msg['replyTo']['text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              if (type == 'image' && img != null)
                                GestureDetector(
                                  onTap: () => showDialog(context: context, builder: (c) => Dialog(backgroundColor: Colors.transparent, child: InteractiveViewer(child: Image.memory(base64Decode(img), fit: BoxFit.contain)))),
                                  child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(base64Decode(img), width: 220, fit: BoxFit.cover)),
                                )
                              else if (type == 'audio' && audio != null)
                                AudioPlayerWidget(base64Audio: audio)
                              else ...[
                                _buildTextWithLinks(msg['text'] ?? '', isMe, isEdited),
                              ],
                              if (reactions.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Wrap(
                                    spacing: 4,
                                    children: reactions.entries.where((e) => (e.value as List).isNotEmpty).map((entry) {
                                      return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)), child: Text('${entry.key} ${(entry.value as List).length}', style: const TextStyle(fontSize: 10)));
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
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('الرد على:', style: TextStyle(color: AppTheme.primaryColor, fontSize: 10)), Text(_replyToMessage!['text'] ?? 'صورة', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                  IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _replyToMessage = null)),
                ],
              ),
            ),
          if (_isUploading) const LinearProgressIndicator(color: AppTheme.primaryColor),
          if (_isRecording) Container(padding: const EdgeInsets.all(8), color: Colors.red.withOpacity(0.2), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mic, color: Colors.red), SizedBox(width: 8), Text('جاري التسجيل...', style: TextStyle(color: Colors.red))])),
          Container(
            padding: const EdgeInsets.all(8), color: AppTheme.cardColor,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image, color: Colors.grey), onPressed: _pickImage),
                Expanded(
                  child: TextField(
                    controller: _controller, style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20)),
                    onSubmitted: (val) => _sendMessage(text: val),
                  ),
                ),
                const SizedBox(width: 8),
                _controller.text.isEmpty 
                    ? GestureDetector(
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressEnd: (_) => _stopRecording(),
                        child: CircleAvatar(radius: 24, backgroundColor: _isRecording ? Colors.red : AppTheme.primaryColor, child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white)),
                      )
                    : CircleAvatar(backgroundColor: AppTheme.primaryColor, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendMessage())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String base64Audio;
  const AudioPlayerWidget({super.key, required this.base64Audio});
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
    _player.playerStateStream.listen((state) { if (mounted) setState(() => _isPlaying = state.playing); });
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 30),
          onPressed: () async {
            if (_isPlaying) { await _player.pause(); }
            else {
              if (_player.audioSource == null) {
                final bytes = base64Decode(widget.base64Audio);
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/temp_audio.m4a');
                await file.writeAsBytes(bytes);
                await _player.setFilePath(file.path);
              }
              await _player.play();
            }
          },
        ),
        const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
      ],
    );
  }
}
