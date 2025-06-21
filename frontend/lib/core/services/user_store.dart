import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserStore {
  static const _kUsersKey = 'users_json';
  late Map<String, Map<String, String>> _users;

  // 🔹 외부에서 읽기용으로 사용
  Map<String, Map<String, String>> get allUsers => _users;

  UserStore._();
  static final instance = UserStore._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kUsersKey);

    if (jsonStr == null) {
      // ▶ 앱 최초 실행 시 기본 계정 2개 삽입
      _users = {
  'TUK@tukorea.ac.kr':  {'pw': '123', 'role': '관리자'},
  'Tino@tukorea.ac.kr': {'pw': '123', 'role': '일반'},
};
      await _persist();
      return;
    }

    // 🔑 안전 캐스팅
    final Map<String, dynamic> raw =
        json.decode(jsonStr) as Map<String, dynamic>;
    _users = raw.map((k, v) =>
        MapEntry(k, Map<String, String>.from(v as Map<String, dynamic>)));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsersKey, json.encode(_users));
  }

  bool contains(String email) => _users.containsKey(email);

  Future<void> addUser(String email, String pw, String role) async {
    _users[email] = {'pw': pw, 'role': role};
    await _persist();
  }

  Map<String, String>? getUser(String email) => _users[email];

  Future<void> removeUser(String email) async {
    _users.remove(email);
    await _persist();
  }
}
