import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sylistock Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualBarcodeController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String _lastScannedBarcode = '';

  @override
  void dispose() {
    _searchController.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  Future<void> _testApiConnection() async {
    setState(() => _isLoading = true);
    
    try {
      final dio = Dio();
      // Test connection to Django inventory endpoint
      final response = await dio.get('http://127.0.0.1:8000/inventory/');
      
      if (response.statusCode == 200) {
        // Load the sample data from Django
        final List<dynamic> djangoItems = response.data;
        setState(() {
          _items.clear();
          _items.addAll(djangoItems.map((item) => {
            'id': item['id'],
            'barcode': item['barcode'],
            'name': item['name'],
            'quantity': item['quantity'],
            'description': item['description'] ?? '',
            'createdAt': item['created_at'],
          }));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Connected to Django! Loaded ${djangoItems.length} items'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Django connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Barcode Entry'),
        content: TextField(
          controller: _manualBarcodeController,
          decoration: const InputDecoration(
            labelText: 'Enter Barcode',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_manualBarcodeController.text.isNotEmpty) {
                try {
                  // Send to Django
                  final dio = Dio();
                  final response = await dio.post(
                    'http://127.0.0.1:8000/inventory/',
                    data: {
                      'barcode': _manualBarcodeController.text,
                      'name': 'Test Item ${_items.length + 1}',
                      'quantity': 1,
                      'description': 'Added via Flutter app',
                    },
                  );
                  
                  if (response.statusCode == 201) {
                    setState(() {
                      _lastScannedBarcode = _manualBarcodeController.text;
                      _items.add(response.data);
                    });
                  }
                } catch (e) {
                  // Fallback to local item if Django fails
                  setState(() {
                    _lastScannedBarcode = _manualBarcodeController.text;
                    _items.add({
                      'id': _items.length + 1,
                      'barcode': _manualBarcodeController.text,
                      'name': 'Test Item ${_items.length + 1}',
                      'quantity': 1,
                      'createdAt': DateTime.now().toString(),
                    });
                  });
                }
                
                Navigator.pop(context);
                _manualBarcodeController.clear();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barcode scanned successfully!')),
                );
              }
            },
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _items;
    
    return _items.where((item) =>
      (item['name'] as String).toLowerCase().contains(query) ||
      (item['barcode'] as String).toLowerCase().contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Sylistock Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _testApiConnection,
            tooltip: 'Test Django Connection',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search items by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          
          // Manual Entry Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Manual Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Status Info
          if (_lastScannedBarcode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Last scanned: $_lastScannedBarcode'),
                  ],
                ),
              ),
            ),

          // Inventory List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No inventory items',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try manual entry or test Django connection',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              (item['quantity'] as int).toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          title: Text(
                            item['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Barcode: ${item['barcode']}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showManualEntryDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
