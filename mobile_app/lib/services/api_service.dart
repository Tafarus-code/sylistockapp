import 'package:dio/dio.dart';
import '../models/inventory_item.dart';
import 'local_storage_service.dart';

class ApiService {
  late final Dio _dio;
  late final LocalStorageService _localStorageService;
  String get baseUrl => _localStorageService.getApiBaseUrl();

  ApiService({
    LocalStorageService? localStorageService,
  }) : _localStorageService = localStorageService ?? LocalStorageService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptors for better error handling
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

  Future<void> updateBaseUrl() async {
    _dio.options.baseUrl = baseUrl;
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
      await _dio.post('/inventory/', data: {'barcode': barcode});
    } catch (e) {
      throw Exception('Failed to send barcode: $e');
    }
  }

  Future<InventoryItem> addInventoryItem({
    required String barcode,
    required String name,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post(
        '/inventory/',
        data: {
          'barcode': barcode,
          'name': name,
          'quantity': quantity,
        },
      );
      return InventoryItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add inventory item: $e');
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

