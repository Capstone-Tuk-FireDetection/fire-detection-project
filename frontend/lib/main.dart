import 'package:flutter/material.dart';
import 'core/auth_gate.dart';
import 'home_scaffold.dart';
import 'core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();   // ← UserStore 초기화
  runApp(const FireDetectionAdminApp());
}

class FireDetectionAdminApp extends StatelessWidget {
  const FireDetectionAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '화재 감지 시스템',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        colorSchemeSeed: Colors.deepOrange,
      ),
      // ⬇️  HomeScaffold 대신 AuthGate로 이동
      home: const AuthGate(),
    );
  }
}
