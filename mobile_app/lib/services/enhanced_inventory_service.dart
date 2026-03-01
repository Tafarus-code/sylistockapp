import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_inventory_item.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

final enhancedInventoryServiceProvider =
    Provider((ref) => EnhancedInventoryService());

class EnhancedInventoryService {
  late final Box<EnhancedInventoryItem> _itemBox;
  late final Box<InventoryCategory> _categoryBox;
  final Dio _dio = Dio();

  EnhancedInventoryService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth interceptor
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
    _itemBox = await Hive.openBox<EnhancedInventoryItem>(
        'enhanced_inventory_items');
    _categoryBox =
        await Hive.openBox<InventoryCategory>('inventory_categories');
  }

  // ─── Item Management ───

  /// Get all items — tries backend first, falls back to local Hive
  Future<List<EnhancedInventoryItem>> getAllItems() async {
    try {
      final response = await _dio.get(ApiConfig.items);
      if (response.statusCode == 200) {
        // Django returns { items: [...], page, total }
        final List<dynamic> data = response.data['items'] ?? [];
        final items = data
            .map((json) =>
                _mapDjangoItemToEnhanced(json as Map<String, dynamic>))
            .toList();

        // Update local cache
        await _syncLocalItems(items);
        return items;
      }
    } catch (e) {
      print('Error fetching items from backend: $e');
    }

    // Fallback to local storage
    return _itemBox.values.toList();
  }

  /// Get item by ID
  Future<EnhancedInventoryItem?> getItemById(String id) async {
    // Try parsing as int for Django's integer PKs
    final intId = int.tryParse(id);
    if (intId != null) {
      try {
        final response =
            await _dio.get(ApiConfig.itemDetails(intId));
        if (response.statusCode == 200) {
          final item = _mapDjangoItemToEnhanced(response.data);
          await _itemBox.put(id, item);
          return item;
        }
      } catch (e) {
        print('Error fetching item from backend: $e');
      }
    }

    return _itemBox.get(id);
  }

  /// Search items by barcode or name
  Future<EnhancedInventoryItem?> getItemByBarcode(
      String barcode) async {
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
          await _itemBox.put(item.id, item);
          return item;
        }
      }
    } catch (e) {
      print('Error searching item by barcode: $e');
    }

    // Search local storage
    try {
      return _itemBox.values.firstWhere(
        (item) =>
            item.barcode == barcode || item.qrCode == barcode,
      );
    } catch (_) {
      return null;
    }
  }

  /// Create item via Django backend
  Future<EnhancedInventoryItem> createItem(
      EnhancedInventoryItem item) async {
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
        await _itemBox.put(createdItem.id, createdItem);
        return createdItem;
      }
    } catch (e) {
      print('Error creating item on backend: $e');
    }

    // Fallback to local storage
    await _itemBox.put(item.id, item);
    return item;
  }

  /// Update item
  Future<EnhancedInventoryItem> updateItem(
      EnhancedInventoryItem item) async {
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
          await _itemBox.put(item.id, item);
          return item;
        }
      } catch (e) {
        print('Error updating item on backend: $e');
      }
    }

    // Fallback to local storage
    await _itemBox.put(item.id, item);
    return item;
  }

  /// Delete item
  Future<void> deleteItem(String id) async {
    // Django doesn't have a delete endpoint yet, just remove locally
    await _itemBox.delete(id);
  }

  // ─── Category Management (local only) ───
  // Categories are local-only since Django has no Category model

  Future<List<InventoryCategory>> getAllCategories() async {
    return _categoryBox.values.toList();
  }

  Future<InventoryCategory> createCategory(
      InventoryCategory category) async {
    await _categoryBox.put(category.id, category);
    return category;
  }

  Future<InventoryCategory> updateCategory(
      InventoryCategory category) async {
    await _categoryBox.put(category.id, category);
    return category;
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }

  // ─── Search ───

  Future<List<EnhancedInventoryItem>> searchItems(
      String query) async {
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

    // Local search fallback
    return _itemBox.values.where((item) {
      final q = query.toLowerCase();
      return item.name.toLowerCase().contains(q) ||
          (item.description?.toLowerCase().contains(q) ?? false) ||
          (item.barcode?.contains(query) ?? false) ||
          (item.supplier?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<List<EnhancedInventoryItem>> getItemsByCategory(
      String categoryId) async {
    return _itemBox.values
        .where((item) => item.categoryId == categoryId)
        .toList();
  }

  // ─── Analytics ───

  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final response =
          await _dio.get(ApiConfig.merchantPerformance);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error fetching stats from backend: $e');
    }

    // Calculate local stats
    final items = _itemBox.values.toList();
    final totalItems = items.length;
    final totalValue = items.fold<double>(
        0, (sum, item) => sum + item.totalValue);
    final lowStockItems =
        items.where((item) => item.isLowStock).length;
    final expiredItems =
        items.where((item) => item.isExpired).length;
    final expiringItems =
        items.where((item) => item.isExpiringSoon).length;

    return {
      'total_items': totalItems,
      'total_value': totalValue,
      'low_stock_items': lowStockItems,
      'expired_items': expiredItems,
      'expiring_items': expiringItems,
    };
  }

  // ─── Bulk Operations ───

  Future<void> bulkImport(
      List<EnhancedInventoryItem> items) async {
    // Add each item through the backend
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
    for (final item in items) {
      await _itemBox.put(item.id, item);
    }
  }

  Future<void> clearLocalData() async {
    await _itemBox.clear();
    await _categoryBox.clear();
  }

  // ─── Django JSON → EnhancedInventoryItem mapper ───

  /// Maps Django's flat stock item JSON to EnhancedInventoryItem.
  /// Django returns:
  ///   { id, barcode, name, quantity, price, last_updated }
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
