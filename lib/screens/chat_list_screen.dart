import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('المحادثات')),
      body: const Center(
        child: Text(
          'لا توجد محادثات حالياً.\n(تتطلب الاتصال بقاعدة البيانات)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
