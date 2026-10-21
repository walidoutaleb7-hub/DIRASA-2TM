import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'chat_room_screen.dart';
import 'social_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  void _deleteChat(BuildContext context, String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المحادثة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentId = AuthService.currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('المحادثات'),
        actions: [
          // 🚀 تم نقل زر إضافة المحادثة هنا ليكون أنيقاً
          IconButton(
            icon: const Icon(Icons.add_comment, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialScreen()));
            },
          ),
        ],
      ),
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
                    child: Text(
                      'لا توجد محادثات حالياً.\nاذهب إلى صفحة الزملاء وابدأ محادثة جديدة.', 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.grey, height: 1.5)
                    ),
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
                    
                    String receiverId = (chat['participants'] as List).firstWhere((id) => id != currentId);
                    String receiverName = chat['names']?[receiverId] ?? 'زميل';

                    return Dismissible(
                      key: Key(chatId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: AppTheme.cardColor,
                              title: const Text("حذف المحادثة", style: TextStyle(color: Colors.white)),
                              content: const Text("هل أنت متأكد من حذف هذه المحادثة؟", style: TextStyle(color: Colors.grey)),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("إلغاء")),
                                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("حذف", style: TextStyle(color: Colors.red))),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) => _deleteChat(context, chatId),
                      child: Container(
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
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
