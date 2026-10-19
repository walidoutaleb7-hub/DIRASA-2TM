import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentId = AuthService.currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: currentId == null
          ? const Center(child: Text('يرجى تسجيل الدخول', style: TextStyle(color: Colors.white)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                var user = snapshot.data!.data() as Map<String, dynamic>? ?? {};

                String name = user['name'] ?? 'مستخدم';
                int studyTime = user['studyTime'] ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // صورة الملف الشخصي
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: Text(name[0], style: const TextStyle(fontSize: 50, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                        child: Text(user['status'] ?? 'متاح للدراسة', style: const TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 32),
                      
                      // إحصائيات مثل إنستغرام
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard('ساعات الدراسة', '${studyTime ~/ 60} ساعة'),
                          _buildStatCard('أيام النشاط', '${(studyTime ~/ 60) % 7} أيام'), // حساب تقريبي
                          _buildStatCard('الرتبة', 'طالب'),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // شبكة أيام الدراسة (Heatmap مصغر)
                      const Align(alignment: Alignment.centerRight, child: Text('نشاط الدراسة الأسبوعي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          bool isActive = (studyTime ~/ 60) % 7 > index;
                          return Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.primaryColor : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Center(child: Text(['س','ح','ن','ث','ر','خ','ج'][index], style: TextStyle(color: isActive ? Colors.white : Colors.grey))),
                          );
                        }),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
