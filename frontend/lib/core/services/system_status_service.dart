import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SystemStatusService {
  SystemStatusService._();
  static final instance = SystemStatusService._();

  /// Base URL of the Flask backend
  final String baseUrl = 'http://localhost:5000';

  Future<Map<String, dynamic>> fetchStatus() async {
    final uri = Uri.parse('$baseUrl/api/system-status');
    final token = await AuthService.instance.getIdToken();
    final response = await http.get(uri, headers: {
      if (token != null) 'Authorization': 'Bearer $token'
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to load status: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
