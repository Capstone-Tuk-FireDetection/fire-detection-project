import 'package:flutter/material.dart';
import '../core/services/user_store.dart';
import '../core/services/auth_service.dart';

/// 모든 계정을 실시간 표시하는 사용자 관리 화면
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late String _selectedEmail;

  @override
  void initState() {
    super.initState();
    final emails = UserStore.instance.allUsers.keys.toList();
    _selectedEmail = emails.first;
    // AuthService 변경 알림을 수신해 리스트 갱신
    AuthService.instance.addListener(_refreshOnChange);
  }

  void _refreshOnChange() {
    setState(() {
      // 새로 가입한 계정이 있을 수 있으므로 선택 값 보정
      if (!UserStore.instance.allUsers.containsKey(_selectedEmail)) {
        _selectedEmail = UserStore.instance.allUsers.keys.first;
      }
    });
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_refreshOnChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = UserStore.instance.allUsers;
    final selected = users[_selectedEmail]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🔽 이메일 기준 드롭다운
        DropdownButton<String>(
          value: _selectedEmail,
          isExpanded: true,
          items: users.keys
              .map((email) =>
                  DropdownMenuItem(value: email, child: Text(email)))
              .toList(),
          onChanged: (v) => setState(() => _selectedEmail = v!),
        ),
        const SizedBox(height: 16),

        _detailTile('권한', selected['role']!),
        _detailTile('이메일', _selectedEmail),
        const SizedBox(height: 24),

        // (예시) 계정 삭제 버튼
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                content: const Text('해당 계정을 삭제할까요?'),
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
            );
            if (confirm == true) {
              await AuthService.instance.deleteUser(_selectedEmail);
            }
          },
          child: const Text('삭제'),
        ),
      ],
    );
  }

  Widget _detailTile(String label, String value) => ListTile(
        title: Text(label),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
