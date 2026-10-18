import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});
  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  List<Offset?> points = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السبورة'),
        actions: [IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => points.clear()))],
      ),
      body: GestureDetector(
        onPanUpdate: (details) => setState(() => points.add(details.localPosition)),
        onPanEnd: (details) => points.add(null),
        child: CustomPaint(
          painter: BoardPainter(points),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final List<Offset?> points;
  BoardPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.blue..strokeCap = StrokeCap.round..strokeWidth = 4.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }
  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;
}
