import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../theme/app_theme.dart';

class FormulaSheetScreen extends StatelessWidget {
  const FormulaSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          title: const Text('مذكرة القوانين'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'الرياضيات'),
              Tab(text: 'الفيزياء'),
              Tab(text: 'الهندسة'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FormulaListTab(
              formulas: [
                {'title': 'المتتاليات الحسابية', 'latex': r'U_n = U_0 + n \cdot r'},
                {'title': '', 'latex': r'S_n = (n+1) \cdot \frac{U_0 + U_n}{2}'},
                {'title': 'المتتاليات الهندسية', 'latex': r'U_n = U_0 \cdot q^n'},
                {'title': '', 'latex': r'S_n = U_0 \cdot \frac{1 - q^{n+1}}{1 - q}'},
                {'title': 'الاشتقاق', 'latex': r'(u \cdot v)^\prime = u^\prime v + u v^\prime'},
                {'title': '', 'latex': r'\left(\frac{u}{v}\right)^\prime = \frac{u^\prime v - u v^\prime}{v^2}'},
                {'title': '', 'latex': r'\left(\frac{1}{u}\right)^\prime = -\frac{u^\prime}{u^2}'},
                {'title': 'المعادلة من الدرجة الثانية', 'latex': r'ax^2 + bx + c = 0'},
                {'title': 'المميز', 'latex': r'\Delta = b^2 - 4ac'},
                {'title': 'الحلول', 'latex': r'x_{1,2} = \frac{-b \pm \sqrt{\Delta}}{2a}'},
                {'title': 'النهايات الأساسية', 'latex': r'\lim_{x \to 0} \frac{\sin x}{x} = 1'},
                {'title': '', 'latex': r'\lim_{x \to 0} \frac{1 - \cos x}{x^2} = \frac{1}{2}'},
                {'title': 'العلاقات المثلثية', 'latex': r'\cos^2(x) + \sin^2(x) = 1'},
                {'title': '', 'latex': r'\cos(a+b) = \cos a \cos b - \sin a \sin b'},
                {'title': '', 'latex': r'\sin(a+b) = \sin a \cos b + \cos a \sin b'},
              ],
            ),
            _FormulaListTab(
              formulas: [
                {'title': 'الحركة المستقيمة', 'latex': r'V = \frac{d}{t}'},
                {'title': 'التسارع', 'latex': r'a = \frac{V_2 - V_1}{t}'},
                {'title': 'المسافة', 'latex': r'd = V_0 t + \frac{1}{2} a t^2'},
                {'title': 'قوانين نيوتن', 'latex': r'F = m \cdot a'},
                {'title': 'الوزن', 'latex': r'P = m \cdot g'},
                {'title': 'الطاقة الحركية', 'latex': r'E_c = \frac{1}{2} m v^2'},
                {'title': 'الطاقة الكامنة', 'latex': r'E_p = m \cdot g \cdot h'},
                {'title': 'الشغل', 'latex': r'W = F \cdot d \cdot \cos \alpha'},
                {'title': 'قانون أوم', 'latex': r'U = R \cdot I'},
                {'title': 'الاستطاعة', 'latex': r'P = U \cdot I'},
                {'title': 'الطاقة الكهربائية', 'latex': r'E = P \cdot t'},
                {'title': 'المقاومات (توالي)', 'latex': r'R = R_1 + R_2 + \dots'},
                {'title': 'المقاومات (توازي)', 'latex': r'\frac{1}{R} = \frac{1}{R_1} + \frac{1}{R_2} + \dots'},
              ],
            ),
            _FormulaListTab(
              formulas: [
                {'title': 'التحويلات الأساسية', 'latex': r'1 \text{ mm} = 0.001 \text{ m}'},
                {'title': '', 'latex': r'1 \text{ cm} = 0.01 \text{ m}'},
                {'title': '', 'latex': r'1 \text{ km} = 1000 \text{ m}'},
                {'title': 'الزمن', 'latex': r'1 \text{ min} = 60 \text{ s}'},
                {'title': '', 'latex': r'1 \text{ h} = 3600 \text{ s}'},
                {'title': 'مساحة المثلث', 'latex': r'A = \frac{b \cdot h}{2}'},
                {'title': 'مساحة الدائرة', 'latex': r'A = \pi \cdot r^2'},
                {'title': 'حجم الأسطوانة', 'latex': r'V = \pi \cdot r^2 \cdot h'},
                {'title': 'حجم المكعب', 'latex': r'V = a^3'},
                {'title': 'حجم الكرة', 'latex': r'V = \frac{4}{3} \cdot \pi \cdot r^3'},
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaListTab extends StatelessWidget {
  final List<Map<String, String>> formulas;
  const _FormulaListTab({required this.formulas});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: formulas.length,
      itemBuilder: (context, index) {
        var item = formulas[index];
        bool hasTitle = item['title']!.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasTitle) ...[
                Text(
                  item['title']!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                // 🚀 الحل: إجبار المعادلة على القراءة من اليسار إلى اليمين
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Math.tex(
                      item['latex']!,
                      mathStyle: MathStyle.display,
                      textStyle: const TextStyle(fontSize: 22, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
