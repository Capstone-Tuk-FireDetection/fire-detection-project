import 'package:flutter/material.dart';

/// 사용자 관리 화면
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // ─── 예시용 더미 사용자 목록 ──────────────────────────────────────────
  final List<Map<String, String>> _users = const [
    {
      'name': 'TUK',
      'email': 'admin@tukorea.ac.kr',
      'role': '관리자',
      'status': '온라인'
    },
    {
      'name': 'Tino',
      'email': '123123@tukorea.ac.kr',
      'role': '일반',
      'status': '온라인'
    },
  ];
  // ────────────────────────────────────────────────────────────────

  late Map<String, String> _selectedUser;

  @override
  void initState() {
    super.initState();
    _selectedUser = _users.first; // 초기 선택
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 사용자 선택 드롭다운
        DropdownButton<String>(
          value: _selectedUser['name'],
          isExpanded: true,
          items: _users
              .map((u) =>
                  DropdownMenuItem(value: u['name'], child: Text(u['name']!)))
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedUser = _users.firstWhere((u) => u['name'] == v)),
        ),
        const SizedBox(height: 16),

        // 상세 정보
        _detailTile('상태', _selectedUser['status']!),
        _detailTile('이메일', _selectedUser['email']!),
        _detailTile('가입 일자', '2024/12/22 15:23'),
        _detailTile('등급', _selectedUser['role']!),
        const SizedBox(height: 24),

        // 액션 버튼
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('등급 변경')),
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

  /// 간단한 라벨-값 표시 타일
  Widget _detailTile(String label, String value) => ListTile(
        title: Text(label),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
