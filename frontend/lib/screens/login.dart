import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';   // signIn()

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;                     // ← 진행 인디케이터용

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('로그인', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),

                // 이메일
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: '이메일'),
                ),
                const SizedBox(height: 12),

                // 비밀번호
                TextField(
                  controller: _pwCtrl,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // 로그인 버튼 또는 로딩 스피너
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _onLoginPressed,
                        child: const Text('로그인'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✔️ 이메일·비밀번호 형식과 무관하게 즉시 로그인 처리
  Future<void> _onLoginPressed() async {
    setState(() => _loading = true);
    await AuthService.instance
        .signIn(_emailCtrl.text.trim(), _pwCtrl.text.trim());
    setState(() => _loading = false);
    // AuthGate 가 상태 변화를 감지해 홈 화면으로 전환합니다.
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }
}
