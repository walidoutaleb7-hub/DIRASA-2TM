import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String? currentId = AuthService.currentUserId;
  final TextEditingController _statusController = TextEditingController();
  bool _isEditing = false;

  void _updateStatus(String oldStatus) async {
    if (_statusController.text.trim().isEmpty || _statusController.text == oldStatus) {
      setState(() => _isEditing = false);
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(currentId).update({'status': _statusController.text.trim()});
    setState(() => _isEditing = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الحالة!')));
  }

  @override
  Widget build(BuildContext context) {
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
                String status = user['status'] ?? 'متاح للدراسة';
                Timestamp? joined = user['createdAt'];
                String joinDate = joined != null ? DateFormat('yyyy/MM/dd').format(joined.toDate()) : 'غير معروف';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // الصورة الرمزية
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: Text(name[0], style: const TextStyle(fontSize: 50, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      
                      // الحالة (قابلة للتعديل)
                      if (_isEditing)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _statusController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(filled: true, fillColor: AppTheme.cardColor, hintText: 'حالتك الآن...'),
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateStatus(status)),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            _statusController.text = status;
                            setState(() => _isEditing = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(status, style: const TextStyle(color: Colors.grey)),
                                const SizedBox(width: 8),
                                const Icon(Icons.edit, color: AppTheme.primaryColor, size: 14),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // إحصائيات
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard('دقائق الدراسة', '$studyTime', Colors.amber),
                          _buildStatCard('تاريخ الانضمام', joinDate, Colors.blueAccent),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
