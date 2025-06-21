import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 로그 조회 화면
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // ─── 더미 데이터 ───────────────────────────────────────────────────
  final List<String> _devices = const ['A', 'B', 'C'];

  final Map<String, List<Map<String, String>>> _deviceLogs = {
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

  void _copyLogs() {
    final text = _logs
        .map((l) =>
            '${l['device']} ${l['date']} ${l['time']} ${l['temp']}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('로그가 복사되었습니다')));
  }

  void _deleteLogs() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text('표시된 로그를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true) {
        setState(() {
          if (_selected == '전체') {
            for (final k in _deviceLogs.keys) {
              _deviceLogs[k]!.clear();
            }
          } else {
            _deviceLogs[_selected]!.clear();
          }
        });
      }
    });
  }

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

        // 복사·삭제 버튼
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(onPressed: _copyLogs, child: const Text('복사')),
            ElevatedButton(
              onPressed: _deleteLogs,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        ),
      ],
    );
  }
}
