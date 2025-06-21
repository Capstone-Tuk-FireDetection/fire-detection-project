import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceService {
  DeviceService._();
  static final instance = DeviceService._();

  /// Base URL of the Flask backend
  final String baseUrl = 'http://localhost:5000';

  /// MJPEG stream endpoint
  Uri get streamUri => Uri.parse('$baseUrl/api/stream-proxy');

  Future<List<Map<String, dynamic>>> fetchDevices() async {
    final uri = Uri.parse('$baseUrl/api/devices');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load devices: ${response.statusCode}');
    }
    final Map<String, dynamic> decoded = json.decode(response.body);
    final List<dynamic> raw = decoded['devices'] as List<dynamic>;
    return raw.cast<Map<String, dynamic>>();
  }
}
