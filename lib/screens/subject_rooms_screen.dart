import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'conference_screen.dart';

class SubjectRoomsScreen extends StatelessWidget {
  const SubjectRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = [
      {'name': 'الرياضيات', 'id': 'MATH_ROOM_2TM', 'icon': Icons.calculate, 'color': Colors.blueAccent},
      {'name': 'الفيزياء', 'id': 'PHYSICS_ROOM_2TM', 'icon': Icons.science, 'color': Colors.greenAccent},
      {'name': 'البرمجة', 'id': 'CODE_ROOM_2TM', 'icon': Icons.code, 'color': Colors.purpleAccent},
      {'name': 'المراجعة العامة', 'id': 'GENERAL_STUDY_2TM', 'icon': Icons.menu_book, 'color': Colors.orangeAccent},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('قاعات الدراسة الدائمة')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          var room = rooms[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: (room['color'] as Color).withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(room['icon'] as IconData, color: room['color'] as Color, size: 30),
              ),
              title: Text(room['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              subtitle: const Text('متاحة دائماً للدخول', style: TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ConferenceScreen(conferenceID: room['id'] as String, userName: 'طالب')));
              },
            ),
          );
        },
      ),
    );
  }
}
