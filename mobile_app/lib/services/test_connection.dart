import 'package:dio/dio.dart';

class TestConnection {
  static Future<void> testDjangoConnection() async {
    final dio = Dio();
    
    try {
      // Test Django server is running
      final response = await dio.get('http://localhost:8000/inventory/process-scan/');
      print('Django server response: ${response.statusCode}');
    } catch (e) {
      print('Connection error: $e');
    }
  }
}
