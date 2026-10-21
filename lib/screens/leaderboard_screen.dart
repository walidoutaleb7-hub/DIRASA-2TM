import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  // 🚀 دالة موحدة لعرض الوقت بشكل دقيق
  String _formatStudyTime(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds ثانية';
    }
    int minutes = totalSeconds ~/ 60;
    if (minutes < 60) {
      return '$minutes دقيقة';
    }
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return '$hours ساعة و $remainingMinutes دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('متصدرو الدراسة')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('studyTime', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب مسجلين بعد.', style: TextStyle(color: Colors.grey)));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              String name = user['name'] ?? 'طالب';
              int studyTime = user['studyTime'] ?? 0;
              
              String timeStr = _formatStudyTime(studyTime);

              Color color = index == 0 
                  ? Colors.amber 
                  : index == 1 
                      ? Colors.grey 
                      : index == 2 
                          ? Colors.brown 
                          : AppTheme.cardColor;
                          
              bool isTopThree = index < 3;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: index == 0 ? Colors.amber.withOpacity(0.5) : Colors.white10,
                    width: index == 0 ? 1.5 : 1,
                  ),
                  boxShadow: index == 0 
                      ? [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 15)] 
                      : [],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: isTopThree 
                      ? CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Text('${index + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  trailing: Text(timeStr, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
