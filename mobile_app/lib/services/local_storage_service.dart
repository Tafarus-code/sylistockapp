import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_item.dart';

class LocalStorageService {
  static const String _inventoryBoxName = 'inventory_items';
  static const String _settingsBoxName = 'app_settings';
  
  late Box<InventoryItem> _inventoryBox;
  late Box _settingsBox;

  Future<void> init() async {
    try {
      _inventoryBox = await Hive.openBox<InventoryItem>(_inventoryBoxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_inventoryBoxName);
      _inventoryBox = await Hive.openBox<InventoryItem>(_inventoryBoxName);
    }
    try {
      _settingsBox = await Hive.openBox(_settingsBoxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_settingsBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
    }
  }

  // Inventory operations
  Future<void> saveInventoryItems(List<InventoryItem> items) async {
    await _inventoryBox.clear();
    for (final item in items) {
      await _inventoryBox.put(item.id, item);
    }
  }

  List<InventoryItem> getInventoryItems() {
    return _inventoryBox.values.toList();
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    await _inventoryBox.put(item.id, item);
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _inventoryBox.put(item.id, item);
  }

  Future<void> deleteInventoryItem(int id) async {
    await _inventoryBox.delete(id);
  }

  Future<void> clearInventory() async {
    await _inventoryBox.clear();
  }

  // Settings operations
  Future<void> saveApiBaseUrl(String url) async {
    await _settingsBox.put('api_base_url', url);
  }

  String getApiBaseUrl() {
    return _settingsBox.get('api_base_url', defaultValue: 'http://localhost:8000/api');
  }

  Future<void> saveLastSyncTime(DateTime time) async {
    await _settingsBox.put('last_sync_time', time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeString = _settingsBox.get('last_sync_time');
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  Future<void> saveOfflineMode(bool enabled) async {
    await _settingsBox.put('offline_mode', enabled);
  }

  bool getOfflineMode() {
    return _settingsBox.get('offline_mode', defaultValue: false);
  }

  // Cleanup
  Future<void> close() async {
    await _inventoryBox.close();
    await _settingsBox.close();
  }
}
