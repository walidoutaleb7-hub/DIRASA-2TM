import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // بيانات تجريبية (لأن Firebase معطل حالياً)
    final users = [
      {'name': 'وليد أوطالب', 'time': '1200 دقيقة', 'rank': 1},
      {'name': 'أحمد محمد', 'time': '950 دقيقة', 'rank': 2},
      {'name': 'سارة علي', 'time': '840 دقيقة', 'rank': 3},
      {'name': 'ياسين خالد', 'time': '600 دقيقة', 'rank': 4},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('متصدرو الدراسة')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          var user = users[index];
          Color color = index == 0 ? Colors.amber : index == 1 ? Colors.grey : index == 2 ? Colors.brown : AppTheme.cardColor;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: index == 0 ? Colors.amber.withOpacity(0.5) : Colors.white10),
              boxShadow: index == 0 ? [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 15)] : [],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Text('${user['rank']}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              title: Text(user['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              trailing: Text(user['time'] as String, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
