import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';   // signIn()
import 'register.dart'; 
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
                      TextButton(
                         onPressed: () => Navigator.push(
                           context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                         child: const Text('회원가입'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
Future<void> _onLoginPressed() async {
  setState(() => _loading = true);
  final error = await AuthService.instance
      .signIn(_emailCtrl.text.trim(), _pwCtrl.text.trim());
  setState(() => _loading = false);
  if (error != null) {
    showDialog(context: context, builder: (_) =>
      AlertDialog(content: Text(error), actions:[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))
      ]));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }
}
}