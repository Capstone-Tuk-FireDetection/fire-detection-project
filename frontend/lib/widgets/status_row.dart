import 'package:flutter/material.dart';

/// 녹색 상태 점 + 텍스트 한 줄 (대시보드 재사용용)
class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.label,
    this.icon = Icons.circle,
    this.iconColor = Colors.green,
    this.iconSize = 16,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      );
}
