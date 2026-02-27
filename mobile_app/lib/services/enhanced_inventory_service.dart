import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_inventory_item.dart';
import '../config/api_config.dart';

final enhancedInventoryServiceProvider = Provider((ref) => EnhancedInventoryService());

class EnhancedInventoryService {
  late final Box<EnhancedInventoryItem> _itemBox;
  late final Box<InventoryCategory> _categoryBox;
  final Dio _dio = Dio();
  
  EnhancedInventoryService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<void> initialize() async {
    _itemBox = await Hive.openBox<EnhancedInventoryItem>('enhanced_inventory_items');
    _categoryBox = await Hive.openBox<InventoryCategory>('inventory_categories');
  }

  // Item Management
  Future<List<EnhancedInventoryItem>> getAllItems() async {
    try {
      // Try to get from backend first
      final response = await _dio.get('/api/inventory/items/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final items = data.map((json) => EnhancedInventoryItem.fromJson(json)).toList();
        
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

  Future<EnhancedInventoryItem?> getItemById(String id) async {
    try {
      final response = await _dio.get('/api/inventory/items/$id/');
      if (response.statusCode == 200) {
        final item = EnhancedInventoryItem.fromJson(response.data);
        await _itemBox.put(id, item);
        return item;
      }
    } catch (e) {
      print('Error fetching item from backend: $e');
    }
    
    return _itemBox.get(id);
  }

  Future<EnhancedInventoryItem?> getItemByBarcode(String barcode) async {
    try {
      final response = await _dio.get('/api/inventory/items/by-barcode/', queryParameters: {'barcode': barcode});
      if (response.statusCode == 200) {
        final item = EnhancedInventoryItem.fromJson(response.data);
        await _itemBox.put(item.id, item);
        return item;
      }
    } catch (e) {
      print('Error fetching item by barcode from backend: $e');
    }
    
    // Search local storage
    return _itemBox.values.firstWhere(
      (item) => item.barcode == barcode || item.qrCode == barcode,
      orElse: () => throw Exception('Item not found'),
    );
  }

  Future<EnhancedInventoryItem> createItem(EnhancedInventoryItem item) async {
    try {
      final response = await _dio.post('/api/inventory/items/', data: item.toJson());
      if (response.statusCode == 201) {
        final createdItem = EnhancedInventoryItem.fromJson(response.data);
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

  Future<EnhancedInventoryItem> updateItem(EnhancedInventoryItem item) async {
    try {
      final response = await _dio.put('/api/inventory/items/${item.id}/', data: item.toJson());
      if (response.statusCode == 200) {
        final updatedItem = EnhancedInventoryItem.fromJson(response.data);
        await _itemBox.put(updatedItem.id, updatedItem);
        return updatedItem;
      }
    } catch (e) {
      print('Error updating item on backend: $e');
    }
    
    // Fallback to local storage
    await _itemBox.put(item.id, item);
    return item;
  }

  Future<void> deleteItem(String id) async {
    try {
      await _dio.delete('/api/inventory/items/$id/');
    } catch (e) {
      print('Error deleting item from backend: $e');
    }
    
    // Remove from local storage
    await _itemBox.delete(id);
  }

  // Category Management
  Future<List<InventoryCategory>> getAllCategories() async {
    try {
      final response = await _dio.get('/api/inventory/categories/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final categories = data.map((json) => InventoryCategory.fromJson(json)).toList();
        
        // Update local cache
        await _syncLocalCategories(categories);
        return categories;
      }
    } catch (e) {
      print('Error fetching categories from backend: $e');
    }
    
    return _categoryBox.values.toList();
  }

  Future<InventoryCategory> createCategory(InventoryCategory category) async {
    try {
      final response = await _dio.post('/api/inventory/categories/', data: category.toJson());
      if (response.statusCode == 201) {
        final createdCategory = InventoryCategory.fromJson(response.data);
        await _categoryBox.put(createdCategory.id, createdCategory);
        return createdCategory;
      }
    } catch (e) {
      print('Error creating category on backend: $e');
    }
    
    await _categoryBox.put(category.id, category);
    return category;
  }

  Future<InventoryCategory> updateCategory(InventoryCategory category) async {
    try {
      final response = await _dio.put('/api/inventory/categories/${category.id}/', data: category.toJson());
      if (response.statusCode == 200) {
        final updatedCategory = InventoryCategory.fromJson(response.data);
        await _categoryBox.put(updatedCategory.id, updatedCategory);
        return updatedCategory;
      }
    } catch (e) {
      print('Error updating category on backend: $e');
    }
    
    await _categoryBox.put(category.id, category);
    return category;
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('/api/inventory/categories/$id/');
    } catch (e) {
      print('Error deleting category from backend: $e');
    }
    
    await _categoryBox.delete(id);
  }

  // Search and Filter
  Future<List<EnhancedInventoryItem>> searchItems(String query) async {
    try {
      final response = await _dio.get('/api/inventory/items/search/', queryParameters: {'q': query});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => EnhancedInventoryItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error searching items on backend: $e');
    }
    
    // Local search fallback
    return _itemBox.values.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase()) ||
          (item.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (item.barcode?.contains(query) ?? false) ||
          (item.supplier?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  Future<List<EnhancedInventoryItem>> getItemsByCategory(String categoryId) async {
    try {
      final response = await _dio.get('/api/inventory/items/by-category/', queryParameters: {'category_id': categoryId});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => EnhancedInventoryItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching items by category from backend: $e');
    }
    
    return _itemBox.values.where((item) => item.categoryId == categoryId).toList();
  }

  // Analytics and Reports
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final response = await _dio.get('/api/inventory/stats/');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error fetching stats from backend: $e');
    }
    
    // Calculate local stats
    final items = _itemBox.values.toList();
    final totalItems = items.length;
    final totalValue = items.fold<double>(0, (sum, item) => sum + item.totalValue);
    final lowStockItems = items.where((item) => item.isLowStock).length;
    final expiredItems = items.where((item) => item.isExpired).length;
    final expiringItems = items.where((item) => item.isExpiringSoon).length;
    
    return {
      'total_items': totalItems,
      'total_value': totalValue,
      'low_stock_items': lowStockItems,
      'expired_items': expiredItems,
      'expiring_items': expiringItems,
    };
  }

  // Bulk Operations
  Future<void> bulkImport(List<EnhancedInventoryItem> items) async {
    try {
      final response = await _dio.post('/api/inventory/bulk-import/', data: {
        'items': items.map((item) => item.toJson()).toList(),
      });
      if (response.statusCode == 200) {
        // Sync imported items
        await _syncLocalItems(response.data['items'].map((json) => EnhancedInventoryItem.fromJson(json)).toList());
        return;
      }
    } catch (e) {
      print('Error bulk importing items: $e');
    }
    
    // Fallback to local storage
    for (final item in items) {
      await _itemBox.put(item.id, item);
    }
  }

  Future<void> bulkExport() async {
    try {
      final response = await _dio.get('/api/inventory/bulk-export/');
      if (response.statusCode == 200) {
        // Handle file download
        return;
      }
    } catch (e) {
      print('Error bulk exporting items: $e');
    }
  }

  // Sync methods
  Future<void> syncWithBackend() async {
    try {
      // Sync items
      await getAllItems();
      
      // Sync categories
      await getAllCategories();
    } catch (e) {
      print('Error syncing with backend: $e');
    }
  }

  Future<void> _syncLocalItems(List<EnhancedInventoryItem> items) async {
    for (final item in items) {
      await _itemBox.put(item.id, item);
    }
  }

  Future<void> _syncLocalCategories(List<InventoryCategory> categories) async {
    for (final category in categories) {
      await _categoryBox.put(category.id, category);
    }
  }

  // Local storage methods
  Future<void> clearLocalData() async {
    await _itemBox.clear();
    await _categoryBox.clear();
  }

  Future<void> backupLocalData() async {
    final items = _itemBox.values.map((item) => item.toJson()).toList();
    final categories = _categoryBox.values.map((category) => category.toJson()).toList();
    
    // Save to file or send to backend
    try {
      await _dio.post('/api/inventory/backup/', data: {
        'items': items,
        'categories': categories,
      });
    } catch (e) {
      print('Error backing up data: $e');
    }
  }
}
