import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});
  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class SubjectData {
  final String name;
  double coeff;
  final TextEditingController devoirCtrl = TextEditingController();
  final TextEditingController evalCtrl = TextEditingController();
  final TextEditingController examCtrl = TextEditingController();

  SubjectData(this.name, this.coeff);
  
  // حساب معدل المادة (متوسط العلامات المدخلة)
  double getAverage() {
    double d = double.tryParse(devoirCtrl.text) ?? -1;
    double e = double.tryParse(evalCtrl.text) ?? -1;
    double x = double.tryParse(examCtrl.text) ?? -1;
    
    List<double> grades = [];
    if (d >= 0 && d <= 20) grades.add(d);
    if (e >= 0 && e <= 20) grades.add(e);
    if (x >= 0 && x <= 20) grades.add(x);
    
    if (grades.isEmpty) return 0;
    return grades.reduce((a, b) => a + b) / grades.length;
  }

  bool get hasInput => devoirCtrl.text.isNotEmpty || evalCtrl.text.isNotEmpty || examCtrl.text.isNotEmpty;
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  final List<SubjectData> subjects = [
    SubjectData('الرياضيات', 5),
    SubjectData('العلوم الفيزيائية', 4),
    SubjectData('التكنولوجيا (حسب التخصص)', 4),
    SubjectData('اللغة العربية وآدابها', 2),
    SubjectData('اللغة الفرنسية', 2),
    SubjectData('اللغة الإنجليزية', 2),
    SubjectData('التاريخ والجغرافيا', 1),
    SubjectData('العلوم الإسلامية', 1),
    SubjectData('التربية البدنية والرياضية', 1),
    SubjectData('اللغة الأمازيغية', 1),
  ];

  double? _result;
  double _totalPoints = 0;
  double _totalCoeffs = 0;

  void _calculate() {
    double totalPoints = 0;
    double totalCoeffs = 0;
    
    for (var sub in subjects) {
      if (sub.hasInput) {
        double avg = sub.getAverage();
        totalPoints += avg * sub.coeff;
        totalCoeffs += sub.coeff;
      }
    }

    if (totalCoeffs == 0) {
      setState(() { _result = null; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال علامة واحدة على الأقل')));
      return;
    }

    setState(() {
      _totalPoints = totalPoints;
      _totalCoeffs = totalCoeffs;
      _result = totalPoints / totalCoeffs;
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
              'أدخل علاماتك (املأ ما لديك فقط)',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                var sub = subjects[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(sub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              const Text('المعامل: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              SizedBox(
                                width: 40,
                                height: 30,
                                child: TextField(
                                  controller: TextEditingController(text: sub.coeff.toInt().toString()),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: AppTheme.bgColor,
                                    border: OutlineInputBorder(borderSide: BorderSide.none),
                                  ),
                                  onChanged: (val) {
                                    double? newCoeff = double.tryParse(val);
                                    if (newCoeff != null) sub.coeff = newCoeff;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildGradeField('الفرض', sub.devoirCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildGradeField('التقويم', sub.evalCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildGradeField('الاختبار', sub.examCtrl)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate, color: Colors.white),
                label: const Text('احسب المعدل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
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
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
