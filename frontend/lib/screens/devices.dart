import 'package:flutter/material.dart';

/// 기기 관리 화면
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<String> _devices = const ['A', 'B', 'C'];
  late String _selected = _devices.first;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 기기 선택 드롭다운
        DropdownButton<String>(
          value: _selected,
          isExpanded: true,
          items: _devices
              .map((d) => DropdownMenuItem(value: d, child: Text('단말기 $d')))
              .toList(),
          onChanged: (v) => setState(() => _selected = v!),
        ),
        const SizedBox(height: 16),

        // 기기 상세
        _detailTile('상태', '온라인'),
        _detailTile('고유 ID', '2BCLP-ESP-32S'),
        _detailTile('총 온라인 시간', '19h 21min'),
        _detailTile('현재 활성화 시간', '1h 16min'),
        _detailTile('카메라 상태', '정상'),
        _detailTile('온도 센서 상태', '정상'),
        _detailTile('불꽃 센서 상태', '정상'),
        const SizedBox(height: 24),

        // 액션 버튼
        Wrap(
          spacing: 8,
          children: [
            _actionButton('이름 변경'),
            _actionButton('재부팅'),
            _actionButton('종료'),
            _actionButton('삭제', color: Colors.red),
          ],
        ),
      ],
    );
  }

  /// 리스트 타일 생성 헬퍼
  Widget _detailTile(String label, String value) => ListTile(
        title: Text(label),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  /// 액션 버튼 헬퍼
  Widget _actionButton(String label, {Color? color}) => ElevatedButton(
        onPressed: () {
          // TODO: 실제 기기 제어 로직
        },
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(label),
      );
}
