import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  String _role = '일반';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: '이메일'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pwCtrl,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _role,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: '관리자', child: Text('관리자')),
                    DropdownMenuItem(value: '일반', child: Text('일반')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _onRegisterPressed,
                        child: const Text('가입하기'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRegisterPressed() async {
    setState(() => _loading = true);
    final error = await AuthService.instance
        .signUp(_emailCtrl.text.trim(), _pwCtrl.text.trim(), _role);
    setState(() => _loading = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(error ?? '회원가입이 완료되었습니다'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (error == null) Navigator.pop(context); // 가입 성공 시 로그인 화면으로
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }
}
