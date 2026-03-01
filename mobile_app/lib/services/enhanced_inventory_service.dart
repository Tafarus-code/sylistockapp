import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_inventory_item.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

final enhancedInventoryServiceProvider =
    Provider((ref) => EnhancedInventoryService.instance);

class EnhancedInventoryService {
  // Singleton so main.dart init and provider share the same instance
  static final EnhancedInventoryService instance =
      EnhancedInventoryService._();
  factory EnhancedInventoryService() => instance;

  Box<EnhancedInventoryItem>? _itemBox;
  Box<InventoryCategory>? _categoryBox;
  bool _initialized = false;
  final Dio _dio = Dio();

  EnhancedInventoryService._() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          print('EnhancedInventory API Error: '
              '${error.response?.statusCode} ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Force-clear all caches — format changed (removed HiveObject),
    // old data on disk causes "Cannot write" / adapter errors.
    // Items and categories reload from Django backend.
    for (final name in [
      'enhanced_inventory_items',
      'inventory_categories',
    ]) {
      try { await Hive.deleteBoxFromDisk(name); } catch (_) {}
    }

    _itemBox = await _openBoxSafe<EnhancedInventoryItem>(
        'enhanced_inventory_items');
    _categoryBox =
        await _openBoxSafe<InventoryCategory>('inventory_categories');
    _initialized = true;
  }

  /// Open a Hive box safely — if corrupted, delete and recreate it
  Future<Box<T>> _openBoxSafe<T>(String name) async {
    try {
      final box = await Hive.openBox<T>(name);
      // Test read to catch deserialization errors early
      box.values.length;
      return box;
    } catch (e) {
      print('Hive box "$name" corrupted, resetting: $e');
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      return await Hive.openBox<T>(name);
    }
  }

  /// Ensure Hive boxes are open before every operation
  Future<void> _ensureInit() async {
    if (!_initialized) await initialize();
  }

  // ─── Item Management ───

  Future<List<EnhancedInventoryItem>> getAllItems() async {
    await _ensureInit();
    try {
      final response = await _dio.get(ApiConfig.items);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['items'] ?? [];
        final items = data
            .map((json) =>
                _mapDjangoItemToEnhanced(json as Map<String, dynamic>))
            .toList();
        try { await _syncLocalItems(items); } catch (_) {}
        return items;
      }
    } catch (e) {
      print('Error fetching items from backend: $e');
    }
    try { return _itemBox!.values.toList(); } catch (_) { return []; }
  }

  Future<EnhancedInventoryItem?> getItemById(String id) async {
    await _ensureInit();
    final intId = int.tryParse(id);
    if (intId != null) {
      try {
        final response =
            await _dio.get(ApiConfig.itemDetails(intId));
        if (response.statusCode == 200) {
          final item = _mapDjangoItemToEnhanced(response.data);
          try { await _itemBox!.put(id, item); } catch (_) {}
          return item;
        }
      } catch (e) {
        print('Error fetching item from backend: $e');
      }
    }
    try { return _itemBox!.get(id); } catch (_) { return null; }
  }

  Future<EnhancedInventoryItem?> getItemByBarcode(
      String barcode) async {
    await _ensureInit();
    try {
      final response = await _dio.get(
        ApiConfig.searchItems,
        queryParameters: {'q': barcode},
      );
      if (response.statusCode == 200) {
        final results = response.data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final item = _mapDjangoItemToEnhanced(
              results.first as Map<String, dynamic>);
          try { await _itemBox!.put(item.id, item); } catch (_) {}
          return item;
        }
      }
    } catch (e) {
      print('Error searching item by barcode: $e');
    }
    try {
      return _itemBox!.values.firstWhere(
        (item) =>
            item.barcode == barcode || item.qrCode == barcode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<EnhancedInventoryItem> createItem(
      EnhancedInventoryItem item) async {
    await _ensureInit();
    try {
      final response = await _dio.post(
        ApiConfig.addItem,
        data: {
          'barcode': item.barcode ?? '',
          'name': item.name,
          'quantity': item.quantity,
          'price': item.sellingPrice ?? item.unitPrice,
          'cost_price': item.unitPrice,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final createdItem =
            _mapDjangoItemToEnhanced(response.data);
        try { await _itemBox!.put(createdItem.id, createdItem); } catch (_) {}
        return createdItem;
      }
    } catch (e) {
      print('Error creating item on backend: $e');
    }
    try { await _itemBox!.put(item.id, item); } catch (_) {}
    return item;
  }

  Future<EnhancedInventoryItem> updateItem(
      EnhancedInventoryItem item) async {
    await _ensureInit();
    final intId = int.tryParse(item.id);
    if (intId != null) {
      try {
        final response = await _dio.put(
          ApiConfig.updateItem(intId),
          data: {
            'quantity': item.quantity,
            'price': item.sellingPrice ?? item.unitPrice,
          },
        );
        if (response.statusCode == 200) {
          try { await _itemBox!.put(item.id, item); } catch (_) {}
          return item;
        }
      } catch (e) {
        print('Error updating item on backend: $e');
      }
    }
    try { await _itemBox!.put(item.id, item); } catch (_) {}
    return item;
  }

  Future<void> deleteItem(String id) async {
    await _ensureInit();
    try { await _itemBox!.delete(id); } catch (_) {}
  }

  // ─── Category Management (synced with Django backend) ───

  Future<List<InventoryCategory>> getAllCategories() async {
    await _ensureInit();
    try {
      final response = await _dio.get(ApiConfig.categories);
      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['categories'] ?? [];
        final categories = data
            .map((json) => InventoryCategory.fromJson(
                json as Map<String, dynamic>))
            .toList();
        // Cache locally (best effort)
        try {
          await _categoryBox!.clear();
          for (final cat in categories) {
            await _categoryBox!.put(cat.id, cat);
          }
        } catch (_) {}
        return categories;
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    try {
      return _categoryBox!.values.toList();
    } catch (_) {
      return [];
    }
  }

  Future<InventoryCategory> createCategory(
      InventoryCategory category) async {
    await _ensureInit();
    final response = await _dio.post(
      ApiConfig.createCategory,
      data: category.toJson(),
    );
    if (response.statusCode == 201) {
      final saved = InventoryCategory.fromJson(
          response.data as Map<String, dynamic>);
      try {
        await _categoryBox!.put(saved.id, saved);
      } catch (_) {}
      return saved;
    }
    throw Exception(response.data?['error'] ?? 'Failed to create category');
  }

  Future<InventoryCategory> updateCategory(
      InventoryCategory category) async {
    await _ensureInit();
    final catId = int.tryParse(category.id);
    if (catId != null) {
      final response = await _dio.put(
        ApiConfig.updateCategory(catId),
        data: category.toJson(),
      );
      if (response.statusCode == 200) {
        final saved = InventoryCategory.fromJson(
            response.data as Map<String, dynamic>);
        try {
          await _categoryBox!.put(saved.id, saved);
        } catch (_) {}
        return saved;
      }
    }
    throw Exception('Failed to update category');
  }

  Future<void> deleteCategory(String id) async {
    await _ensureInit();
    final catId = int.tryParse(id);
    if (catId != null) {
      await _dio.delete(ApiConfig.deleteCategory(catId));
    }
    try {
      await _categoryBox!.delete(id);
    } catch (_) {}
  }

  // ─── Search ───

  Future<List<EnhancedInventoryItem>> searchItems(
      String query) async {
    await _ensureInit();
    try {
      final response = await _dio.get(
        ApiConfig.searchItems,
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['results'] ?? [];
        return data
            .map((json) => _mapDjangoItemToEnhanced(
                json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error searching items on backend: $e');
    }
    try {
      return _itemBox!.values.where((item) {
        final q = query.toLowerCase();
        return item.name.toLowerCase().contains(q) ||
            (item.description?.toLowerCase().contains(q) ?? false) ||
            (item.barcode?.contains(query) ?? false) ||
            (item.supplier?.toLowerCase().contains(q) ?? false);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<EnhancedInventoryItem>> getItemsByCategory(
      String categoryId) async {
    await _ensureInit();
    try {
      return _itemBox!.values
          .where((item) => item.categoryId == categoryId)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Analytics ───

  Future<Map<String, dynamic>> getInventoryStats() async {
    await _ensureInit();
    try {
      final response =
          await _dio.get(ApiConfig.merchantPerformance);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error fetching stats from backend: $e');
    }
    try {
      final items = _itemBox!.values.toList();
      return {
        'total_items': items.length,
        'total_value': items.fold<double>(
            0, (sum, item) => sum + item.totalValue),
        'low_stock_items':
            items.where((item) => item.isLowStock).length,
        'expired_items':
            items.where((item) => item.isExpired).length,
        'expiring_items':
            items.where((item) => item.isExpiringSoon).length,
      };
    } catch (_) {
      return {
        'total_items': 0,
        'total_value': 0.0,
        'low_stock_items': 0,
        'expired_items': 0,
        'expiring_items': 0,
      };
    }
  }

  // ─── Bulk Operations ───

  Future<void> bulkImport(
      List<EnhancedInventoryItem> items) async {
    for (final item in items) {
      await createItem(item);
    }
  }

  Future<void> bulkExport() async {
    try {
      await _dio.get(ApiConfig.bulkExport);
    } catch (e) {
      print('Error bulk exporting items: $e');
    }
  }

  // ─── Sync ───

  Future<void> syncWithBackend() async {
    try {
      await getAllItems();
    } catch (e) {
      print('Error syncing with backend: $e');
    }
  }

  Future<void> _syncLocalItems(
      List<EnhancedInventoryItem> items) async {
    try {
      for (final item in items) {
        await _itemBox!.put(item.id, item);
      }
    } catch (_) {}
  }

  Future<void> clearLocalData() async {
    await _ensureInit();
    try { await _itemBox!.clear(); } catch (_) {}
    try { await _categoryBox!.clear(); } catch (_) {}
  }

  // ─── Django JSON → EnhancedInventoryItem mapper ───

  EnhancedInventoryItem _mapDjangoItemToEnhanced(
      Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final price = _toDouble(json['price'] ?? json['sale_price']);
    final costPrice = _toDouble(json['cost_price']);

    return EnhancedInventoryItem(
      id: id,
      name: json['name'] as String? ?? '',
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String? ?? 'uncategorized',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: costPrice ?? price ?? 0.0,
      sellingPrice: price,
      location: json['location'] as String?,
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['last_updated'] ?? json['updated_at']),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
