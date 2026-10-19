import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentId = AuthService.currentUserId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('المحادثات')),
      body: currentId == null
          ? const Center(child: Text('يرجى تسجيل الدخول أولاً', style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentId)
                  .orderBy('lastTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد محادثات.\nاذهب لصفحة الزملاء لبدء محادثة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  );
                }

                var chats = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    var chat = chats[index].data() as Map<String, dynamic>;
                    String chatId = chats[index].id;
                    String lastMsg = chat['lastMessage'] ?? 'بدء محادثة';
                    
                    // استخراج اسم الطرف الآخر
                    String receiverId = (chat['participants'] as List).firstWhere((id) => id != currentId);
                    String receiverName = chat['names']?[receiverId] ?? 'زميل';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.2), child: const Icon(Icons.person, color: AppTheme.primaryColor)),
                        title: Text(receiverName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              chatId: chatId, 
                              receiverName: receiverName, 
                              receiverId: receiverId
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
