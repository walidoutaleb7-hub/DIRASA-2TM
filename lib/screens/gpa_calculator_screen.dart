import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});
  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  // 📚 المواد ومعاملاتها (تقني رياضي - 2 ثانوي)
  final List<Map<String, dynamic>> subjects = [
    {'name': 'الرياضيات', 'coeff': 5, 'controller': TextEditingController()},
    {'name': 'الفيزياء', 'coeff': 4, 'controller': TextEditingController()},
    {'name': 'التكنولوجيا (هندسة)', 'coeff': 4, 'controller': TextEditingController()},
    {'name': 'اللغة العربية', 'coeff': 2, 'controller': TextEditingController()},
    {'name': 'اللغة الفرنسية', 'coeff': 2, 'controller': TextEditingController()},
    {'name': 'اللغة الإنجليزية', 'coeff': 2, 'controller': TextEditingController()},
    {'name': 'الفلسفة', 'coeff': 2, 'controller': TextEditingController()},
    {'name': 'العلوم الإسلامية', 'coeff': 1, 'controller': TextEditingController()},
    {'name': 'التاريخ والجغرافيا', 'coeff': 1, 'controller': TextEditingController()},
    {'name': 'التربية البدنية', 'coeff': 1, 'controller': TextEditingController()},
  ];

  double? _result;
  String _status = '';

  void _calculateGpa() {
    double totalPoints = 0;
    int totalCoeffs = 0;
    bool hasError = false;

    for (var subject in subjects) {
      String text = subject['controller'].text.trim();
      if (text.isNotEmpty) {
        double? grade = double.tryParse(text);
        if (grade == null || grade < 0 || grade > 20) {
          hasError = true;
          break;
        }
        totalPoints += grade * subject['coeff'];
        totalCoeffs += subject['coeff'] as int;
      }
    }

    if (hasError) {
      setState(() {
        _result = null;
        _status = 'الرجاء إدخال علامات صحيحة (من 0 إلى 20)';
      });
      return;
    }

    if (totalCoeffs == 0) {
      setState(() {
        _result = null;
        _status = 'الرجاء إدخال علامة واحدة على الأقل';
      });
      return;
    }

    setState(() {
      _result = totalPoints / totalCoeffs;
      _status = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('حاسبة المعدل الفصلي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'أدخل علاماتك (اختياري، املأ ما لديك فقط)',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // قائمة المواد
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                var subject = subjects[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${subject['name']} (م ${subject['coeff']})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: subject['controller'],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // زر الحساب
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _calculateGpa,
                icon: const Icon(Icons.calculate, color: Colors.white),
                label: const Text('احسب المعدل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // عرض النتيجة
            if (_status.isNotEmpty)
              Text(_status, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
            
            if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    const Text('معدلك الفصلي المتوقع', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      _result!.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result! >= 10 ? 'مبروك، أنت ناجح! استمر في التفوق.' : 'تحتاج إلى مراجعة بعض المواد. لا تستسلم!',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
