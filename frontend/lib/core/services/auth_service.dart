import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_store.dart';

class AuthService with ChangeNotifier {
  AuthService._();
  static final instance = AuthService._();

  bool _loggedIn = false;
  String? _email;               // 현재 로그인 이메일
  String? _role;                // '관리자' | '일반'

  bool get loggedIn => _loggedIn;
  String? get email => _email;
  String? get role => _role;

  /// 앱 시작 시 UserStore 초기화
  Future<void> init() async => UserStore.instance.init();

 // …위쪽 코드 동일…
  Future<String?> signUp(String email, String pw, String role) async {
    final uri = Uri.parse('http://localhost:5000/api/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': pw, 'role': role}),
    );
    if (response.statusCode == 201) {
      notifyListeners();
      return null;
    }
    final Map<String, dynamic> decoded = json.decode(response.body);
    return decoded['error'] as String? ?? '가입 실패';
  }
// …아래쪽 코드 동일…


  /// 로그인 (이메일·비밀번호 체크)
  Future<String?> signIn(String email, String pw) async {
    final uri = Uri.parse('http://localhost:5000/api/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': pw}),
    );
    final Map<String, dynamic> decoded = json.decode(response.body);
    if (response.statusCode == 200) {
      _loggedIn = true;
      _email = email;
      _role = decoded['role'] as String?;
      notifyListeners();
      return null;
    }
    return decoded['error'] as String? ?? '로그인 실패';
  }
  
  Future<void> signOut() async {
    _loggedIn = false;
    _email = null;
    _role = null;
    notifyListeners();
  }

  Future<void> deleteUser(String email) async {
    await UserStore.instance.removeUser(email);
    if (_email == email) {
      await signOut();
    } else {
      notifyListeners();
    }
  }
}
