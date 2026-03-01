import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/inventory_item.dart';
import 'auth_service.dart';

class ApiService {
  late final Dio _dio;
  bool _initialized = false;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: Map<String, String>.from(ApiConfig.defaultHeaders),
    ));

    // Add auth interceptor — injects token on every request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
          print('API → ${options.method} ${options.uri}');
          handler.next(options);
        },
        onError: (error, handler) {
          print('API Error: ${error.response?.statusCode} '
              '${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  // ─── Inventory Items ───

  /// Fetch all stock items for the current merchant
  Future<List<InventoryItem>> fetchInventory({
    int page = 1,
    int pageSize = 50,
    String search = '',
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.items,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search.isNotEmpty) 'search': search,
        },
      );
      // Django returns { items: [...], page, total }
      final List<dynamic> data = response.data['items'] ?? [];
      return data
          .map((json) => InventoryItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch inventory: $e');
    }
  }

  /// Add a new stock item
  Future<InventoryItem> addItem({
    required String barcode,
    required String name,
    required int quantity,
    double price = 0,
    double costPrice = 0,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.addItem,
        data: {
          'barcode': barcode,
          'name': name,
          'quantity': quantity,
          'price': price,
          'cost_price': costPrice,
        },
      );
      return InventoryItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  /// Update an existing stock item
  Future<Map<String, dynamic>> updateItem({
    required int id,
    int? quantity,
    double? price,
  }) async {
    try {
      final response = await _dio.put(
        ApiConfig.updateItem(id),
        data: {
          if (quantity != null) 'quantity': quantity,
          if (price != null) 'price': price,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  /// Remove quantity from a stock item
  Future<Map<String, dynamic>> removeStock({
    required int id,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.removeItem(id),
        data: {'quantity': quantity},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to remove stock: $e');
    }
  }

  /// Get single item details
  Future<Map<String, dynamic>> getItemDetails(int id) async {
    try {
      final response = await _dio.get(ApiConfig.itemDetails(id));
      return response.data;
    } catch (e) {
      throw Exception('Failed to get item details: $e');
    }
  }

  /// Search inventory items
  Future<List<InventoryItem>> searchItems(String query) async {
    try {
      final response = await _dio.get(
        ApiConfig.searchItems,
        queryParameters: {'q': query},
      );
      final List<dynamic> results = response.data['results'] ?? [];
      return results
          .map((json) => InventoryItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search items: $e');
    }
  }

  // ─── Barcode Scanning ───

  /// Process a barcode scan (IN or OUT)
  Future<Map<String, dynamic>> processScan({
    required String barcode,
    required String action,
    String source = 'PHONE',
    String deviceId = 'mobile_app',
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.scanProcess,
        data: {
          'barcode': barcode,
          'action': action,
          'source': source,
          'device_id': deviceId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to process scan: $e');
    }
  }

  // ─── Reports ───

  Future<Map<String, dynamic>> getSalesReport({int days = 7}) async {
    try {
      final response = await _dio.get(
        ApiConfig.salesReport,
        queryParameters: {'days': days},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to get sales report: $e');
    }
  }

  Future<Map<String, dynamic>> getPerformance() async {
    try {
      final response = await _dio.get(ApiConfig.merchantPerformance);
      return response.data;
    } catch (e) {
      throw Exception('Failed to get performance: $e');
    }
  }

  // ─── Alerts ───

  Future<Map<String, dynamic>> getLowStockAlerts({
    int? threshold,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.lowStockAlerts,
        queryParameters: {
          if (threshold != null) 'threshold': threshold,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to get alerts: $e');
    }
  }

  // ─── Inventory History ───

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await _dio.get(ApiConfig.inventoryHistory);
      final List<dynamic> data = response.data['history'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get history: $e');
    }
  }
}
