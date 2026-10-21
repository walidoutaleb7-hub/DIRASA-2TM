import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ميزة "$feature" ستتوفر في التحديث القادم!'), backgroundColor: Theme.of(context).primaryColor),
    );
  }

  void _showGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
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
        backgroundColor: const Color(0xFF121212),
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
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 🚀 قسم اختيار الثيم (زهري / أزرق)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('لون التطبيق المفضل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // الأزرق (للشباب)
                          GestureDetector(
                            onTap: () => ThemeService.setTheme(ThemeService.blueColor),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              decoration: BoxDecoration(
                                color: ThemeService.blueColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: ThemeService.blueColor, width: 2),
                              ),
                              child: const Text('أزرق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          // الزهري (للفتيات)
                          GestureDetector(
                            onTap: () => ThemeService.setTheme(ThemeService.pinkColor),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              decoration: BoxDecoration(
                                color: ThemeService.pinkColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: ThemeService.pinkColor, width: 2),
                              ),
                              child: const Text('زهري', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildSettingTile(context, Icons.person_outline, 'الملف الشخصي', 'إدارة معلومات حسابك', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                const SizedBox(height: 12),
                _buildSettingTile(context, Icons.menu_book, 'دليل الاستخدام', 'كيف تستخدم التطبيق؟', onTap: () => _showGuide(context)),
                const SizedBox(height: 12),
                _buildSettingTile(context, Icons.share, 'مشاركة التطبيق', 'أرسل التطبيق لزملائك', onTap: () => _shareApp(context)),
                const SizedBox(height: 12),
                _buildSettingTile(context, Icons.notifications_none, 'الإشعارات', 'تخصيص التنبيهات', onTap: () => _showComingSoon(context, 'الإشعارات')),
                const SizedBox(height: 12),
                _buildSettingTile(context, Icons.security, 'الخصوصية والأمان', 'أمان البيانات', onTap: () {
                  showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF121212), title: const Text('الخصوصية', style: TextStyle(color: Colors.white)), content: const Text('بياناتك محمية عبر Firebase وتستخدم فقط لأغراض الدراسة داخل القسم.', style: TextStyle(color: Colors.grey)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))]));
                }),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red),
                  onPressed: () async {
                    await AuthService.logout();
                    if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  },
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            width: double.infinity,
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1E1E1E)))),
            child: Column(
              children: [
                const Icon(Icons.code, color: Colors.grey, size: 24),
                const SizedBox(height: 8),
                const Text('Developed by', style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('Walid Outaleb', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, letterSpacing: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: Icon(icon, color: Theme.of(context).primaryColor)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
