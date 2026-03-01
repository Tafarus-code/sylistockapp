import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

// Riverpod provider for inventory list
final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(
  InventoryNotifier.new,
);

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  final ApiService _api = ApiService();

  @override
  Future<List<InventoryItem>> build() async {
    return _loadItems();
  }

  /// Load items from backend, fallback to local
  Future<List<InventoryItem>> _loadItems() async {
    try {
      final items = await _api.fetchInventory();
      // Cache locally
      final localStorage = LocalStorageService();
      await localStorage.init();
      await localStorage.saveInventoryItems(items);
      return items;
    } catch (e) {
      // Fallback to local cache
      try {
        final localStorage = LocalStorageService();
        await localStorage.init();
        return localStorage.getInventoryItems();
      } catch (_) {
        return [];
      }
    }
  }

  /// Refresh items from server
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadItems());
  }

  /// Add item via backend
  Future<void> addItem({
    required String barcode,
    required String name,
    required int quantity,
    double price = 0,
    double costPrice = 0,
  }) async {
    await _api.addItem(
      barcode: barcode,
      name: name,
      quantity: quantity,
      price: price,
      costPrice: costPrice,
    );
    await refresh();
  }

  /// Process barcode scan
  Future<Map<String, dynamic>> processScan({
    required String barcode,
    String action = 'IN',
    String source = 'PHONE',
  }) async {
    final result = await _api.processScan(
      barcode: barcode,
      action: action,
      source: source,
    );
    await refresh();
    return result;
  }

  /// Search items
  Future<List<InventoryItem>> searchItems(String query) async {
    return _api.searchItems(query);
  }
}

// Provider for pending sync count
final pendingSyncCountProvider = Provider<int>((ref) {
  return 0;
});
