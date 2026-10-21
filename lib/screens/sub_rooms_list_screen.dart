import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'room_chat_screen.dart';

class SubRoomsListScreen extends StatefulWidget {
  final String subjectName;
  final String subjectId;
  const SubRoomsListScreen({super.key, required this.subjectName, required this.subjectId});

  @override
  State<SubRoomsListScreen> createState() => _SubRoomsListScreenState();
}

class _SubRoomsListScreenState extends State<SubRoomsListScreen> {
  final String? currentId = AuthService.currentUserId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    AuthService.getUserName().then((name) => setState(() => _userName = name ?? 'طالب'));
  }

  void _createRoom() {
    TextEditingController nameController = TextEditingController();
    TextEditingController passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('إنشاء روم جديد', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'اسم الروم', hintStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: const InputDecoration(hintText: 'كلمة المرور (اختياري)', hintStyle: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                String roomId = DateTime.now().millisecondsSinceEpoch.toString();
                await FirebaseFirestore.instance.collection('study_rooms').doc(roomId).set({
                  'roomId': roomId, 'subject': widget.subjectId, 'name': nameController.text.trim(),
                  'adminId': currentId, 'adminName': _userName, 'isLocked': false,
                  'password': passController.text.trim(), 'bannedUsers': [], 'createdAt': FieldValue.serverTimestamp(),
                });
              } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'))); }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _enterRoom(Map<String, dynamic> room) async {
    bool isLocked = room['isLocked'] ?? false;
    bool isAdmin = room['adminId'] == currentId;
    String password = room['password'] ?? '';
    List<dynamic> bannedUsers = room['bannedUsers'] ?? [];

    // 🚀 منع الدخول إذا كان الروم مغلقاً
    if (isLocked && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، هذا الروم مغلق حالياً من قبل المشرف.')));
      return;
    }

    // 🚀 منع الدخول إذا كان محظوراً
    if (bannedUsers.contains(currentId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حظرك من دخول هذا الروم.')));
      return;
    }

    // 🚀 التحقق من كلمة المرور
    if (password.isNotEmpty && !isAdmin) {
      TextEditingController passInput = TextEditingController();
      bool? correct = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('الروم محمي بكلمة مرور', style: TextStyle(color: Colors.white)),
          content: TextField(controller: passInput, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'أدخل كلمة المرور', hintStyle: TextStyle(color: Colors.grey))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (passInput.text == password) { Navigator.pop(context, true); } 
                else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور خاطئة!'))); }
              },
              child: const Text('دخول'),
            ),
          ],
        ),
      );
      if (correct != true) return;
    }

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => RoomChatScreen(
          roomId: room['roomId'], roomName: room['name'], adminId: room['adminId'], isLocked: isLocked, userName: _userName ?? 'طالب',
        )
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: Text('رومات ${widget.subjectName}')),
      floatingActionButton: FloatingActionButton(backgroundColor: AppTheme.primaryColor, onPressed: _createRoom, child: const Icon(Icons.add, color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('study_rooms').where('subject', isEqualTo: widget.subjectId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد رومات حالياً.', style: TextStyle(color: Colors.grey)));

          var rooms = snapshot.data!.docs.toList();
          rooms.sort((a, b) {
            var t1 = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            var t2 = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var room = rooms[index].data() as Map<String, dynamic>;
              bool isLocked = room['isLocked'] ?? false;
              bool isAdmin = room['adminId'] == currentId;
              bool isProtected = (room['password'] ?? '').isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(backgroundColor: isLocked ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2), child: Icon(isLocked ? Icons.lock : Icons.meeting_room, color: isLocked ? Colors.red : Colors.greenAccent)),
                  title: Row(children: [Text(room['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), if (isProtected) ...[const SizedBox(width: 8), const Icon(Icons.password, color: Colors.orange, size: 16)]]),
                  subtitle: Text('الأدمن: ${room['adminName']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: isAdmin ? const Icon(Icons.admin_panel_settings, color: Colors.amber) : null,
                  onTap: () => _enterRoom(room),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
