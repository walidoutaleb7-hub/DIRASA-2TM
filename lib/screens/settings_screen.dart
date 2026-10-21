import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ميزة "$feature" ستتوفر في التحديث القادم!'), backgroundColor: AppTheme.primaryColor),
    );
  }

  void _showGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('دليل الاستخدام', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            'مرحباً بك في DIRASA 2TM!\n\n'
            '1. القاعات: ادخل لأي مادة لتجد رومات النقاش.\n'
            '2. إنشاء روم: يمكنك إنشاء رومك الخاص وتصبح الأدمن.\n'
            '3. الأدمن: يمكنه قفل الدردشة أو حذف الرسائل.\n'
            '4. الفيديو: ادخل للمكالمة لمشاهدة الشاشة والكاميرا.\n'
            '5. المساعد AI: اسأله عن أي درس أو معادلة صعبة.\n'
            '6. الدردشة: تواصل مع أي زميل مباشرة.',
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('فهمت')),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('مشاركة التطبيق', style: TextStyle(color: Colors.white)),
        content: const Text('يمكنك مشاركة التطبيق مع زملائك في القسم عن طريق إرسال ملف الـ APK لهم، أو مشاركة رابط المستودع.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'تطبيق DIRASA 2TM - مستقبل التعليم يبدأ من هنا!'));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ اسم التطبيق للمشاركة')));
            }, 
            child: const Text('نسخ الاسم')
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 1. الملف الشخصي (الآن يعمل بشكل صحيح)
                _buildSettingTile(
                  Icons.person_outline, 'الملف الشخصي', 'إدارة معلومات حسابك',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // 2. دليل الاستخدام
                _buildSettingTile(
                  Icons.menu_book, 'دليل الاستخدام', 'كيف تستخدم التطبيق؟',
                  onTap: () => _showGuide(context),
                ),
                const SizedBox(height: 12),

                // 3. مشاركة التطبيق
                _buildSettingTile(
                  Icons.share, 'مشاركة التطبيق', 'أرسل التطبيق لزملائك',
                  onTap: () => _shareApp(context),
                ),
                const SizedBox(height: 12),

                // 4. الإشعارات
                _buildSettingTile(
                  Icons.notifications_none, 'الإشعارات', 'تخصيص التنبيهات',
                  onTap: () => _showComingSoon(context, 'الإشعارات'),
                ),
                const SizedBox(height: 12),

                // 5. الخصوصية والأمان
                _buildSettingTile(
                  Icons.security, 'الخصوصية والأمان', 'أمان البيانات',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.cardColor,
                        title: const Text('الخصوصية', style: TextStyle(color: Colors.white)),
                        content: const Text('بياناتك محمية عبر Firebase وتستخدم فقط لأغراض الدراسة داخل القسم.', style: TextStyle(color: Colors.grey)),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // زر تسجيل الخروج
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري تسجيل الخروج..."), duration: Duration(seconds: 1)));
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
          
          // التوقيع الخاص بك
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
            ),
            child: Column(
              children: [
                const Icon(Icons.code, color: Colors.grey, size: 24),
                const SizedBox(height: 8),
                const Text('Developed by', style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(
                  'Walid Outaleb',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
