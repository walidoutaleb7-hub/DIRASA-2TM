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

  final Map<String, Uint8List?> _avatarCache = {};

  Future<Uint8List?> _getUserAvatar(String userId) async {
    if (_avatarCache.containsKey(userId)) return _avatarCache[userId];
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['profileImage'] != null) {
        final bytes = base64Decode(data['profileImage'] as String);
        _avatarCache[userId] = bytes;
        return bytes;
      }
    } catch (e) { print("Avatar Load Error: $e"); }
    _avatarCache[userId] = null;
    return null;
  }

  Widget _buildAvatar(String userId, String name) {
    return FutureBuilder<Uint8List?>(
      future: _getUserAvatar(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white12, width: 1.5), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))]),
            child: CircleAvatar(radius: 16, backgroundImage: MemoryImage(snapshot.data!)),
          );
        }
        return CircleAvatar(radius: 16, backgroundColor: AppTheme.primaryColor.withOpacity(0.2), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)));
      },
    );
  }

  Future<void> _sendMessage({String? text, String? base64Img, String? audioUrl, String type = 'text'}) async {
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
      if (users.isEmpty) { reactions.remove(emoji); } else { reactions[emoji] = users; }
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
        content: TextField(controller: editCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(filled: true, fillColor: AppTheme.bgColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () async {
            if (editCtrl.text.trim().isNotEmpty) {
              await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc(msgId).update({'text': editCtrl.text.trim(), 'isEdited': true});
            }
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('حفظ')),
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['❤️', '👍', '😂', '🔥', '😮'].map((emoji) => GestureDetector(onTap: () { Navigator.pop(context); _addReaction(msgDoc.id, emoji); }, child: Text(emoji, style: const TextStyle(fontSize: 30)))).toList()),
              const Divider(color: Colors.grey),
              ListTile(leading: const Icon(Icons.reply, color: Colors.white), title: const Text('رد', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); setState(() => _replyToMessage = msg); }),
              if (type == 'text') ListTile(leading: const Icon(Icons.copy, color: Colors.white), title: const Text('نسخ النص', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Clipboard.setData(ClipboardData(text: msg['text'] ?? '')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص'))); }),
              if (isMe && type == 'text') ListTile(leading: const Icon(Icons.edit, color: Colors.blueAccent), title: const Text('تعديل الرسالة', style: TextStyle(color: Colors.blueAccent)), onTap: () { Navigator.pop(context); _editMessage(msgDoc.id, msg['text']); }),
              if (type == 'image') ListTile(leading: const Icon(Icons.download, color: Colors.greenAccent), title: const Text('حفظ الصورة', style: TextStyle(color: Colors.greenAccent)), onTap: () { Navigator.pop(context); _downloadImage(msg['imageBase64']); }),
              if (isMe) ListTile(leading: const Icon(Icons.delete, color: Colors.redAccent), title: const Text('حذف الرسالة', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(context); _deleteMessage(msgDoc.id); }),
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
      if (match.start > lastMatchEnd) spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      final url = match.group(0)!;
      spans.add(TextSpan(text: url, style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () async {
        final Uri uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الرابط')));
        }
      }));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    if (isEdited) spans.add(const TextSpan(text: ' (معدلة)', style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)));

    return RichText(text: TextSpan(style: TextStyle(color: isMe ? Colors.white : Colors.white, fontSize: 16), children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      resizeToAvoidBottomInset: true,
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
                    bool hasReactions = reactions.values.any((list) => (list as List).isNotEmpty);

                    String senderName = isMe ? 'أنا' : widget.receiverName;

                    return Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isMe) ...[
                          _buildAvatar(msg['senderId'], senderName),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Dismissible(
                            key: Key(msgDoc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.transparent, child: const Icon(Icons.reply, color: Colors.white70, size: 30)),
                            confirmDismiss: (direction) async { setState(() => _replyToMessage = msg); return false; },
                            child: GestureDetector(
                              onDoubleTap: () => _addReaction(msgDoc.id, '❤️'),
                              onLongPress: () => _showMessageOptions(msgDoc),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: hasReactions ? 16 : 12), 
                                    padding: type == 'image' ? EdgeInsets.zero : const EdgeInsets.all(12),
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                    decoration: type == 'image' ? null : BoxDecoration(color: isMe ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isMe ? AppTheme.primaryColor : Colors.white10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (msg['replyTo'] != null)
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: isMe ? Colors.white70 : AppTheme.primaryColor, width: 3))),
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text(msg['replyTo']['senderName'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                              Text(msg['replyTo']['text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ]),
                                          ),
                                        if (type == 'image' && img != null)
                                          GestureDetector(
                                            onTap: () => showDialog(context: context, builder: (c) => Dialog(backgroundColor: Colors.transparent, child: InteractiveViewer(child: Image.memory(base64Decode(img), fit: BoxFit.contain)))),
                                            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(base64Decode(img), width: 220, fit: BoxFit.cover, cacheWidth: 400)),
                                          )
                                        else if (type == 'audio' && audio != null)
                                          AudioPlayerWidget(base64Audio: audio)
                                        else ...[
                                          _buildTextWithLinks(msg['text'] ?? '', isMe, isEdited),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (hasReactions)
                                    Positioned(
                                      bottom: -10,
                                      right: isMe ? 16 : null,
                                      left: isMe ? null : 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))]),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: reactions.entries.where((e) => (e.value as List).isNotEmpty).map((entry) {
                                          return Padding(padding: const EdgeInsets.symmetric(horizontal: 2.0), child: Text('${entry.key} ${(e.value as List).length}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)));
                                        }).toList()),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isMe) ...[
                          const SizedBox(width: 8),
                          _buildAvatar(msg['senderId'], senderName),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: AppTheme.cardColor,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('الرد على:', style: TextStyle(color: AppTheme.primaryColor, fontSize: 10)), Text(_replyToMessage!['text'] ?? 'صورة', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _replyToMessage = null)),
              ]),
            ),
          if (_isUploading) const LinearProgressIndicator(color: AppTheme.primaryColor),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8), color: AppTheme.cardColor,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.image, color: Colors.grey), onPressed: _pickImage),
                  Expanded(
                    child: TextField(
                      controller: _controller, enabled: !_isRecording, style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(hintText: _isRecording ? 'جاري التسجيل...' : 'اكتب رسالة...', hintStyle: TextStyle(color: _isRecording ? Colors.red : Colors.grey), filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20)),
                      onSubmitted: (val) => _sendMessage(text: val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _controller.text.isEmpty && !_isRecording
                      ? GestureDetector(onTap: _startRecording, child: const CircleAvatar(radius: 24, backgroundColor: AppTheme.primaryColor, child: Icon(Icons.mic, color: Colors.white)))
                      : _isRecording
                          ? GestureDetector(onTap: _stopRecording, child: const CircleAvatar(radius: 24, backgroundColor: Colors.red, child: Icon(Icons.stop, color: Colors.white)))
                          : CircleAvatar(backgroundColor: AppTheme.primaryColor, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendMessage())),
                ],
              ),
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
      width: 220, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          IconButton(icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: AppTheme.primaryColor, size: 32), onPressed: () async { if (_isPlaying) await _player.pause(); else await _player.play(); }),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor), minHeight: 4),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_formatDuration(_position), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(_formatDuration(_duration), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
