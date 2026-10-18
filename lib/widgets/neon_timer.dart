import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class NeonTimer extends StatefulWidget {
  final int seconds;
  final bool isRunning;
  final VoidCallback onToggle;
  final int maxSeconds;

  const NeonTimer({
    super.key,
    required this.seconds,
    required this.isRunning,
    required this.onToggle,
    this.maxSeconds = 1500,
  });

  @override
  State<NeonTimer> createState() => _NeonTimerState();
}

class _NeonTimerState extends State<NeonTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.seconds / widget.maxSeconds;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double glowOpacity = widget.isRunning ? (0.3 + (_controller.value * 0.4)) : 0.1;
        return GestureDetector(
          onTap: widget.onToggle,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(glowOpacity),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: CustomPaint(
              painter: TimerPainter(progress: progress),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(widget.seconds ~/ 60).toString().padLeft(2, '0')}:${(widget.seconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        color: AppTheme.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isRunning ? 'جاري التركيز...' : 'اضغط للبدء',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  TimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2;

    // الخلفية الداكنة للدائرة
    Paint bgPaint = Paint()
      ..color = AppTheme.cardColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    // القوس المتوهج (التقدم)
    Paint progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;
    double sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) => oldDelegate.progress != progress;
}
