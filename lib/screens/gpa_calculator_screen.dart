import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SubjectData {
  final String name;
  double coeff;
  final TextEditingController devoirCtrl = TextEditingController();
  final TextEditingController evalCtrl = TextEditingController();
  final TextEditingController examCtrl = TextEditingController();
  final TextEditingController coeffCtrl;

  SubjectData(this.name, this.coeff) : coeffCtrl = TextEditingController(text: coeff.toStringAsFixed(0));

  double getAverage() {
    double? d = double.tryParse(devoirCtrl.text);
    double? e = double.tryParse(evalCtrl.text);
    double? x = double.tryParse(examCtrl.text);
    if (d != null && (d < 0 || d > 20)) d = null;
    if (e != null && (e < 0 || e > 20)) e = null;
    if (x != null && (x < 0 || x > 20)) x = null;
    if (d != null && e != null && x != null) return (d + e + 2 * x) / 4;
    else if (d != null && e != null) return (d + e) / 2;
    else if (d != null && x != null) return (d + x) / 2;
    else if (e != null && x != null) return (e + x) / 2;
    else if (d != null) return d;
    else if (e != null) return e;
    else if (x != null) return x;
    return 0;
  }
  bool get hasInput => devoirCtrl.text.isNotEmpty || evalCtrl.text.isNotEmpty || examCtrl.text.isNotEmpty;
  void dispose() { devoirCtrl.dispose(); evalCtrl.dispose(); examCtrl.dispose(); coeffCtrl.dispose(); }
}

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});
  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  final List<SubjectData> subjects = [
    SubjectData('الرياضيات', 5), SubjectData('العلوم الفيزيائية', 4), SubjectData('التكنولوجيا', 4),
    SubjectData('اللغة العربية', 2), SubjectData('اللغة الفرنسية', 2), SubjectData('اللغة الإنجليزية', 2),
    SubjectData('التاريخ والجغرافيا', 1), SubjectData('العلوم الإسلامية', 1), SubjectData('التربية البدنية', 1), SubjectData('اللغة الأمازيغية', 1),
  ];
  double? _result;
  double _totalPoints = 0;
  double _totalCoeffs = 0;

  @override
  void dispose() { for (var sub in subjects) sub.dispose(); super.dispose(); }

  void _calculate() {
    double totalPoints = 0;
    double totalCoeffs = 0;
    for (var sub in subjects) {
      double? newCoeff = double.tryParse(sub.coeffCtrl.text);
      if (newCoeff != null && newCoeff > 0) sub.coeff = newCoeff;
      if (sub.hasInput) {
        totalPoints += sub.getAverage() * sub.coeff;
        totalCoeffs += sub.coeff;
      }
    }
    if (totalCoeffs == 0) {
      setState(() => _result = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال علامة واحدة على الأقل')));
      return;
    }
    setState(() { _totalPoints = totalPoints; _totalCoeffs = totalCoeffs; _result = totalPoints / totalCoeffs; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('حاسبة المعدل الفصلي')),
      // 🚀 إضافة SafeArea لحماية الزر من شريط التنقل السفلي
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('أدخل علاماتك (املأ ما لديك فقط)', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  var sub = subjects[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(sub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                            Row(
                              children: [
                                const Text('المعامل:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 45, height: 30,
                                  child: TextField(
                                    controller: sub.coeffCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderSide: BorderSide.none)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildGradeField('فرض', sub.devoirCtrl)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildGradeField('تقويم', sub.evalCtrl)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildGradeField('اختبار', sub.examCtrl)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate, color: Colors.white),
                  label: const Text('احسب المعدل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(height: 24),
              if (_result != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20)]),
                  child: Column(
                    children: [
                      const Text('معدلك الفصلي المتوقع', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(_result!.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_result! >= 10 ? 'مبروك، أنت ناجح! استمر في التفوق.' : 'تحتاج إلى مراجعة بعض المواد. لا تستسلم!', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text('مجموع المعاملات المدخلة: ${_totalCoeffs.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('مجموع النقاط: ${_totalPoints.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        filled: true,
        fillColor: AppTheme.bgColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
