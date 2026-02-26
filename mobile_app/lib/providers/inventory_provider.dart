import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

// Simple Riverpod provider for inventory management
final inventoryProvider = Provider<List<InventoryItem>>((ref) => []);

// Service class to handle inventory operations
class InventoryService {
  static List<InventoryItem> _currentItems = [];
  
  static List<InventoryItem> get currentItems => _currentItems;
  
  static Future<void> addItem(WidgetRef ref, InventoryItem item) async {
    try {
      // Add to local storage immediately (offline-first)
      final localStorage = LocalStorageService();
      await localStorage.addInventoryItem(item);
      
      // Update UI with local data
      _currentItems = [..._currentItems, item];
      // Note: Provider doesn't support state updates, this is a limitation
      
      // Sync to backend when online (background)
      _syncToBackend();
    } catch (error) {
      print('Error adding item: $error');
    }
  }

  static Future<void> updateItem(WidgetRef ref, InventoryItem item) async {
    try {
      final localStorage = LocalStorageService();
      await localStorage.updateInventoryItem(item);
      
      _currentItems = _currentItems.map((i) => 
        i.id == item.id ? item : i
      ).toList();
      // Note: Provider doesn't support state updates
      
      await _syncToBackend();
    } catch (error) {
      print('Error updating item: $error');
    }
  }

  static Future<void> deleteItem(WidgetRef ref, int itemId) async {
    try {
      final localStorage = LocalStorageService();
      await localStorage.deleteInventoryItem(itemId);
      
      _currentItems = _currentItems.where((i) => i.id != itemId).toList();
      // Note: Provider doesn't support state updates
      
      await _syncToBackend();
    } catch (error) {
      print('Error deleting item: $error');
    }
  }

  static Future<void> processBarcode(WidgetRef ref, String barcode) async {
    try {
      final localStorage = LocalStorageService();
      
      // Create scan record immediately (offline-first)
      final scanItem = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch,
        barcode: barcode,
        name: 'Scanned Item',
        quantity: 1,
        createdAt: DateTime.now(),
      );
      
      await localStorage.addInventoryItem(scanItem);
      _currentItems = [..._currentItems, scanItem];
      // Note: Provider doesn't support state updates
      
      // Background sync
      _syncToBackend();
    } catch (error) {
      print('Error processing barcode: $error');
    }
  }

  // "Stale-While-Revalidate" pattern for 4G optimization
  static Future<void> _syncToBackend() async {
    try {
      final localStorage = LocalStorageService();
      final allItems = localStorage.getInventoryItems();
      
      if (allItems.isEmpty) return;
      
      final apiService = ApiService();
      
      // Sync all items for now (simplified)
      for (final item in allItems) {
        try {
          await apiService.addInventoryItem(
            barcode: item.barcode,
            name: item.name,
            quantity: item.quantity,
          );
          print('Synced item ${item.id}');
        } catch (e) {
          // Continue with other items if one fails
          print('Sync failed for item ${item.id}: $e');
        }
      }
    } catch (error) {
      print('Background sync failed: $error');
      // Don't update state - keep local data
    }
  }

  static Future<void> refreshFromServer(WidgetRef ref) async {
    try {
      final apiService = ApiService();
      final serverItems = await apiService.fetchInventory();
      
      // Update local storage with server data
      final localStorage = LocalStorageService();
      await localStorage.saveInventoryItems(serverItems);
      
      _currentItems = serverItems;
      // Note: Provider doesn't support state updates
    } catch (error) {
      // Fallback to local data if server fails
      print('Error refreshing from server: $error');
      // Keep current state (local data)
    }
  }

  static Future<void> initializeWithLocalData(WidgetRef ref) async {
    try {
      // Initialize with local data for offline-first experience
      final localStorage = LocalStorageService();
      final localItems = localStorage.getInventoryItems();
      _currentItems = localItems;
      // Note: Provider doesn't support state updates
    } catch (e) {
      print('Error initializing local data: $e');
    }
  }
}

// Provider for pending sync count
final pendingSyncCountProvider = Provider<int>((ref) {
  // This would watch the inventory provider and count unsynced items
  // For now, return 0 as placeholder
  return 0;
});
