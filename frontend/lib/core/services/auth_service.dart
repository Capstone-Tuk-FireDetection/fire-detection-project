import 'package:flutter/foundation.dart';
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
    if (UserStore.instance.contains(email)) {
      return '이미 존재하는 이메일입니다';
    }
    await UserStore.instance.addUser(email, pw, role);

    notifyListeners();           // ⭐️ 신규: UI(UsersScreen) 갱신 트리거
    return null;                 // null = 성공
  }
// …아래쪽 코드 동일…


  /// 로그인 (이메일·비밀번호 체크)
  Future<String?> signIn(String email, String pw) async {
    final user = UserStore.instance.getUser(email);
    if (user == null || user['pw'] != pw) {
      return '이메일 또는 비밀번호가 일치하지 않습니다';
    }
    _loggedIn = true;
    _email = email;
    _role = user['role'];
    notifyListeners();
    return null;
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
