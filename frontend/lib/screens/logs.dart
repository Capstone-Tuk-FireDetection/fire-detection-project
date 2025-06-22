import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/device_service.dart';
import '../core/services/logs_service.dart';

/// 로그 조회 화면
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<String> _devices = [];
  List<Map<String, dynamic>> _logs = [];
  String _selected = '전체';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final devices = await DeviceService.instance.fetchDevices();
      setState(() {
        _devices = devices.map((d) => d['device_id'] as String).toList();
      });
    } catch (_) {
      // ignore errors fetching devices
    }
    await _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final logs = await LogsService.instance
          .fetchLogs(device: _selected == '전체' ? null : _selected);
      setState(() => _logs = logs);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

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
    ).then((confirm) async {
      if (confirm == true) {
        try {
          await LogsService.instance
              .deleteLogs(device: _selected == '전체' ? null : _selected);
          await _loadLogs();
        } catch (e) {
          setState(() => _error = e.toString());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

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
          onChanged: (v) {
            setState(() => _selected = v!);
            _loadLogs();
          },
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
