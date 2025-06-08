import 'package:flutter/material.dart';

// 각 탭 화면
import 'screens/dashboard.dart';
import 'screens/devices.dart';
import 'screens/monitoring.dart';
import 'screens/logs.dart';
import 'screens/users.dart';

/// BottomNavigationBar와 페이지 전환 담당
class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _currentIndex = 0;

  // 한 탭 = 한 파일 (screens/ 폴더).  const 사용 시 Hot-Reload 안정적
  final _pages = const [
    DashboardScreen(),
    DevicesScreen(),
    MonitoringScreen(),
    LogsScreen(),
    UsersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('화재 감지 시스템'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              // TODO: 로그아웃 로직
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: '기기'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: '모니터'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '로그'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '사용자'),
        ],
      ),
    );
  }
}
