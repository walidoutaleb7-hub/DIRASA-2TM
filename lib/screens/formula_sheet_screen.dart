import 'package:flutter/material.dart';
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
            _MathTab(),
            _PhysicsTab(),
            _EngineeringTab(),
          ],
        ),
      ),
    );
  }
}

class _MathTab extends StatelessWidget {
  const _MathTab();
  @override
  Widget build(BuildContext context) {
    final formulas = [
      {'title': 'المتتاليات الحسابية', 'text': 'الحد العام: U_n = U_0 + n * r\nالمجموع: S_n = (n+1) * (U_0 + U_n) / 2'},
      {'title': 'المتتاليات الهندسية', 'text': 'الحد العام: U_n = U_0 * q^n\nالمجموع: S_n = U_0 * (1 - q^(n+1)) / (1 - q)'},
      {'title': 'الاشتقاق', 'text': '(u*v)\' = u\'v + uv\'\n(u/v)\' = (u\'v - uv\') / v^2\n(1/u)\' = -u\' / u^2'},
      {'title': 'المعادلة من الدرجة الثانية', 'text': 'ax^2 + bx + c = 0\nالمميز: Delta = b^2 - 4ac\nالحلول: x = (-b ± جذر(Delta)) / 2a'},
      {'title': 'النهايات', 'text': 'lim (sin x / x) = 1 عند x->0\nlim (1 - cos x / x^2) = 1/2 عند x->0'},
    ];
    return _buildFormulaList(formulas);
  }
}

class _PhysicsTab extends StatelessWidget {
  const _PhysicsTab();
  @override
  Widget build(BuildContext context) {
    final formulas = [
      {'title': 'الحركة', 'text': 'السرعة: V = d / t\nالتسارع: a = (V2 - V1) / t\nالمسافة: d = V * t'},
      {'title': 'قوانين نيوتن', 'text': 'القانون الثاني: F = m * a\nالوزن: P = m * g (حيث g = 9.8)'},
      {'title': 'الطاقة', 'text': 'الطاقة الحركية: Ec = 1/2 * m * v^2\nالطاقة الكامنة: Ep = m * g * h\nالشغل: W = F * d * cos(alpha)'},
      {'title': 'الكهرباء', 'text': 'قانون أوم: U = R * I\nالاستطاعة: P = U * I\nالطاقة: E = P * t'},
    ];
    return _buildFormulaList(formulas);
  }
}

class _EngineeringTab extends StatelessWidget {
  const _EngineeringTab();
  @override
  Widget build(BuildContext context) {
    final formulas = [
      {'title': 'المقاومات', 'text': 'التوالي: R = R1 + R2\nالتوازي: 1/R = 1/R1 + 1/R2'},
      {'title': 'التحويلات', 'text': '1 mm = 0.001 m\n1 cm = 0.01 m\n1 km = 1000 m'},
      {'title': 'المساحات والحجوم', 'text': 'مساحة المثلث: (القاعدة * الارتفاع) / 2\nحجم الأسطوانة: pi * r^2 * h'},
    ];
    return _buildFormulaList(formulas);
  }
}

Widget _buildFormulaList(List<Map<String, String>> formulas) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: formulas.length,
    itemBuilder: (context, index) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formulas[index]['title']!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              formulas[index]['text']!,
              style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.8, fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    },
  );
}
