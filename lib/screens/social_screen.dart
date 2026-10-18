import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_room_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});
  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _startChat(String otherUserId, String otherUserName) {
    // إنشاء معرف محادثة فريد يعتمد على ترتيب الأسماء ليكون ثابتاً دائماً
    String chatId = currentUserId.compareTo(otherUserId) < 0 
        ? '${currentUserId}_$otherUserId' 
        : '${otherUserId}_$currentUserId';
        
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          chatId: chatId,
          otherUserName: otherUserName,
          otherUserId: otherUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('زملاء القسم')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').where('uid', isNotEqualTo: currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد زملاء مسجلين بعد', style: TextStyle(color: AppTheme.textSecondary)));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                    child: Text(user['name'][0].toUpperCase(), style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('عضو في DIRASA 2TM'),
                  trailing: IconButton(
                    icon: const Icon(Icons.message_outlined, color: AppTheme.primaryColor),
                    onPressed: () => _startChat(user['uid'], user['name']),
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
