import 'package:flutter/material.dart';
import '../models/detection.dart';

class ZoneCard extends StatelessWidget {
  final ZoneStats stats;
  final bool isExpanded;
  final VoidCallback? onTap;

  const ZoneCard({
    super.key,
    required this.stats,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(stats.level);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: levelColor.withOpacity(isExpanded ? 0.7 : 0.25),
            width: isExpanded ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            _header(levelColor),
            if (isExpanded) _details(),
          ],
        ),
      ),
    );
  }

  Widget _header(Color levelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Level indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: levelColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: levelColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stats.zoneName,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Complexity score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: levelColor.withOpacity(0.4)),
            ),
            child: Text(
              stats.complexityScore.toStringAsFixed(0),
              style: TextStyle(
                color: levelColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Complexity bar
          _complexityBar(levelColor),
        ],
      ),
    );
  }

  Widget _complexityBar(Color color) {
    return SizedBox(
      width: 60,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Container(color: const Color(0xFF1F2937)),
            FractionallySizedBox(
              widthFactor: (stats.complexityScore / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.6), color],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          const Divider(color: Color(0xFF1F2937), height: 16),
          Row(
            children: [
              _stat('VEHICLES', stats.vehicleCount.toString(),
                  const Color(0xFF00D4FF)),
              _stat('PEDESTRIANS', stats.pedestrianCount.toString(),
                  const Color(0xFFFF9F1C)),
              _stat('CYCLISTS', stats.cyclistCount.toString(),
                  const Color(0xFF06D6A0)),
              _stat('FLOW', '${stats.flowRate.toStringAsFixed(0)}/m',
                  const Color(0xFF7B61FF)),
            ],
          ),
          const SizedBox(height: 10),
          _densityRow(),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _densityRow() {
    // Visual density bar — one pip per actor
    final total = stats.totalActors.clamp(0, 30);
    return Row(
      children: [
        const Text(
          'DENSITY',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: List.generate(
              total,
              (i) => Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _levelColor(stats.level).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _levelColor(ComplexityLevel level) => switch (level) {
        ComplexityLevel.low => const Color(0xFF06D6A0),
        ComplexityLevel.medium => const Color(0xFFFFD166),
        ComplexityLevel.high => const Color(0xFFEF476F),
      };
}