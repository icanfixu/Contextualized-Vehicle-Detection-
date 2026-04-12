import 'dart:math';
import 'package:flutter/material.dart';
import '../models/detection.dart';
import 'detection_overlay.dart';

/// Fully self-contained dummy video feed.
/// Renders an animated top-down road scene with lane markings, moving
/// "vehicles", and scanline noise — no network required.
///
/// Swap this widget for a real MJPEG reader when your FastAPI backend is ready.
class VideoFeedWidget extends StatefulWidget {
  // kept for API compatibility — ignored in dummy mode
  final String streamUrl;
  final List<Detection> detections;
  final bool showOverlay;

  const VideoFeedWidget({
    super.key,
    required this.streamUrl,
    required this.detections,
    this.showOverlay = true,
  });

  @override
  State<VideoFeedWidget> createState() => _VideoFeedWidgetState();
}

class _VideoFeedWidgetState extends State<VideoFeedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated road scene
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _RoadScenePainter(_ctrl.value),
              ),
            ),

            // Bounding-box overlay driven by dummy detections
            if (widget.showOverlay)
              CustomPaint(
                painter: DetectionOverlayPainter(widget.detections),
              ),

            // Scanline CRT overlay for that surveillance-cam feel
            CustomPaint(painter: _ScanlinePainter()),

            // HUD
            _hudTop(),
            _hudBottom(),
          ],
        ),
      ),
    );
  }

  Widget _hudTop() {
    return Positioned(
      top: 10,
      left: 10,
      child: Row(
        children: [
          _BlinkingDot(),
          const SizedBox(width: 5),
          const Text(
            'DEMO',
            style: TextStyle(
              color: Color(0xFFEF476F),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'CAM 01 — INTERSECTION A',
            style: TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudBottom() {
    return const Positioned(
      bottom: 8,
      right: 10,
      child: Text(
        'DUMMY FEED — swap VideoFeedWidget for MJPEG',
        style: TextStyle(
          color: Color(0x55FFFFFF),
          fontSize: 8,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blinking red dot
// ---------------------------------------------------------------------------
class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFFEF476F),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Road scene painter
// ---------------------------------------------------------------------------
class _RoadScenePainter extends CustomPainter {
  final double t; // 0..1 animation progress

  _RoadScenePainter(this.t);

  // Fixed set of dummy cars — seeded so positions are deterministic per lane
  static final List<_DummyCar> _cars = List.generate(14, (i) {
    final rng = Random(i * 31 + 7);
    return _DummyCar(
      lane: rng.nextInt(4),
      yOffset: rng.nextDouble(),
      speed: 0.12 + rng.nextDouble() * 0.28,
      width: 0.045 + rng.nextDouble() * 0.025,
      height: 0.055 + rng.nextDouble() * 0.03,
      color: [
        const Color(0xFF334155),
        const Color(0xFF1E3A5F),
        const Color(0xFF3B2F2F),
        const Color(0xFF2D3748),
        const Color(0xFF1A2E44),
      ][rng.nextInt(5)],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF111827),
    );

    _drawRoad(canvas, size);
    _drawMarkings(canvas, size);
    _drawZoneTints(canvas, size);

    for (final car in _cars) {
      _drawCar(canvas, size, car);
    }

    _drawPedestrians(canvas, size);
  }

  void _drawRoad(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.08, 0, size.width * 0.92, size.height),
      Paint()..color = const Color(0xFF1A1F2E),
    );
  }

  void _drawMarkings(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = const Color(0xFF374151)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final solidPaint = Paint()
      ..color = const Color(0xFF4B5563)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final roadLeft = size.width * 0.08;
    final roadRight = size.width * 0.92;
    final laneWidth = (roadRight - roadLeft) / 4;

    for (int i = 1; i < 4; i++) {
      final x = roadLeft + laneWidth * i;
      final dashLen = size.height * 0.06;
      final gapLen = size.height * 0.04;
      final cycle = dashLen + gapLen;
      double y = -cycle + (t * cycle * 2) % cycle;
      while (y < size.height) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + dashLen),
          i == 3 ? solidPaint : dashPaint,
        );
        y += cycle;
      }
    }

    canvas.drawLine(
        Offset(roadLeft, 0), Offset(roadLeft, size.height), solidPaint);
    canvas.drawLine(
        Offset(roadRight, 0), Offset(roadRight, size.height), solidPaint);

    _drawZebra(canvas, size, roadLeft, roadRight);
  }

  void _drawZebra(
      Canvas canvas, Size size, double roadLeft, double roadRight) {
    final zebraPaint = Paint()..color = const Color(0xFF2D3748);
    const stripeCount = 8;
    final crossingTop = size.height * 0.72;
    final crossingHeight = size.height * 0.10;
    final stripeWidth = (roadRight - roadLeft) / (stripeCount * 2 - 1);

    for (int i = 0; i < stripeCount; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          roadLeft + i * stripeWidth * 2,
          crossingTop,
          stripeWidth,
          crossingHeight,
        ),
        zebraPaint,
      );
    }
  }

  void _drawZoneTints(Canvas canvas, Size size) {
    final roadLeft = size.width * 0.08;
    final laneWidth = (size.width * 0.84) / 4;

    canvas.drawRect(
      Rect.fromLTRB(
        roadLeft + laneWidth * 3,
        0,
        roadLeft + laneWidth * 4,
        size.height,
      ),
      Paint()..color = const Color(0xFFFF9F1C).withOpacity(0.04),
    );
  }

  void _drawCar(Canvas canvas, Size size, _DummyCar car) {
    final roadLeft = size.width * 0.08;
    final laneWidth = (size.width * 0.84) / 4;
    final laneCenter = roadLeft + laneWidth * car.lane + laneWidth / 2;
    final carW = size.width * car.width;
    final carH = size.height * car.height;
    final rawY = (car.yOffset + t * car.speed) % 1.0;
    final carY = rawY * size.height - carH;

    final rect = Rect.fromCenter(
      center: Offset(laneCenter, carY + carH / 2),
      width: carW,
      height: carH,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = car.color,
    );

    // Windshield
    canvas.drawRect(
      Rect.fromLTWH(rect.left + carW * 0.2, rect.top + carH * 0.08,
          carW * 0.6, carH * 0.25),
      Paint()..color = const Color(0xFF1E3A5F).withOpacity(0.6),
    );

    // Headlights
    final headPaint =
        Paint()..color = const Color(0xFFFFD166).withOpacity(0.85);
    canvas.drawCircle(
        Offset(rect.left + carW * 0.25, rect.top + carH * 0.08), 2, headPaint);
    canvas.drawCircle(
        Offset(rect.left + carW * 0.75, rect.top + carH * 0.08), 2, headPaint);

    // Tail lights
    final tailPaint =
        Paint()..color = const Color(0xFFEF476F).withOpacity(0.85);
    canvas.drawCircle(
        Offset(rect.left + carW * 0.25, rect.bottom - carH * 0.08), 2,
        tailPaint);
    canvas.drawCircle(
        Offset(rect.left + carW * 0.75, rect.bottom - carH * 0.08), 2,
        tailPaint);
  }

  void _drawPedestrians(Canvas canvas, Size size) {
    final roadLeft = size.width * 0.08;
    final laneWidth = (size.width * 0.84) / 4;
    final pedLaneCenter = roadLeft + laneWidth * 3 + laneWidth / 2;

    final positions = [
      (0.3 + t * 0.15) % 1.0,
      (0.7 + t * 0.10) % 1.0,
    ];

    for (final yFrac in positions) {
      final cx = pedLaneCenter + (yFrac > 0.5 ? 10.0 : -10.0);
      final cy = yFrac * size.height;
      final r = size.width * 0.008;

      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = const Color(0xFFFF9F1C).withOpacity(0.9),
      );

      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + r * 1.8), width: r * 1.6, height: r * 0.5),
        Paint()..color = Colors.black.withOpacity(0.3),
      );
    }
  }

  @override
  bool shouldRepaint(_RoadScenePainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Scanline + vignette overlay
// ---------------------------------------------------------------------------
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      y += 3;
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

// ---------------------------------------------------------------------------
// Data class for a dummy vehicle
// ---------------------------------------------------------------------------
class _DummyCar {
  final int lane;
  final double yOffset;
  final double speed;
  final double width;
  final double height;
  final Color color;

  const _DummyCar({
    required this.lane,
    required this.yOffset,
    required this.speed,
    required this.width,
    required this.height,
    required this.color,
  });
}