import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_room_screen.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colleagues = [
      {'name': 'أحمد محمد', 'status': 'أدرس رياضيات الآن', 'color': Colors.blueAccent},
      {'name': 'سارة علي', 'status': 'متاحة للمراجعة', 'color': Colors.pinkAccent},
      {'name': 'ياسين خالد', 'status': 'غائب', 'color': Colors.orangeAccent},
      {'name': 'ليلى يوسف', 'status': 'في قاعة الفيزياء', 'color': Colors.greenAccent},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('زملاء القسم')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: colleagues.length,
        itemBuilder: (context, index) {
          var user = colleagues[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: (user['color'] as Color).withOpacity(0.2),
                child: Text(user['name'].toString()[0], style: TextStyle(color: user['color'] as Color, fontWeight: FontWeight.bold)),
              ),
              title: Text(user['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(user['status'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(name: user['name'] as String))),
              ),
            ),
          );
        },
      ),
    );
  }
}
