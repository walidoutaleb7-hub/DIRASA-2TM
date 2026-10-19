import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // شاشة مؤقتة لحين إصلاح مشكلة قاعدة البيانات
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('زملاء القسم')),
      body: const Center(
        child: Text(
          'قائمة الزملاء ستتوفر قريباً...\n(تتطلب الاتصال بقاعدة البيانات)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
