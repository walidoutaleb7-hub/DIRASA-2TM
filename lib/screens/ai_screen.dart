import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    {'role': 'ai', 'text': 'مرحباً بك في DIRASA AI. أنا مساعدك الدراسي الخارق. اسألني عن أي شيء.'}
  ];
  
  bool _isLoading = false;

  final String _backendUrl = 'https://dirasa-2tm.onrender.com/api/chat';

  Future<void> _askAI() async {
    String userText = _controller.text.trim();
    if (userText.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isLoading = true;
      _messages.add({'role': 'ai', 'text': 'جاري الاتصال بالخادم...'});
    });
    _scrollToBottom();

    try {
      List<Map<String, String>> history = [];
      // بناء السجل مع تجاهل رسائل الترحيب والتحميل
      for (var msg in _messages) {
        if (msg['role'] == 'user') {
          history.add({'role': 'user', 'parts': msg['text']});
        } else if (msg['role'] == 'ai' && !msg['text'].contains('جاري الاتصال') && !msg['text'].contains('مرحباً بك في DIRASA AI')) {
          history.add({'role': 'model', 'parts': msg['text']});
        }
      }
      if (history.isNotEmpty) history.removeLast(); // حذف آخر رسالة للمستخدم لأننا سنرسلها في message

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userText,
          'history': history,
        }),
      ).timeout(const Duration(seconds: 60)); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _messages.removeLast(); 
          _messages.add({'role': 'ai', 'text': data['reply'] ?? 'عذراً، لم أفهم.'});
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _messages.removeLast();
          _messages.add({'role': 'ai', 'text': 'خطأ: ${data['error']}'});
        });
      }
    } on TimeoutException {
      setState(() {
        _isLoading = false;
        _messages.removeLast();
        _messages.add({'role': 'ai', 'text': 'استغرق الخادم وقتاً طويلاً للرد. يرجى المحاولة مرة أخرى.'});
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.removeLast();
        _messages.add({'role': 'ai', 'text': 'حدث خطأ في الشبكة. تأكد من الإنترنت.'});
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
