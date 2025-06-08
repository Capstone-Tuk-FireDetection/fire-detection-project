import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  AuthService._private();
  static final instance = AuthService._private();

  // 더미 사용자 상태
  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  Future<void> signIn(String email, String pw) async {
    // TODO: 서버 요청 ↔︎ 성공 시
    await Future.delayed(const Duration(seconds: 1));
    _loggedIn = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    _loggedIn = false;
    notifyListeners();
  }
}
