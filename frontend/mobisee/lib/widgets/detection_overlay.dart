import 'package:flutter/material.dart';
import '../models/detection.dart';

class DetectionOverlayPainter extends CustomPainter {
  final List<Detection> detections;

  const DetectionOverlayPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final color = _colorForLabel(d.label);

      final boxPaint = Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      final rect = Rect.fromLTRB(
        d.x1 * size.width,
        d.y1 * size.height,
        d.x2 * size.width,
        d.y2 * size.height,
      );

      // Bounding box
      canvas.drawRect(rect, boxPaint);

      // Corner ticks (surveillance aesthetic)
      _drawCornerTicks(canvas, rect, color);

      // Label pill
      _drawLabel(canvas, rect, d, color, size);
    }
  }

  void _drawCornerTicks(Canvas canvas, Rect rect, Color color) {
    final tickPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;

    const t = 8.0;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(t, 0), tickPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, t), tickPaint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight.translate(-t, 0), tickPaint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, t), tickPaint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(t, 0), tickPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -t), tickPaint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-t, 0), tickPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(0, -t), tickPaint);
  }

  void _drawLabel(
      Canvas canvas, Rect rect, Detection d, Color color, Size canvasSize) {
    final text = '${d.label} ${(d.confidence * 100).toStringAsFixed(0)}%';
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );

    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();

    final pillW = tp.width + 10;
    final pillH = 16.0;

    double pillLeft = rect.left;
    double pillTop = rect.top - pillH - 2;

    // Keep pill inside canvas
    if (pillTop < 0) pillTop = rect.top + 2;
    if (pillLeft + pillW > canvasSize.width) {
      pillLeft = canvasSize.width - pillW - 2;
    }

    final pillRect =
        RRect.fromLTRBR(pillLeft, pillTop, pillLeft + pillW, pillTop + pillH,
            const Radius.circular(3));

    canvas.drawRRect(
        pillRect, Paint()..color = color.withOpacity(0.92));

    tp.paint(canvas, Offset(pillLeft + 5, pillTop + (pillH - tp.height) / 2));
  }

  Color _colorForLabel(String label) {
    return switch (label) {
      'car' => const Color(0xFF00D4FF),
      'truck' => const Color(0xFF7B61FF),
      'bus' => const Color(0xFFFF6B6B),
      'motorcycle' => const Color(0xFFFFD166),
      'bicycle' => const Color(0xFF06D6A0),
      'person' => const Color(0xFFFF9F1C),
      _ => const Color(0xFFCCCCCC),
    };
  }

  @override
  bool shouldRepaint(DetectionOverlayPainter old) =>
      old.detections != detections;
}