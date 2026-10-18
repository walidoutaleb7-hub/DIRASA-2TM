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
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [
    {'role': 'ai', 'text': 'مرحباً بك في DIRASA AI. أنا مساعدك الدراسي الخارق. يمكنك سؤالي عن أي شيء (رياضيات، فيزياء، فلسفة، برمجة...) وسأشرحه لك بأسلوب مبسط واحترافي. بماذا أساعدك اليوم؟'}
  ];
  
  bool _isLoading = false;

  // ⚠️ ضع مفتاح API الخاص بك هنا ⚠️
  final String _apiKey = 'AQ.Ab8RN6KrkqlBO4TI9fdDekj43Z8OEeY2W-KmJa2EmlVZPVacQw'; 

  Future<void> _askAI() async {
    String userText = _controller.text.trim();
    if (userText.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // ترقية النموذج إلى 3.6 Flash (الأحدث والأذكى مجاناً)
      final model = GenerativeModel(
        model: 'gemini-3.6-flash', 
        apiKey: _apiKey,
        systemInstruction: Content.system(
          'أنت "DIRASA AI"، مساعد دراسي خارق الذكاء لطلاب قسم DIRASA 2TM. '
          'أسلوبك احترافي، مشجع، ومنظم جداً. '
          'عند شرح أي مفهوم، اتبع هذه القواعد: '
          '1. ابدأ بملخص سريع. '
          '2. اشرح الفكرة الرئيسية ببساطة. '
          '3. قم بتقسيم الحل أو الشرح إلى خطوات مرقمة. '
          '4. استخدم التنسيق (النقاط، العريض) لتسهيل القراءة. '
          '5. أنهِ إجابتك دائماً بسؤال تحفيزي للطالب. '
          'لا تستخدم إيموجيات أبداً، والتزم باللغة العربية الفصحى المبسطة.'
        ),
      );

      List<Content> history = [];
      for (var msg in _messages) {
        if (msg['role'] == 'user') {
          history.add(Content.text(msg['text']));
        } else {
          history.add(Content.model([TextPart(msg['text'])]));
        }
      }

      final response = await model.generateContent(history);

      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'ai', 
          'text': response.text ?? "عذراً، لم أستطع معالجة طلبك. حاول صياغته بطريقة أخرى."
        });
      });
      _scrollToBottom();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'ai', 
          'text': "حدث خطأ في الاتصال بالشبكة. تأكد من الإنترنت وصلاحية مفتاح API."
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DIRASA AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({'role': 'ai', 'text': 'تم مسح المحادثة. أنا جاهز لأسئلتك الجديدة!'});
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var msg = _messages[index];
                bool isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryColor : AppTheme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? Radius.zero : const Radius.circular(20),
                        bottomRight: isUser ? const Radius.circular(20) : Radius.zero,
                      ),
                      border: isUser ? null : Border.all(color: Colors.grey.shade800),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(fontSize: 16, height: 1.5, color: isUser ? Colors.white : AppTheme.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgColor,
              border: Border(top: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _askAI(),
                    decoration: InputDecoration(
                      hintText: 'اسأل عن أي شيء دراسي...',
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24, 
                  backgroundColor: _isLoading ? Colors.grey : AppTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20), 
                    onPressed: _isLoading ? null : _askAI
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
