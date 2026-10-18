import 'dart:convert';
import 'dart:typed_data';
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
    String chatId = currentUserId.compareTo(otherUserId) < 0 
        ? '${currentUserId}_$otherUserId' 
        : '${otherUserId}_$currentUserId';
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(chatId: chatId, otherUserName: otherUserName, otherUserId: otherUserId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('زملاء القسم')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').where('uid', isNotEqualTo: currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا يوجد زملاء مسجلين بعد'));

          var users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              
              Uint8List? imageBytes;
              if (user['profileImage'] != null && user['profileImage'].toString().isNotEmpty) {
                imageBytes = base64Decode(user['profileImage']);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                    child: imageBytes == null ? Text(user['name'][0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)) : null,
                  ),
                  title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user['status'] ?? 'متاح للدراسة', style: const TextStyle(color: AppTheme.textSecondary)),
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
