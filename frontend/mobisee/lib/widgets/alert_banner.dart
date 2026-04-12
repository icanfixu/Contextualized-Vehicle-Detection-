import 'package:flutter/material.dart';
import '../models/detection.dart';

class AlertBanner extends StatelessWidget {
  final List<ZoneStats> zones;

  const AlertBanner({super.key, required this.zones});

  @override
  Widget build(BuildContext context) {
    final highZones = zones.where((z) => z.level == ComplexityLevel.high).toList();
    final medZones = zones.where((z) => z.level == ComplexityLevel.medium).toList();

    if (highZones.isNotEmpty) {
      return _banner(
        color: const Color(0xFFEF476F),
        icon: Icons.warning_amber_rounded,
        label:
            'HIGH COMPLEXITY — ${highZones.map((z) => z.zoneName).join(', ')}',
      );
    }
    if (medZones.isNotEmpty) {
      return _banner(
        color: const Color(0xFFFFD166),
        icon: Icons.info_outline_rounded,
        label:
            'MODERATE TRAFFIC — ${medZones.map((z) => z.zoneName).join(', ')}',
      );
    }
    return _banner(
      color: const Color(0xFF06D6A0),
      icon: Icons.check_circle_outline_rounded,
      label: 'ALL ZONES CLEAR',
    );
  }

  Widget _banner({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(label),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          border: Border(
            left: BorderSide(color: color, width: 3),
            bottom: BorderSide(color: color.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}