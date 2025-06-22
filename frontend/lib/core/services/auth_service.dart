import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'user_store.dart';

class AuthService with ChangeNotifier {
  AuthService._();
  static final instance = AuthService._();

  bool _loggedIn = false;
  String? _email;               // 현재 로그인 이메일
  String? _role;                // '관리자' | '일반'
  String? _idToken;             // Firebase ID 토큰

  bool get loggedIn => _loggedIn;
  String? get email => _email;
  String? get role => _role;
  String? get idToken => _idToken;

  /// 앱 시작 시 UserStore 초기화
  Future<void> init() async => UserStore.instance.init();

 // …위쪽 코드 동일…
  Future<String?> signUp(String email, String pw, String role) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pw);
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Firebase 가입 실패';
    }

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


  /// 로그인 (Firebase 인증 후 백엔드 로그인)
  Future<String?> signIn(String email, String pw) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pw);
      _idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Firebase 로그인 실패';
    }

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
    await FirebaseAuth.instance.signOut();
    _loggedIn = false;
    _email = null;
    _role = null;
    _idToken = null;
    notifyListeners();
  }

  /// 현재 Firebase ID 토큰을 가져옵니다
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    _idToken = await user.getIdToken(forceRefresh);
    return _idToken;
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
