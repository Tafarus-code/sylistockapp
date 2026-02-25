import 'package:flutter_test/flutter_test.dart';
import '../../lib/bloc/inventory_event.dart';
import '../../lib/bloc/inventory_state.dart';
import '../../lib/models/inventory_item.dart';

void main() {
  group('Inventory Models and States Tests', () {
    test('InventoryItem creates correctly from JSON', () {
      final json = {
        'id': 1,
        'barcode': '123456',
        'name': 'Test Item',
        'quantity': 10,
        'description': 'Test Description',
        'price': 29.99,
        'created_at': '2023-01-01T00:00:00.000Z',
      };

      final item = InventoryItem.fromJson(json);

      expect(item.id, equals(1));
      expect(item.barcode, equals('123456'));
      expect(item.name, equals('Test Item'));
      expect(item.quantity, equals(10));
      expect(item.description, equals('Test Description'));
      expect(item.price, equals(29.99));
    });

    test('InventoryItem converts to JSON correctly', () {
      final item = InventoryItem(
        id: 1,
        barcode: '123456',
        name: 'Test Item',
        quantity: 10,
        description: 'Test Description',
        price: 29.99,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      final json = item.toJson();

      expect(json['id'], equals(1));
      expect(json['barcode'], equals('123456'));
      expect(json['name'], equals('Test Item'));
      expect(json['quantity'], equals(10));
      expect(json['description'], equals('Test Description'));
      expect(json['price'], equals(29.99));
    });

    test('InventoryLoaded state holds correct values', () {
      final items = [
        InventoryItem(
          id: 1,
          barcode: '123456',
          name: 'Test Item',
          quantity: 10,
          createdAt: DateTime.now(),
        ),
      ];

      final state = InventoryLoaded(
        items: items,
        lastScannedBarcode: '123456',
        isOffline: true,
      );

      expect(state.items, equals(items));
      expect(state.lastScannedBarcode, equals('123456'));
      expect(state.isOffline, isTrue);
    });

    test('InventoryError state holds correct message', () {
      const errorMessage = 'Test error message';
      final state = InventoryError(errorMessage);

      expect(state.message, equals(errorMessage));
    });

    test('BarcodeScanSuccess state holds correct barcode', () {
      const barcode = '123456789';
      final state = BarcodeScanSuccess(barcode);

      expect(state.barcode, equals(barcode));
    });

    test('ScanBarcodeEvent holds correct barcode', () {
      const barcode = '123456789';
      final event = ScanBarcodeEvent(barcode);

      expect(event.barcode, equals(barcode));
    });

    test('AddInventoryItemEvent holds correct values', () {
      final event = AddInventoryItemEvent(
        barcode: '123456',
        name: 'Test Item',
        quantity: 5,
      );

      expect(event.barcode, equals('123456'));
      expect(event.name, equals('Test Item'));
      expect(event.quantity, equals(5));
    });

    test('LoadInventoryEvent creates correctly', () {
      final event = LoadInventoryEvent();
      expect(event, isA<LoadInventoryEvent>());
    });
  });
}
