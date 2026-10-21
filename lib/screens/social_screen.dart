import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'chat_room_screen.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentId = AuthService.currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('زملاء القسم')),
      body: currentId == null 
        ? const Center(child: Text('يرجى تسجيل الدخول أولاً', style: TextStyle(color: Colors.white)))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا يوجد زملاء مسجلين بعد.', style: TextStyle(color: Colors.grey)));
              }

              var users = snapshot.data!.docs.where((doc) => doc.id != currentId).toList();

              if (users.isEmpty) {
                return const Center(child: Text('أنت أول شخص يسجل في التطبيق!', style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var user = users[index].data() as Map<String, dynamic>;
                  String name = user['name'] ?? 'مستخدم';
                  String status = user['status'] ?? 'متاح';
                  bool isOnline = user['isOnline'] ?? false; // 🟢 قراءة حالة الاتصال
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                            child: Text(name[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          // 🟢 النقطة الخضراء
                          if (isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.cardColor, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(isOnline ? 'متصل الآن' : status, style: TextStyle(color: isOnline ? Colors.greenAccent : Colors.grey, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                        onPressed: () {
                          String chatId = currentId.compareTo(users[index].id) < 0 
                              ? '${currentId}_${users[index].id}' 
                              : '${users[index].id}_$currentId';
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(chatId: chatId, receiverName: name, receiverId: users[index].id)
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
