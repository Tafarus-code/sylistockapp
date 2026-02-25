import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Django Connection Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('Django Connection Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _testConnection(context),
                child: const Text('Test Django Connection'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openBrowser,
                child: const Text('Open in Browser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBrowser() async {
    // This will show the URL to test manually
    print('Open this URL in browser: http://127.0.0.1:8000/inventory/');
  }

  Future<void> _testConnection(BuildContext context) async {
  print('=== BUTTON CLICKED! Starting Django connection test... ===');
  
  // Show immediate feedback
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Testing connection...')),
  );
  
  String dialogTitle = 'Connection Test';
  String dialogContent = 'Testing...';

  try {
    print('Making request to http://127.0.0.1:8000/inventory/');
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    
    final response = await dio.get('http://127.0.0.1:8000/inventory/');
    print('Response received: ${response.statusCode}');
    print('Response data: ${response.data}');
    
    dialogTitle = 'SUCCESS! Status: ${response.statusCode}';
    dialogContent = 'Django connection working!\n\nData: ${response.data}';
  } catch (e, stackTrace) {
    print('ERROR occurred: $e');
    print('Stack trace: $stackTrace');
    
    dialogTitle = 'Connection Failed';
    dialogContent = 'ERROR!\n\n$e\n\nTroubleshooting:\n• Is Django server running on port 8000?\n• Check browser console for errors\n• Try opening http://127.0.0.1:8000/inventory/ in browser';
  }
  
  print('=== TEST COMPLETE! ===');
  
  // Show result using a simple Container instead of Dialog
  if (context.mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  }
}
