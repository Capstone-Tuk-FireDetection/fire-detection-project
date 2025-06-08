import 'package:flutter/material.dart';

/// 실시간 모니터링 화면
class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  // ─── 예시용 더미 기기 목록 ────────────────────────────────────────────
  final List<String> _devices = const ['A', 'B', 'C'];
  late String _selected = _devices.first;
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 기기 선택
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButton<String>(
            value: _selected,
            isExpanded: true,
            items: _devices
                .map((d) => DropdownMenuItem(value: d, child: Text('단말기 $d')))
                .toList(),
            onChanged: (v) => setState(() => _selected = v!),
          ),
        ),

        // 비디오 스트림(더미)
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(
                  child: Text(
                    '카메라 영상 (클릭하여 스트림)',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        const Text('현재 온도: 23°C', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
      ],
    );
  }
}
