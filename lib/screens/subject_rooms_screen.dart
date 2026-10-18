import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'conference_screen.dart';
import '../services/auth_service.dart';

class SubjectRoomsScreen extends StatelessWidget {
  const SubjectRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = [
      {'name': 'غرفة الرياضيات', 'id': 'MATH_ROOM_2TM', 'icon': Icons.calculate, 'color': Colors.blueAccent},
      {'name': 'غرفة الفيزياء', 'id': 'PHYSICS_ROOM_2TM', 'icon': Icons.science, 'color': Colors.greenAccent},
      {'name': 'غرفة البرمجة', 'id': 'CODE_ROOM_2TM', 'icon': Icons.code, 'color': Colors.purpleAccent},
      {'name': 'قاعة المراجعة العامة', 'id': 'GENERAL_STUDY_2TM', 'icon': Icons.menu_book, 'color': Colors.orangeAccent},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('قاعات الدراسة الدائمة')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          var room = rooms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: (room['color'] as Color).withOpacity(0.2),
                child: Icon(room['icon'] as IconData, color: room['color'] as Color, size: 30),
              ),
              title: Text(room['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text('متاحة دائماً للدخول', style: TextStyle(color: AppTheme.textSecondary)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                String userName = await AuthService.getUserName() ?? 'طالب';
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ConferenceScreen(conferenceID: room['id'] as String, userName: userName)));
                }
              },
            ),
          );
        },
      ),
    );
  }
}
