import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('المحادثات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildChatTile(context, 'أحمد محمد', 'هل راجعت درس الفيزياء؟', '10:30 ص'),
          _buildChatTile(context, 'سارة علي', 'شكراً على الملخص!', 'أمس'),
          _buildChatTile(context, 'مجموعة القسم', 'تم إنشاء غرفة مراجعة جديدة', 'أمس'),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, String name, String message, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.2), child: const Icon(Icons.person, color: AppTheme.primaryColor)),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
        trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(name: name))),
      ),
    );
  }
}
