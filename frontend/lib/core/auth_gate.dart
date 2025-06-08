import 'package:flutter/material.dart';

import '../home_scaffold.dart';          // 로그인 후 메인
import '../screens/login.dart';          // 로그인 화면
import 'services/auth_service.dart';     // Auth 상태

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        return AuthService.instance.loggedIn
            ? const HomeScaffold()
            : const LoginScreen();
      },
    );
  }
}
