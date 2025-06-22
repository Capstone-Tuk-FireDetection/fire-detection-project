import 'dart:convert';
import 'package:http/http.dart' as http;

class LogsService {
  LogsService._();
  static final instance = LogsService._();

  /// Base URL of the Flask backend
  final String baseUrl = 'http://localhost:5000';

  Future<List<Map<String, dynamic>>> fetchLogs({String? device}) async {
    final uri = device != null
        ? Uri.parse('$baseUrl/api/logs?device=$device')
        : Uri.parse('$baseUrl/api/logs');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load logs: ${response.statusCode}');
    }
    final Map<String, dynamic> decoded = json.decode(response.body);
    final List<dynamic> raw = decoded['logs'] as List<dynamic>;
    return raw.cast<Map<String, dynamic>>();
  }

  Future<void> deleteLogs({String? device}) async {
    final uri = device != null
        ? Uri.parse('$baseUrl/api/logs?device=$device')
        : Uri.parse('$baseUrl/api/logs');
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete logs: ${response.statusCode}');
    }
  }
}
