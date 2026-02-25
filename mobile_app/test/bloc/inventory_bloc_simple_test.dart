import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import '../../lib/bloc/inventory_bloc.dart';
import '../../lib/bloc/inventory_event.dart';
import '../../lib/bloc/inventory_state.dart';
import '../../lib/models/inventory_item.dart';

void main() {
  group('InventoryBloc Tests', () {
    late InventoryBloc inventoryBloc;

    setUp(() {
      inventoryBloc = InventoryBloc();
    });

    tearDown(() {
      inventoryBloc.close();
    });

    test('initial state is InventoryInitial', () {
      expect(inventoryBloc.state, equals(InventoryInitial()));
    });

    blocTest<InventoryBloc, InventoryState>(
      'emits InventoryLoading when LoadInventoryEvent is added',
      build: () => inventoryBloc,
      act: (bloc) => bloc.add(LoadInventoryEvent()),
      expect: () => [
        InventoryLoading(),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits BarcodeScanSuccess when ScanBarcodeEvent is added',
      build: () => inventoryBloc,
      act: (bloc) => bloc.add(ScanBarcodeEvent('123456')),
      expect: () => [
        BarcodeScanSuccess('123456'),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits states when AddInventoryItemEvent is added',
      build: () => inventoryBloc,
      act: (bloc) => bloc.add(AddInventoryItemEvent(
        barcode: '123456',
        name: 'Test Item',
        quantity: 5,
      )),
      expect: () => [
        isA<InventoryLoaded>(),
      ],
    );

    test('InventoryLoaded holds correct values', () {
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

    test('InventoryError holds correct message', () {
      const errorMessage = 'Test error message';
      final state = InventoryError(errorMessage);

      expect(state.message, equals(errorMessage));
    });

    test('BarcodeScanSuccess holds correct barcode', () {
      const barcode = '123456789';
      final state = BarcodeScanSuccess(barcode);

      expect(state.barcode, equals(barcode));
    });
  });
}
