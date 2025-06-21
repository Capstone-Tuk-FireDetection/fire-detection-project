import 'package:flutter/material.dart';
import '../core/services/device_service.dart';

/// 실시간 모니터링 화면
class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  List<Map<String, dynamic>> _devices = [];
  String? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await DeviceService.instance.fetchDevices();
      setState(() {
        _devices = devices;
        _selected =
            devices.isNotEmpty ? devices.first['device_id'] as String? : null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return Column(
      children: [
        // 기기 선택
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButton<String>(
            value: _selected,
            isExpanded: true,
            items: _devices
                .map((d) => DropdownMenuItem(
                      value: d['device_id'] as String,
                      child: Text(d['nickname'] as String),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          ),
        ),

        // 비디오 스트림
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRect(
                child: Image.network(
                  DeviceService.instance.streamUri.toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Center(
                    child: Text('스트림을 불러올 수 없습니다'),
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
