import 'package:flutter/material.dart';

/// 로그 조회 화면
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // ─── 더미 데이터 ───────────────────────────────────────────────────
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
  // ──────────────────────────────────────────────────────────────

  String _selected = '전체';

  List<Map<String, String>> get _logs => _selected == '전체'
      ? _deviceLogs.entries
          .expand((e) => e.value.map((m) => {...m, 'device': e.key}))
          .toList()
      : _deviceLogs[_selected]!
          .map((m) => {...m, 'device': _selected})
          .toList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 기기 필터
        DropdownButton<String>(
          value: _selected,
          isExpanded: true,
          items: ['전체', ..._devices]
              .map((d) => DropdownMenuItem(value: d, child: Text('단말기 $d')))
              .toList(),
          onChanged: (v) => setState(() => _selected = v!),
        ),
        const SizedBox(height: 16),

        // 로그 테이블
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('기기')),
              DataColumn(label: Text('날짜')),
              DataColumn(label: Text('시간')),
              DataColumn(label: Text('온도')),
            ],
            rows: [
              for (final log in _logs)
                DataRow(cells: [
                  DataCell(Text(log['device']!)),
                  DataCell(Text(log['date']!)),
                  DataCell(Text(log['time']!)),
                  DataCell(Text(log['temp']!)),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 복사·삭제 버튼 (기능은 TODO)
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('복사')),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        ),
      ],
    );
  }
}
