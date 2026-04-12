/// A single detected object returned by the FastAPI backend.
class Detection {
  final String label;
  final double confidence;

  /// Normalised bounding box — all values in [0.0, 1.0].
  final double x1, y1, x2, y2;

  const Detection({
    required this.label,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
        label: json['label'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        x1: (json['x1'] as num).toDouble(),
        y1: (json['y1'] as num).toDouble(),
        x2: (json['x2'] as num).toDouble(),
        y2: (json['y2'] as num).toDouble(),
      );
}

/// Per-lane / per-zone statistics sent by the backend each frame.
class ZoneStats {
  final String zoneId;
  final String zoneName;
  final int vehicleCount;
  final int pedestrianCount;
  final int cyclistCount;

  /// Vehicles per minute
  final double flowRate;

  /// 0–100 composite score
  final double complexityScore;

  const ZoneStats({
    required this.zoneId,
    required this.zoneName,
    required this.vehicleCount,
    required this.pedestrianCount,
    required this.cyclistCount,
    required this.flowRate,
    required this.complexityScore,
  });

  int get totalActors => vehicleCount + pedestrianCount + cyclistCount;

  ComplexityLevel get level {
    if (complexityScore < 33) return ComplexityLevel.low;
    if (complexityScore < 66) return ComplexityLevel.medium;
    return ComplexityLevel.high;
  }

  factory ZoneStats.fromJson(Map<String, dynamic> json) => ZoneStats(
        zoneId: json['zone_id'] as String,
        zoneName: json['zone_name'] as String,
        vehicleCount: (json['vehicle_count'] as num).toInt(),
        pedestrianCount: (json['pedestrian_count'] as num).toInt(),
        cyclistCount: (json['cyclist_count'] as num).toInt(),
        flowRate: (json['flow_rate'] as num).toDouble(),
        complexityScore: (json['complexity_score'] as num).toDouble(),
      );
}

enum ComplexityLevel { low, medium, high }

/// Full payload arriving each tick from the backend.
class FramePayload {
  final List<Detection> detections;
  final List<ZoneStats> zones;
  final DateTime timestamp;

  const FramePayload({
    required this.detections,
    required this.zones,
    required this.timestamp,
  });

  factory FramePayload.fromJson(Map<String, dynamic> json) => FramePayload(
        detections: (json['detections'] as List)
            .map((d) => Detection.fromJson(d as Map<String, dynamic>))
            .toList(),
        zones: (json['zones'] as List)
            .map((z) => ZoneStats.fromJson(z as Map<String, dynamic>))
            .toList(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}