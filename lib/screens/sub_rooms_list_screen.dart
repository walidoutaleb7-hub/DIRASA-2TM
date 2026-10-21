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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('إنشاء روم جديد', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'اسم الروم (مثال: مراجعة شاملة)', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              
              String roomId = DateTime.now().millisecondsSinceEpoch.toString();
              await FirebaseFirestore.instance.collection('study_rooms').doc(roomId).set({
                'roomId': roomId,
                'subject': widget.subjectId,
                'name': nameController.text.trim(),
                'adminId': currentId,
                'adminName': _userName,
                'isLocked': false,
                'createdAt': FieldValue.serverTimestamp(),
              });
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: Text('رومات ${widget.subjectName}')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: _createRoom,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('study_rooms').where('subject', isEqualTo: widget.subjectId).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد رومات حالياً. أنشئ رومك الأول!', style: TextStyle(color: Colors.grey)));

          var rooms = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var room = rooms[index].data() as Map<String, dynamic>;
              bool isLocked = room['isLocked'] ?? false;
              bool isAdmin = room['adminId'] == currentId;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isLocked ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    child: Icon(isLocked ? Icons.lock : Icons.meeting_room, color: isLocked ? Colors.red : Colors.greenAccent),
                  ),
                  title: Text(room['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('الأدمن: ${room['adminName']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: isAdmin ? const Icon(Icons.admin_panel_settings, color: Colors.amber) : null,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => RoomChatScreen(
                        roomId: room['roomId'],
                        roomName: room['name'],
                        adminId: room['adminId'],
                        isLocked: isLocked,
                        userName: _userName ?? 'طالب',
                      )
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
