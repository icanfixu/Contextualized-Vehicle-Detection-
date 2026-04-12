import 'dart:async';
import 'dart:math';
import '../models/detection.dart';

/// Simulates the JSON payloads that your FastAPI /ws/stats endpoint
/// will send after each YOLO inference frame.
///
/// Replace this with a real [WebSocketChannel] listener once the backend
/// is running — the data shape is identical.
class TrafficDataService {
  final _random = Random();
  final _controller = StreamController<FramePayload>.broadcast();
  Timer? _timer;

  Stream<FramePayload> get stream => _controller.stream;

  void start() {
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _controller.add(_generatePayload());
    });
  }

  void stop() {
    _timer?.cancel();
    _controller.close();
  }

  FramePayload _generatePayload() {
    return FramePayload(
      detections: _generateDetections(),
      zones: _generateZones(),
      timestamp: DateTime.now(),
    );
  }

  List<Detection> _generateDetections() {
    final labels = ['car', 'motorcycle', 'person', 'bicycle', 'truck', 'bus'];
    final count = 4 + _random.nextInt(8);
    return List.generate(count, (_) {
      final x1 = _random.nextDouble() * 0.7;
      final y1 = _random.nextDouble() * 0.7;
      return Detection(
        label: labels[_random.nextInt(labels.length)],
        confidence: 0.60 + _random.nextDouble() * 0.38,
        x1: x1,
        y1: y1,
        x2: x1 + 0.06 + _random.nextDouble() * 0.18,
        y2: y1 + 0.06 + _random.nextDouble() * 0.18,
      );
    });
  }

  List<ZoneStats> _generateZones() {
    return [
      _zone('z1', 'Lane 1 (left)'),
      _zone('z2', 'Lane 2 (centre)'),
      _zone('z3', 'Lane 3 (right)'),
      _zone('z4', 'Pedestrian crossing'),
    ];
  }

  ZoneStats _zone(String id, String name) {
    final v = _random.nextInt(20);
    final p = _random.nextInt(8);
    final c = _random.nextInt(6);
    final flow = 10.0 + _random.nextDouble() * 80;
    final score = (v * 3.5 + p * 2.0 + c * 1.5 + flow * 0.3).clamp(0, 100);
    return ZoneStats(
      zoneId: id,
      zoneName: name,
      vehicleCount: v,
      pedestrianCount: p,
      cyclistCount: c,
      flowRate: flow,
      complexityScore: score.toDouble(),
    );
  }
}