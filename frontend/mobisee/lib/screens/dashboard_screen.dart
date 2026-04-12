import 'package:flutter/material.dart';
import '../models/detection.dart';
import '../services/traffic_data_service.dart';
import '../widgets/alert_banner.dart';
import '../widgets/video_feed.dart';
import '../widgets/zone_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = TrafficDataService();
  FramePayload? _latest;

  /// Which zone card is expanded
  String? _expandedZone;

  bool _showOverlay = true;

  /// Replace with your FastAPI MJPEG endpoint
  static const _streamUrl = 'http://localhost:8000/video_feed';

  @override
  void initState() {
    super.initState();
    _service.start();
    _service.stream.listen((payload) {
      if (mounted) setState(() => _latest = payload);
    });
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zones = _latest?.zones ?? [];
    final detections = _latest?.detections ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            AlertBanner(zones: zones),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Side-by-side on wide screens, stacked on narrow
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _videoPane(detections),
                        ),
                        SizedBox(
                          width: 280,
                          child: _statsPane(zones, detections),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _videoPane(detections),
                      Expanded(child: _statsPane(zones, detections)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF111827), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(0.4)),
            ),
            child: const Icon(
              Icons.traffic_rounded,
              color: Color(0xFF00D4FF),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'MTCA',
            style: TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Mixed Traffic Complexity Analyzer',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          // Overlay toggle
          _overlayToggle(),
          const SizedBox(width: 12),
          _clockWidget(),
        ],
      ),
    );
  }

  Widget _overlayToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showOverlay = !_showOverlay),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _showOverlay
              ? const Color(0xFF00D4FF).withOpacity(0.1)
              : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: _showOverlay
                ? const Color(0xFF00D4FF).withOpacity(0.4)
                : const Color(0xFF1F2937),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.layers_rounded,
              size: 13,
              color: _showOverlay
                  ? const Color(0xFF00D4FF)
                  : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 5),
            Text(
              'Overlay',
              style: TextStyle(
                color: _showOverlay
                    ? const Color(0xFF00D4FF)
                    : const Color(0xFF4B5563),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clockWidget() {
    final now = _latest?.timestamp ?? DateTime.now();
    return Text(
      '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}',
      style: const TextStyle(
        color: Color(0xFF4B5563),
        fontSize: 12,
        fontFeatures: [FontFeature.tabularFigures()],
        fontFamily: 'monospace',
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Widget _videoPane(List<Detection> detections) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VideoFeedWidget(
            streamUrl: _streamUrl,
            detections: detections,
            showOverlay: _showOverlay,
          ),
          const SizedBox(height: 10),
          _detectionLegend(detections),
        ],
      ),
    );
  }

  Widget _detectionLegend(List<Detection> detections) {
    // Tally counts per label
    final counts = <String, int>{};
    for (final d in detections) {
      counts[d.label] = (counts[d.label] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: counts.entries.map((e) {
        final color = _labelColor(e.key);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                '${e.key}  ${e.value}',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _labelColor(String label) => switch (label) {
        'car' => const Color(0xFF00D4FF),
        'truck' => const Color(0xFF7B61FF),
        'bus' => const Color(0xFFFF6B6B),
        'motorcycle' => const Color(0xFFFFD166),
        'bicycle' => const Color(0xFF06D6A0),
        'person' => const Color(0xFFFF9F1C),
        _ => const Color(0xFFCCCCCC),
      };

  Widget _statsPane(List<ZoneStats> zones, List<Detection> detections) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF111827))),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionLabel('ZONE ANALYSIS'),
          const SizedBox(height: 6),
          ...zones.map((z) => ZoneCard(
                stats: z,
                isExpanded: _expandedZone == z.zoneId,
                onTap: () => setState(() {
                  _expandedZone =
                      _expandedZone == z.zoneId ? null : z.zoneId;
                }),
              )),
          const SizedBox(height: 16),
          _sectionLabel('DETECTION SUMMARY'),
          const SizedBox(height: 6),
          _summaryPanel(detections),
          const SizedBox(height: 16),
          _sectionLabel('BACKEND'),
          const SizedBox(height: 6),
          _backendInfo(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4B5563),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      );

  Widget _summaryPanel(List<Detection> detections) {
    final totalActors = detections.length;
    final avgConf = detections.isEmpty
        ? 0.0
        : detections.map((d) => d.confidence).reduce((a, b) => a + b) /
            detections.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          _bigStat('ACTORS', totalActors.toString(), const Color(0xFF00D4FF)),
          _bigStat(
            'AVG CONF',
            '${(avgConf * 100).toStringAsFixed(0)}%',
            const Color(0xFF7B61FF),
          ),
        ],
      ),
    );
  }

  Widget _bigStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }

  Widget _backendInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Video stream', _streamUrl),
          const SizedBox(height: 6),
          _infoRow(
              'Stats WS', _streamUrl.replaceFirst('/video_feed', '/ws/stats')),
          const SizedBox(height: 6),
          _infoRow('Tick rate', '~800 ms (dummy)'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}