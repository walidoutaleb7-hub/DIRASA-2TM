import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});
  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isHistoryLoaded = false;

  final String _backendUrl = 'https://dirasa-2tm.onrender.com/api/chat';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedMessages = prefs.getString('ai_chat_history');
    
    if (savedMessages != null) {
      List<dynamic> decoded = jsonDecode(savedMessages);
      _messages = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _messages = [
        {'role': 'ai', 'text': 'مرحباً بك في DIRASA AI. أنا مساعدك الدراسي الخارق. اسألني عن أي شيء.'}
      ];
    }
    setState(() => _isHistoryLoaded = true);
    _scrollToBottom();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_chat_history', jsonEncode(_messages));
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_chat_history');
    setState(() {
      _messages.clear();
      _messages.add({'role': 'ai', 'text': 'تم مسح المحادثة. أنا جاهز لأسئلتك الجديدة!'});
    });
  }

  Future<void> _askAI() async {
    String userText = _controller.text.trim();
    if (userText.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isLoading = true;
      _messages.add({'role': 'ai', 'text': 'جاري التفكير...'});
    });
    _scrollToBottom();

    try {
      List<Map<String, String>> history = [];
      for (var msg in _messages) {
        if (msg['role'] == 'user') {
          history.add({'role': 'user', 'parts': msg['text']});
        } else if (msg['role'] == 'ai' && !msg['text'].contains('جاري') && !msg['text'].contains('مرحباً بك') && !msg['text'].contains('تم مسح')) {
          history.add({'role': 'model', 'parts': msg['text']});
        }
      }
      if (history.isNotEmpty) history.removeLast();

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userText, 'history': history}),
      ).timeout(const Duration(seconds: 90)); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _messages.removeLast(); 
          _messages.add({'role': 'ai', 'text': data['reply'] ?? 'عذراً، لم أفهم.'});
        });
      } else {
        setState(() {
          _isLoading = false;
          _messages.removeLast();
          _messages.add({'role': 'ai', 'text': 'حدث خطأ في الخادم.'});
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.removeLast();
        _messages.add({'role': 'ai', 'text': 'حدث خطأ في الشبكة. تأكد من الإنترنت.'});
      });
    }
    _saveHistory();
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
    if (!_isHistoryLoaded) return const Scaffold(backgroundColor: Color(0xFF000000), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIRASA AI'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearHistory)
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
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
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
                    child: MarkdownWidget(
                      data: msg['text'],
                      shrinkWrap: true,
                      config: MarkdownConfig(
                        configs: [
                          PConfig(textStyle: TextStyle(fontSize: 16, height: 1.6, color: isUser ? Colors.white : AppTheme.textPrimary)),
                          H1Config(style: TextStyle(color: isUser ? Colors.white : AppTheme.primaryColor, fontSize: 22, fontWeight: FontWeight.bold)),
                          H2Config(style: TextStyle(color: isUser ? Colors.white : AppTheme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                          H3Config(style: TextStyle(color: isUser ? Colors.white : AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          CodeConfig(style: const TextStyle(color: Colors.amberAccent, backgroundColor: Colors.black45, fontFamily: 'monospace')),
                          LinkConfig(style: TextStyle(color: AppTheme.primaryColor, decoration: TextDecoration.underline)),
                          ListConfig(marker: (isTight, index, listType) => Text('•', style: TextStyle(color: isUser ? Colors.white : AppTheme.primaryColor, fontSize: 18))),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.bgColor, border: Border(top: BorderSide(color: Colors.grey.shade800))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _askAI(),
                    decoration: InputDecoration(
                      hintText: 'اسأل عن أي شيء دراسي...',
                      hintStyle: const TextStyle(color: Colors.grey),
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
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _isLoading ? null : _askAI),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
