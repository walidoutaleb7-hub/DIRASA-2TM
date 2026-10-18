import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});
  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  String _response = "مرحباً! أنا مساعدك الذكي. اسألني عن أي شيء دراسي وسأشرحه لك.";
  bool _isLoading = false;

  void _askAI() async {
    if (_controller.text.isEmpty) return;
    setState(() { _isLoading = true; _response = "جاري التفكير..."; });
    // محاكاة الاتصال بالذكاء الاصطناعي (يمكنك ربط Gemini API هنا لاحقاً)
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _response = "هذا سؤال رائع! (هنا سيتم عرض إجابة الذكاء الاصطناعي بعد ربط الـ API). السؤال كان: ${_controller.text}";
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المساعد الذكي')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(child: Text(_response, style: const TextStyle(fontSize: 16, height: 1.5))),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'اسأل عن الرياضيات، الفيزياء...')),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24, backgroundColor: AppTheme.primaryColor,
                  child: IconButton(icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.send, color: Colors.white), onPressed: _isLoading ? null : _askAI),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
