import 'package:flutter/material.dart';
import '../widgets/status_row.dart';
import '../core/services/system_status_service.dart';

/// 홈 대시보드 화면
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic>? _status;
  bool _serverOnline = false;

  // ─── 예시용 더미 데이터 ───────────────────────────────────────────────
  
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
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await SystemStatusService.instance.fetchStatus();
      setState(() {
        _status = data;
        _serverOnline = true;
      });
    } catch (e) {
      setState(() {
        _serverOnline = false;
        _status = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final recentLogs = _deviceLogs.entries
        .expand((e) => e.value.map((m) => {...m, 'device': e.key}))
        .take(5)
        .toList();

    final serverOnline = _serverOnline && _status?['server'] == 'online';
    final devices = serverOnline
        ? (_status?['devices'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
        : _deviceLogs.keys
            .map((id) => {'device_id': id, 'status': 'offline'})
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
                  StatusRow(
                      label: '서버 ' + (serverOnline ? '온라인' : '오프라인'),
                      iconColor: serverOnline ? Colors.green : Colors.red),
                  const SizedBox(height: 12),
                  ...devices.map((d) => StatusRow(
                        label:
                            '단말기 ${d['device_id']} ${d['status'] == 'online' ? '온라인' : '오프라인'}',
                        iconColor: d['status'] == 'online'
                            ? Colors.green
                            : Colors.red,
                      )),
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
