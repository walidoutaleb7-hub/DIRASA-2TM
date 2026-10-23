import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('التمارين والسوجي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSubjectCard(context, 'الرياضيات', Icons.calculate, Colors.blueAccent, [
            {'type': 'تمرين', 'title': 'المتتاليات الحسابية', 'content': 'احسب الحد العام والحد العشرين للمتتالية...'},
            {'type': 'تمرين', 'title': 'الاشتقاق', 'content': 'أوجد مشتقة الدالة f(x) = x^2 + 2x...'},
            {'type': 'سوجي', 'title': 'سوجي 2023', 'content': 'تمرين 1: نعتبر المتتالية... \nتمرين 2: الدالة العددية...'},
          ]),
          const SizedBox(height: 16),
          _buildSubjectCard(context, 'الفيزياء', Icons.science, Colors.purpleAccent, [
            {'type': 'تمرين', 'title': 'قوانين نيوتن', 'content': 'جسم كتلته 5kg يتحرك بتسارع 2m/s^2. احسب القوة...'},
            {'type': 'سوجي', 'title': 'سوجي 2022', 'content': 'التمرين الأول: دراسة حركة جسم... \nالتمرين الثاني: الكهرباء...'},
          ]),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, String title, IconData icon, Color color, List<Map<String, String>> items) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconColor: color,
        collapsedIconColor: color,
        children: items.map((item) {
          bool isSujet = item['type'] == 'سوجي';
          return ListTile(
            leading: Icon(isSujet ? Icons.assignment : Icons.edit, color: isSujet ? Colors.orangeAccent : AppTheme.primaryColor),
            title: Text(item['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(item['content']!, style: const TextStyle(color: Colors.grey, height: 1.5)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              showDialog(context: context, builder: (c) => AlertDialog(
                backgroundColor: AppTheme.cardColor,
                title: Text(item['title']!, style: const TextStyle(color: Colors.white)),
                content: SingleChildScrollView(child: Text(item['content']!, style: const TextStyle(color: Colors.white70, height: 1.5))),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق'))],
              ));
            },
          );
        }).toList(),
      ),
    );
  }
}
