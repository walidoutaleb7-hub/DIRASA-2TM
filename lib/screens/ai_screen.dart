import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});
  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  String _response = "مرحباً! أنا مساعدك الذكي DIRASA. اسألني عن أي شيء دراسي (رياضيات، فيزياء، فلسفة...) وسأشرحه لك فوراً.";
  bool _isLoading = false;

  // ⚠️ ضع مفتاح API الخاص بك هنا ⚠️
  final String _apiKey = 'AQ.Ab8RN6KrkqlBO4TI9fdDekj43Z8OEeY2W-KmJa2EmlVZPVacQw'; 

  void _askAI() async {
    if (_controller.text.isEmpty) return;
    setState(() { _isLoading = true; _response = "جاري التفكير..."; });
    
    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
      final content = [Content.text("أنت مساعد دراسي ذكي ولطيف. أجب على السؤال التالي باللغة العربية بشكل مبسط ومفيد: ${_controller.text}")];
      final response = await model.generateContent(content);

      setState(() {
        _isLoading = false;
        _response = response.text ?? "عذراً، لم أستطع فهم السؤال. حاول مرة أخرى.";
        _controller.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = "حدث خطأ في الاتصال بالمساعد الذكي. تأكد من الإنترنت ومن صحة مفتاح API.";
      });
    }
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
                decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade800)),
                child: SingleChildScrollView(child: Text(_response, style: const TextStyle(fontSize: 16, height: 1.6))),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'اكتب سؤالك هنا...')),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24, backgroundColor: AppTheme.primaryColor,
                  child: IconButton(icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white), onPressed: _isLoading ? null : _askAI),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
