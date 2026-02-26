import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_item.dart';

class ApiService {
  late final Dio _dio;
  static const String _baseUrlKey = 'api_base_url';

  ApiService() {
    _initializeDio();
  }

  Future<void> _initializeDio() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Auto-detect Railway deployment URL
    String defaultUrl = 'http://localhost:8000';
    try {
      // Check if we're running on Railway (web deployment)
      final currentUrl = Uri.base.toString();
      if (currentUrl.contains('railway.app')) {
        // Extract the Railway URL and use it for API calls
        final uri = Uri.parse(currentUrl);
        defaultUrl = '${uri.scheme}://${uri.host}';
      }
    } catch (e) {
      print('Could not detect deployment URL: $e');
    }
    
    final baseUrl = prefs.getString(_baseUrlKey) ?? '$defaultUrl/inventory';

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('API Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onError: (error, handler) {
          print('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<void> updateBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
    await _initializeDio();
  }

  Future<List<InventoryItem>> fetchInventory() async {
    try {
      final response = await _dio.get('/inventory/');
      final List<dynamic> data = response.data as List;
      return data.map((json) => InventoryItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch inventory: $e');
    }
  }

  Future<void> sendBarcode(String barcode) async {
    try {
      await _dio.post('/inventory/process-scan/', data: {
        'barcode': barcode,
        'action': 'IN',
        'source': 'mobile_app',
        'device_id': 'mobile_device',
      });
    } catch (e) {
      throw Exception('Failed to send barcode: $e');
    }
  }

  Future<InventoryItem> addInventoryItem({
    required String barcode,
    required String name,
    required int quantity,
    double? price,
  }) async {
    try {
      final response = await _dio.post('/inventory/', data: {
        'product': {
          'barcode': barcode,
          'name': name,
        },
        'quantity': quantity,
        'cost_price': price,
        'sale_price': price,
      });
      return InventoryItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  Future<InventoryItem> updateInventoryItem({
    required int id,
    String? barcode,
    String? name,
    int? quantity,
  }) async {
    try {
      final response = await _dio.patch(
        '/inventory/$id/',
        data: {
          if (barcode != null) 'barcode': barcode,
          if (name != null) 'name': name,
          if (quantity != null) 'quantity': quantity,
        },
      );
      return InventoryItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    try {
      await _dio.delete('/inventory/$id/');
    } catch (e) {
      throw Exception('Failed to delete inventory item: $e');
    }
  }
}
