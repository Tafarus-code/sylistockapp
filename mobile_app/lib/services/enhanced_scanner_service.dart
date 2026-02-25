import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EnhancedScannerService {
  static const String _queueKey = 'scan_queue';
  static const String _backendUrlKey = 'backend_url';
  static const String _lastSyncKey = 'last_sync_time';

  /// Initialize scanner service
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Set default backend URL if not set
    if (!prefs.containsKey(_backendUrlKey)) {
      await prefs.setString(_backendUrlKey, 'https://your-railway-app.railway.app/api');
    }
  }

  /// Get current backend URL
  static Future<String> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendUrlKey) ?? 'http://localhost:8000/api';
  }

  /// Update backend URL
  static Future<void> updateBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, url);
  }

  /// Scan barcode and handle offline/online logic
  static Future<Map<String, dynamic>> scanBarcode(String barcode, {
    required String source,
    String action = 'IN',
    String deviceId = 'mobile_app',
  }) async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;
      
      if (isConnected) {
        // Online: Send directly to backend
        return await _sendScanToBackend(barcode, source, action, deviceId);
      } else {
        // Offline: Add to queue
        await _addToQueue({
          'barcode': barcode,
          'source': source,
          'action': action,
          'device_id': deviceId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return {
          'success': true,
          'message': 'Added to offline queue',
          'queued': true,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Scan failed',
      };
    }
  }

  /// Send scan to backend
  static Future<Map<String, dynamic>> _sendScanToBackend(
    String barcode,
    String source,
    String action,
    String deviceId,
  ) async {
    try {
      final backendUrl = await getBackendUrl();
      final response = await Dio().post(
        '$backendUrl/inventory/process-scan/',
        data: {
          'barcode': barcode,
          'action': action,
          'source': source,
          'device_id': deviceId,
        },
        options: Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        // Update last sync time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
        
        return {
          'success': true,
          'data': response.data,
          'message': 'Scan synced to backend',
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'message': 'Failed to sync scan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Network error',
      };
    }
  }

  /// Add scan to offline queue
  static Future<void> _addToQueue(Map<String, dynamic> scanData) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey) ?? '[]';
    final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
    
    queue.add(scanData);
    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Get offline queue
  static Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey) ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(queueJson));
  }

  /// Sync queued scans when back online
  static Future<Map<String, dynamic>> syncQueue() async {
    try {
      final queue = await getQueue();
      if (queue.isEmpty) {
        return {
          'success': true,
          'message': 'No items to sync',
          'synced_count': 0,
        };
      }

      final backendUrl = await getBackendUrl();
      int syncedCount = 0;
      List<Map<String, dynamic>> failedItems = [];

      for (final scanData in queue) {
        try {
          final response = await Dio().post(
            '$backendUrl/inventory/process-scan/',
            data: scanData,
            options: Options(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

          if (response.statusCode == 200) {
            syncedCount++;
          } else {
            failedItems.add(scanData);
          }
        } catch (e) {
          failedItems.add(scanData);
        }
      }

      // Clear synced items from queue
      final remainingQueue = queue.skip(syncedCount).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueKey, jsonEncode(remainingQueue));

      // Update last sync time
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return {
        'success': true,
        'message': 'Sync completed',
        'synced_count': syncedCount,
        'failed_count': failedItems.length,
        'remaining_count': remainingQueue.length,
        'failed_items': failedItems,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Sync failed',
      };
    }
  }

  /// Clear offline queue
  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, jsonEncode([]));
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final syncTimeStr = prefs.getString(_lastSyncKey);
    return syncTimeStr != null ? DateTime.parse(syncTimeStr) : null;
  }

  /// Get inventory from backend with enhanced error handling
  static Future<Map<String, dynamic>> getInventory() async {
    try {
      final backendUrl = await getBackendUrl();
      final response = await Dio().get(
        '$backendUrl/inventory/',
        options: Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Inventory loaded',
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'message': 'Failed to load inventory',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Network error',
      };
    }
  }

  /// Add inventory item with validation
  static Future<Map<String, dynamic>> addInventoryItem({
    required String barcode,
    required String name,
    required int quantity,
    double? price,
  }) async {
    try {
      final backendUrl = await getBackendUrl();
      final response = await Dio().post(
        '$backendUrl/inventory/',
        data: {
          'product': {
            'barcode': barcode,
            'name': name,
          },
          'quantity': quantity,
          'cost_price': price,
          'sale_price': price,
        },
        options: Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Item added successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'message': 'Failed to add item',
          'details': response.data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Network error',
      };
    }
  }
}
