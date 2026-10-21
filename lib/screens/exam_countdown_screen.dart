import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ExamCountdownScreen extends StatefulWidget {
  const ExamCountdownScreen({super.key});
  @override
  State<ExamCountdownScreen> createState() => _ExamCountdownScreenState();
}

class _ExamCountdownScreenState extends State<ExamCountdownScreen> {
  DateTime? _examDate;
  final _subjectController = TextEditingController();
  String _examSubject = '';

  @override
  void initState() {
    super.initState();
    _loadSavedExam();
  }

  void _loadSavedExam() async {
    final prefs = await SharedPreferences.getInstance();
    String? dateStr = prefs.getString('exam_date');
    String? subject = prefs.getString('exam_subject');
    if (dateStr != null && subject != null) {
      setState(() {
        _examDate = DateTime.parse(dateStr);
        _examSubject = subject;
        _subjectController.text = subject;
      });
    }
  }

  void _pickDate() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم المادة أولاً')));
      return;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('exam_date', picked.toIso8601String());
      await prefs.setString('exam_subject', _subjectController.text.trim());
      setState(() {
        _examDate = picked;
        _examSubject = _subjectController.text.trim();
      });
    }
  }

  int get _daysRemaining {
    if (_examDate == null) return 0;
    final now = DateTime.now();
    final difference = _examDate!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('عداد الامتحانات')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'اسم المادة (مثال: الرياضيات)',
                prefixIcon: Icon(Icons.book, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: const Text('اختر تاريخ الامتحان'),
              ),
            ),
            const SizedBox(height: 40),
            if (_examDate != null) ...[
              const Text('الوقت المتبقي على امتحان:', style: TextStyle(color: Colors.grey, fontSize: 18)),
              const SizedBox(height: 8),
              Text(_examSubject, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 8),
                  boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_daysRemaining', style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
                      const Text('يوم متبقي', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(DateFormat('EEEE, d MMMM yyyy', 'ar').format(_examDate!), style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ] else ...[
              const Icon(Icons.calendar_today, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('لم يتم تحديد أي امتحان بعد', style: TextStyle(color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}
