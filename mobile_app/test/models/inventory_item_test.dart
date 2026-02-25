import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/inventory_item.dart';

void main() {
  group('Inventory Models and States Tests', () {
    test('InventoryItem creates correctly from JSON', () {
      final json = {
        'id': 1,
        'barcode': '123456',
        'name': 'Test Item',
        'quantity': 10,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final item = InventoryItem.fromJson(json);
      
      expect(item.id, 1);
      expect(item.barcode, '123456');
      expect(item.name, 'Test Item');
      expect(item.quantity, 10);
    });

    test('InventoryItem creates correctly from nested product JSON', () {
      final json = {
        'id': 2,
        'product': {
          'barcode': '789012',
          'name': 'Nested Product',
        },
        'quantity': 5,
        'created_at': DateTime.now().toIso8601String(),
      };

      final item = InventoryItem.fromJson(json);

      expect(item.id, 2);
      expect(item.barcode, '789012');
      expect(item.name, 'Nested Product');
      expect(item.quantity, 5);
    });
  });
}
