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
  Map<String, dynamic>? _replyToMessage;
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  final RegExp _urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');

  @override
  void initState() { super.initState(); _isLocked = widget.isLocked; }

  Future<void> _sendMessage({String? text, String? base64Img, String? audioUrl, String type = 'text'}) async {
    if (_isLocked) return;
    String msgText = text ?? _controller.text.trim();
    if (msgText.isEmpty && base64Img == null && audioUrl == null) return;
    if (base64Img == null && audioUrl == null) _controller.clear();
    
    setState(() => _replyToMessage = null);
    FocusScope.of(context).unfocus();

    Map<String, dynamic> msgData = {
      'senderId': currentId, 'senderName': widget.userName, 'text': msgText,
      'type': type, 'imageBase64': base64Img, 'audioUrl': audioUrl, 
      'reactions': {}, 'isEdited': false, 'time': FieldValue.serverTimestamp(),
    };

    if (_replyToMessage != null) {
      msgData['replyTo'] = {
        'text': _replyToMessage!['text'] ?? 'صورة',
        'senderName': _replyToMessage!['senderId'] == currentId ? 'أنت' : _replyToMessage!['senderName'],
      };
    }

    await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').add(msgData);
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
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب السماح بالوصول للمايك')));
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
    var msgRef = FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').doc(msgId);
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
    await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').doc(msgId).delete();
  }

  void _deleteRoom() async {
    bool confirm = await showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: AppTheme.cardColor, title: const Text('حذف الروم', style: TextStyle(color: Colors.white)), content: const Text('هل أنت متأكد؟', style: TextStyle(color: Colors.grey)), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])) ?? false;
    if (confirm) { await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).delete(); if (mounted) Navigator.pop(context); }
  }

  void _toggleLock() async {
    bool newLock = !_isLocked;
    await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).update({'isLocked': newLock});
    setState(() => _isLocked = newLock);
  }

  void _kickUser(String userId) async {
    var roomRef = FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId);
    await roomRef.update({'bannedUsers': FieldValue.arrayUnion([userId])});
    var messages = await roomRef.collection('messages').where('senderId', isEqualTo: userId).get();
    for (var doc in messages.docs) { await doc.reference.delete(); }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حظر العضو وحذف رسائله.')));
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
                await FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId).collection('messages').doc(msgId).update({
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
    bool isAdmin = currentId == widget.adminId;
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
              if (isMe || isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('حذف الرسالة', style: TextStyle(color: Colors.redAccent)),
                  onTap: () { Navigator.pop(context); _deleteMessage(msgDoc.id); },
                ),
              if (isAdmin && !isMe)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.orangeAccent),
                  title: const Text('حظر العضو', style: TextStyle(color: Colors.orangeAccent)),
                  onTap: () { Navigator.pop(context); _kickUser(msg['senderId']); },
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
    bool isAdmin = currentId == widget.adminId;
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      resizeToAvoidBottomInset: true, // 🚀 إصلاح جلتش الكيبورد
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.roomName), 
          if (_isLocked) const Text('مغلق', style: TextStyle(fontSize: 10, color: Colors.red))
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.video_camera_front, color: Colors.greenAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConferenceScreen(conferenceID: widget.roomId, userName: widget.userName)))),
          if (isAdmin) ...[
            IconButton(icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: _isLocked ? Colors.red : Colors.amber), onPressed: _toggleLock),
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
                    String? img = msg['imageBase64'];
                    String? audio = msg['audioUrl'];
                    Map<String, dynamic> reactions = msg['reactions'] ?? {};
                    bool isEdited = msg['isEdited'] ?? false;

                    return GestureDetector(
                      onDoubleTap: () => _addReaction(msgDoc.id, '❤️'),
                      onLongPress: () => _showMessageOptions(msgDoc),
                      child: Align(
                        alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: reactions.isNotEmpty ? 16 : 12), 
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
                                      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(base64Decode(img), width: 220, fit: BoxFit.cover, cacheWidth: 400)), // 🚀 إصلاح تجمد الصورة
                                    )
                                  else if (type == 'audio' && audio != null)
                                    AudioPlayerWidget(base64Audio: audio)
                                  else ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(msg['senderName'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    _buildTextWithLinks(msg['text'] ?? '', isMe, isEdited),
                                  ],
                                ],
                              ),
                            ),
                            // 🚀 التفاعلات تظهر كشارة أسفل الرسالة
                            if (reactions.isNotEmpty)
                              Positioned(
                                bottom: -8,
                                right: isMe ? 16 : null,
                                left: isMe ? null : 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: reactions.entries.where((e) => (e.value as List).isNotEmpty).map((entry) {
                                      return Text('${entry.key} ${(entry.value as List).length}', style: const TextStyle(fontSize: 12, color: Colors.white));
                                    }).toList(),
                                  ),
                                ),
                              ),
                          ],
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
          // 🚀 شريط الإدخال والمايك (نظام الضغط للبدء والإيقاف)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8), color: AppTheme.cardColor,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.image, color: Colors.grey), onPressed: _isLocked ? null : _pickImage),
                  Expanded(
                    child: TextField(
                      controller: _controller, enabled: !_isLocked && !_isRecording, style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _isLocked ? 'الروم مغلق...' : (_isRecording ? 'جاري التسجيل...' : 'اكتب رسالة...'), 
                        hintStyle: TextStyle(color: _isRecording ? Colors.red : Colors.grey), 
                        filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20)
                      ),
                      onSubmitted: (val) => _sendMessage(text: val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _controller.text.isEmpty && !_isRecording
                      ? GestureDetector(
                          onTap: _startRecording, // 🚀 ضغطة واحدة للبدء
                          child: CircleAvatar(radius: 24, backgroundColor: _isLocked ? Colors.grey : AppTheme.primaryColor, child: const Icon(Icons.mic, color: Colors.white)),
                        )
                      : _isRecording
                          ? GestureDetector(
                              onTap: _stopRecording, // 🚀 ضغطة واحدة للإيقاف
                              child: const CircleAvatar(radius: 24, backgroundColor: Colors.red, child: Icon(Icons.stop, color: Colors.white)),
                            )
                          : CircleAvatar(backgroundColor: _isLocked ? Colors.grey : AppTheme.primaryColor, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _isLocked ? null : () => _sendMessage())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🚀 مشغل صوت محسن مع شريط تقدم ومدة
class AudioPlayerWidget extends StatefulWidget {
  final String base64Audio;
  const AudioPlayerWidget({super.key, required this.base64Audio});
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    
    _player.durationStream.listen((d) { if (mounted && d != null) setState(() => _duration = d); });
    _player.positionStream.listen((p) { if (mounted) setState(() => _position = p); });
    _player.playerStateStream.listen((state) { if (mounted) setState(() => _isPlaying = state.playing); });

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      final bytes = base64Decode(widget.base64Audio);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await file.writeAsBytes(bytes);
      await _player.setFilePath(file.path);
    } catch (e) { print("Audio Load Error: $e"); }
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: AppTheme.primaryColor, size: 32),
            onPressed: () async { if (_isPlaying) await _player.pause(); else await _player.play(); },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(_formatDuration(_duration), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
