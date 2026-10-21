import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'sub_rooms_list_screen.dart';

class SubjectRoomsScreen extends StatelessWidget {
  const SubjectRoomsScreen({super.key});

  // 🚀 نقل القائمة خارج build لمنع إعادة إنشائها
  final List<Map<String, dynamic>> subjects = const [
    {'name': 'الرياضيات', 'id': 'MATH', 'icon': Icons.calculate, 'color': Colors.blueAccent},
    {'name': 'الهندسة المدنية', 'id': 'CIVIL', 'icon': Icons.engineering, 'color': Colors.orange},
    {'name': 'الميكانيك', 'id': 'MECH', 'icon': Icons.settings, 'color': Colors.grey},
    {'name': 'هندسة الطرائق', 'id': 'PROCESS', 'icon': Icons.science, 'color': Colors.teal},
    {'name': 'اللغة العربية', 'id': 'ARABIC', 'icon': Icons.menu_book, 'color': Colors.green},
    {'name': 'اللغة الفرنسية', 'id': 'FRENCH', 'icon': Icons.translate, 'color': Colors.blue},
    {'name': 'التاريخ والجغرافيا', 'id': 'HISTORY', 'icon': Icons.public, 'color': Colors.brown},
    {'name': 'اللغة الإنجليزية', 'id': 'ENGLISH', 'icon': Icons.language, 'color': Colors.redAccent},
    {'name': 'العلوم الإسلامية', 'id': 'ISLAMIC', 'icon': Icons.mosque, 'color': Colors.amber},
    {'name': 'العلوم الفيزيائية', 'id': 'PHYSICS', 'icon': Icons.bolt, 'color': Colors.purpleAccent},
    {'name': 'اللغة الأمازيغية', 'id': 'AMAZIGH', 'icon': Icons.abc, 'color': Colors.cyan},
    {'name': 'المراجعة العامة', 'id': 'GENERAL', 'icon': Icons.group, 'color': Colors.pinkAccent},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor, // 🚀 خلفية مصمتة أسرع بكثير
      appBar: AppBar(title: const Text('قاعات المواد الدراسية')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          var subject = subjects[index];
          Color color = subject['color'] as Color;

          return GestureDetector(
            onTap: () {
              // 🚀 انتقال سريع (200ms) باستخدام Fade بدلاً من الانزلاق
              Navigator.push(context, PageRouteBuilder(
                pageBuilder: (_, __, ___) => SubRoomsListScreen(
                  subjectName: subject['name'] as String,
                  subjectId: subject['id'] as String,
                ),
                transitionDuration: const Duration(milliseconds: 200),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
              ));
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                // 🚀 تقليل الظل لتحسين الأداء
                boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(subject['icon'] as IconData, size: 40, color: color),
                  const SizedBox(height: 12),
                  Text(
                    subject['name'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
