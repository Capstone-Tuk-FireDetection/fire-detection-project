import 'package:flutter/material.dart';

/// 홈 대시보드 화면
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ─── 예시용 더미 데이터 ───────────────────────────────────────────────
  final List<String> _devices = const ['A', 'B', 'C'];

  final Map<String, List<Map<String, String>>> _deviceLogs = const {
    'A': [
      {'date': '2024/12/04', 'time': '15:25', 'temp': '24°C'},
      {'date': '2025/01/04', 'time': '14:25', 'temp': '23°C'},
      {'date': '2025/02/03', 'time': '01:21', 'temp': '32°C'},
    ],
    'B': [
      {'date': '2025/02/03', 'time': '01:21', 'temp': '32°C'},
    ],
    'C': [],
  };
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final recentLogs = _deviceLogs.entries
        .expand((e) => e.value.map((m) => {...m, 'device': e.key}))
        .take(5)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // 시스템 상태 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('시스템 상태',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _StatusRow('서버 온라인'),
                  const SizedBox(height: 12),
                  ..._devices.map((d) => _StatusRow('단말기 $d 온라인')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 최근 기록 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('최근 기록',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('날짜')),
                        DataColumn(label: Text('시간')),
                        DataColumn(label: Text('단말기')),
                      ],
                      rows: [
                        for (final log in recentLogs)
                          DataRow(cells: [
                            DataCell(Text(log['date']!)),
                            DataCell(Text(log['time']!)),
                            DataCell(Text(log['device']!)),
                          ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 대시보드용 상태 줄
class _StatusRow extends StatelessWidget {
  const _StatusRow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      );
}
